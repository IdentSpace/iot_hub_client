import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';
import 'package:iot_hub_client/views/login.dart';
import 'package:iot_hub_client/widgets/hub_card.dart';

class LoginSelectToken extends StatefulWidget {
  LoginSelectToken({super.key});

  final AppDatabase db = AppDatabase.instance;

  @override
  State<LoginSelectToken> createState() => _LoginSelectTokenState();
}

class _LoginSelectTokenState extends State<LoginSelectToken> {
  late Future<List<Widget>> _futureList;
  bool _navigated = false;

  Future<List<Widget>> _getTokens() async {
    final List<Widget> tmpList = [];

    final List<Token> tokens = await (widget.db.select(widget.db.tokens)).get();
    debugPrint(tokens.length.toString());

    for (var t in tokens) {
      tmpList.add(
        HubCard(
          token: t,
          onClick: () => {
            TokenStore.setToken(IHCToken(t.token ?? '', t.server)),
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => DeviceList()),
              (route) => false,
            ),
          },
          onLogout: () => {
            setState(() {
              _futureList = _getTokens();
            }),
          },
        ),
      );
    }

    return tmpList;
  }

  @override
  void initState() {
    super.initState();
    _futureList = _getTokens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        Text(
                          'Select Account',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Login(),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Account'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  FutureBuilder(
                    future: _futureList,
                    builder: (BuildContext context, AsyncSnapshot snap) {
                      if (snap.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Accounts could not be loaded. Please try again.',
                          ),
                        );
                      }
                      if (snap.hasData) {
                        final list = snap.data;

                        if (list.isEmpty && !_navigated) {
                          _navigated = true;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Login()),
                            );
                          });

                          return Container();
                        }

                        return Wrap(
                          alignment: WrapAlignment.center,
                          children: [...list],
                        );
                      }

                      return CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
