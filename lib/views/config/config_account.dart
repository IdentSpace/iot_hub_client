import 'package:flutter/material.dart';
import 'package:iot_hub_client/services/token_state.dart';

class ConfigAccount extends StatefulWidget {
  const ConfigAccount({super.key});

  @override
  State<ConfigAccount> createState() => _ConfigAccountState();
}

class _ConfigAccountState extends State<ConfigAccount> {
  final TextEditingController _tokenRext = TextEditingController();
  final token = TokenStore();

  Future<void> _loadConfig() async {
    final String n = await token.getName();
    _tokenRext.text = n;
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tokenRext,
                      decoration: const InputDecoration(
                        labelText: 'Accountname',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      token.setName(_tokenRext.text);
                    },
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
