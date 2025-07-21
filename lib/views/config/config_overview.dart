import 'package:flutter/material.dart';
import 'package:iot_hub_client/views/admin/config_app.dart';
import 'package:iot_hub_client/views/login.dart';

class ConfigItem {
  final String name;
  final Function callback;

  ConfigItem({required this.name, required this.callback});
}

class ConfigOverview extends StatelessWidget {
  const ConfigOverview({super.key});

  void _navigate(BuildContext context, Function call) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => call()));
  }

  void _notImplemented(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Not implemented yet!")));
    debugPrint("Not implemented yet!");
  }

  @override
  Widget build(BuildContext context) {
    List<ConfigItem> menuItems = [
      ConfigItem(name: "Account", callback: () => _notImplemented(context)),
      ConfigItem(
        name: "Logout",
        callback: () => _navigate(context, () => Login()),
      ),
      ConfigItem(
        name: "App Settings",
        callback: () => _navigate(context, () => ConfigApp()),
      ),
      ConfigItem(
        name: "Hub Configuration",
        callback: () => _notImplemented(context),
      ),
      ConfigItem(name: "About", callback: () => _notImplemented(context)),
      ConfigItem(name: "Licenses", callback: () => _notImplemented(context)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    return configItem(menuItems[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget configItem(ConfigItem item) {
    return GestureDetector(
      onTap: () => item.callback(),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),

        child: Row(children: [Text(item.name)]),
      ),
    );
  }
}
