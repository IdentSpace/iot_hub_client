import 'dart:async';

import 'package:flutter/material.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

// TODO: Implement fast login with QR Code
class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  final _serverController = TextEditingController();
  final _serverFocus = FocusNode();
  Timer? _serverDebounce;
  int _serverCheckId = 0;
  bool _checkingServer = false;
  String? _verifiedServer;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _serverFocus.addListener(_onServerFocusChanged);
  }

  @override
  void dispose() {
    _serverDebounce?.cancel();
    _serverFocus.dispose();
    _serverController.dispose();
    super.dispose();
  }

  void _onServerFocusChanged() {
    if (!_serverFocus.hasFocus && _serverController.text.trim().isNotEmpty) {
      _checkServer();
    }
  }

  String? _validateServer(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Server is required';
    try {
      final uri = Uri.tryParse(text);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          RegExp(r'\s').hasMatch(text) ||
          uri.port < 1 ||
          uri.port > 65535) {
        return 'Enter a valid HTTP or HTTPS server URL';
      }
    } on FormatException {
      return 'Enter a valid HTTP or HTTPS server URL';
    }
    return null;
  }

  String _normalizedServer() =>
      _serverController.text.trim().replaceFirst(RegExp(r'/+$'), '');

  void _onServerChanged(String value) {
    _serverDebounce?.cancel();
    _serverCheckId++;
    setState(() {
      _verifiedServer = null;
      _serverError = null;
      _checkingServer = false;
      _errorText = '';
    });
    if (value.trim().isNotEmpty) {
      _serverDebounce = Timer(const Duration(milliseconds: 700), _checkServer);
    }
  }

  Future<void> _checkServer() async {
    _serverDebounce?.cancel();
    final formatError = _validateServer(_serverController.text);
    final server = _normalizedServer();
    if (_checkingServer || (_verifiedServer == server && formatError == null)) {
      return;
    }
    final checkId = ++_serverCheckId;
    setState(() {
      _serverError = formatError;
      _verifiedServer = null;
      _checkingServer = formatError == null;
    });
    if (formatError != null) return;

    try {
      final state = await IOHubClient(
        server,
        '',
      ).state().timeout(const Duration(seconds: 8));
      if (!mounted || checkId != _serverCheckId) return;
      setState(() {
        _checkingServer = false;
        _verifiedServer = state != null ? server : null;
        _serverError = state == null
            ? 'No valid IOHub state received. Check the server URL.'
            : null;
      });
    } catch (_) {
      if (!mounted || checkId != _serverCheckId) return;
      setState(() {
        _checkingServer = false;
        _serverError = 'Server could not be reached. Please try again.';
      });
    }
  }

  bool isLoading = false;
  String _errorText = '';

  String _serverHost = '';
  String _username = '';
  String _password = '';

  Future<void> _login() async {
    if (isLoading ||
        _checkingServer ||
        _verifiedServer != _normalizedServer()) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      _errorText = '';
    });

    _formKey.currentState!.save();

    final token = await IHC.auth(
      server: _serverHost,
      username: _username,
      password: _password,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (token == null) {
      setState(() {
        _errorText = "Login failure, wrong data";
      });
      return;
    }

    TokenStore.setToken(token);

    final AppDatabase db = AppDatabase.instance;
    await db.insertToken(token);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => DeviceList()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 480 ? 16.0 : 32.0;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(padding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - padding * 2).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Welcome to IOHub Dash',
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to connect to your hub.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  TextFormField(
                                    controller: _serverController,
                                    focusNode: _serverFocus,
                                    readOnly: isLoading,
                                    onChanged: _onServerChanged,
                                    decoration: InputDecoration(
                                      errorText: _serverError,
                                      helperText: _checkingServer
                                          ? 'Checking server?'
                                          : _verifiedServer != null
                                          ? 'IOHub server is reachable'
                                          : 'Include http:// or https://',
                                      helperMaxLines: 2,
                                      errorMaxLines: 3,
                                      suffixIcon: _checkingServer
                                          ? const Padding(
                                              padding: EdgeInsets.all(14),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : IconButton(
                                              tooltip: 'Check server',
                                              onPressed: isLoading
                                                  ? null
                                                  : _checkServer,
                                              icon: Icon(
                                                _verifiedServer != null
                                                    ? Icons.check_circle_outline
                                                    : Icons.refresh,
                                              ),
                                            ),
                                      labelText: 'Server',
                                      hintText: 'https://hub.example.com',
                                      prefixIcon: const Icon(
                                        Icons.dns_outlined,
                                      ),
                                    ),
                                    keyboardType: TextInputType.url,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    onSaved: (_) =>
                                        _serverHost = _normalizedServer(),
                                    validator: _validateServer,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    onSaved: (value) =>
                                        _username = value?.trim() ?? '',
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Username is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!isLoading) _login();
                                    },
                                    onSaved: (value) => _password = value ?? '',
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Password is required'
                                        : null,
                                  ),
                                  if (_errorText.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorText,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 28),
                                  FilledButton(
                                    onPressed:
                                        isLoading ||
                                            _checkingServer ||
                                            _verifiedServer == null
                                        ? null
                                        : _login,
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Sign in'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'IdentSpace',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
