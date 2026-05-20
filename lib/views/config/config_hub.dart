import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/io_view.dart';
import 'package:iot_hub_client/widgets/io_material.dart';

class ConfigHub extends StatefulWidget {
  const ConfigHub({super.key});

  @override
  State<ConfigHub> createState() => _ConfigHubState();
}

class _ConfigHubState extends State<ConfigHub> {
  List<Map<String, dynamic>> _hubConfigs = [];
  bool _isLoading = true;
  final IHC ihc = IHC(TokenStore.token!);
  final IOHubClient ioHubClient = IOHubClient(
    TokenStore.token!.server,
    TokenStore.token?.token ?? '',
  );

  @override
  void initState() {
    super.initState();
    _loadHubConfigs();
  }

  Future<void> _loadHubConfigs() async {
    setState(() => _isLoading = true);
    try {
      final configs = await ihc.getConfigList();
      setState(() => _hubConfigs = configs);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave(String name, String value) async {
    await ihc.setConfigValue(name: name, value: value);
    // Optional: Snackbars können hier global oder im Tile getriggert werden
  }

  Future<void> _handleDelete(String name) async {
    await ioHubClient.configDelete(name);
    _loadHubConfigs();
  }

  @override
  Widget build(BuildContext context) {
    return IOHView(
      title: "HUB Config",
      body: SelectionArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildAddCard(),
                      const SizedBox(height: 32),
                      const Text(
                        "Existing Configs",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Hier wird das neue ConfigTile aufgerufen
                      ..._hubConfigs.map(
                        (config) => ConfigTile(
                          key: ValueKey(
                            config['name'],
                          ), // Wichtig für Listen-Stabilität
                          config: config,
                          onSave: _handleSave,
                          onDelete: _handleDelete,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddCard() {
    // Lokale Variablen für die neuen Eingaben
    final TextEditingController nameController = TextEditingController();
    final TextEditingController valueController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Exakt derselbe Rahmen wie beim ConfigTile
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              "Add Config",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment
                .center, // Richtet den Button an der unteren Kante aus
            children: [
              // Linke Seite: Eingabefelder untereinander
              Expanded(
                child: Column(
                  children: [
                    // Name Input
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Name",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8), // Abstand zwischen den Feldern
                    // Value Input
                    TextField(
                      controller: valueController,
                      decoration: InputDecoration(
                        hintText: "Value",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Rechte Seite: Add Button
              IconButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await ihc.setConfigValue(
                      name: nameController.text,
                      value: valueController.text,
                    );
                    nameController.clear();
                    valueController.clear();
                    _loadHubConfigs();
                  }
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.black87,
                  size: 40, // Etwas größer, da er nun neben zwei Feldern steht
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Das separate ConfigTile Widget ---

class ConfigTile extends StatefulWidget {
  final Map<String, dynamic> config;
  final Future<void> Function(String name, String value) onSave;
  final Future<void> Function(String name) onDelete;

  const ConfigTile({
    super.key,
    required this.config,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<ConfigTile> createState() => _ConfigTileState();
}

class _ConfigTileState extends State<ConfigTile> {
  late TextEditingController _controller;
  bool _isEdited = false;
  late String _originalValue;

  @override
  void initState() {
    super.initState();
    _originalValue = widget.config['value']?.toString() ?? '';
    _controller = TextEditingController(text: _originalValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkChanges(String value) {
    setState(() {
      _isEdited = value != _originalValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.config['name'] ?? 'Unnamed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEdited
              ? Colors.black87.withAlpha(150)
              : Colors.grey.shade200,
          width: _isEdited ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Colors.blueGrey),
                onPressed: () => _copy(name, "Name"),
              ),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
                onPressed: () => widget.onDelete(name),
              ),
            ],
          ),
          const Divider(height: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildInputRow(),
              const SizedBox(height: 12),
              _buildSaveButton(name),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.content_copy,
            size: 16,
            color: Colors.blueGrey,
          ),
          onPressed: () => _copy(_controller.text, "Value"),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: _checkChanges,
            decoration: ioInputDecoration(hintText: "Value eingeben..."),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(String name) {
    return ElevatedButton.icon(
      onPressed: _isEdited
          ? () async {
              await widget.onSave(name, _controller.text);
              setState(() {
                _originalValue = _controller.text;
                _isEdited = false;
              });
            }
          : null,
      label: const Text("Save"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade100,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label kopiert!"),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
