import 'package:flutter/material.dart';
import 'package:iot_hub_client/views/admin/config_app.dart';
import 'package:iot_hub_client/views/config/config_account.dart';
import 'package:iot_hub_client/views/config/config_hub.dart';
import 'package:iot_hub_client/views/config/test_ioh.dart';
import 'package:iot_hub_client/views/io_view.dart';
import 'package:iot_hub_client/views/login.dart';
import 'package:iot_hub_client/views/login_select_token.dart';
import 'package:iot_hub_client/widgets/io_card.dart';

class ConfigItem {
  final String name;
  final Function callback;

  ConfigItem({required this.name, required this.callback});
}

class ConfigOverview extends StatelessWidget {
  const ConfigOverview({super.key});

  void _navigate(
    BuildContext context,
    Function call, {
    bool removeUntil = false,
  }) {
    if (removeUntil) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => call()),
        (route) => false,
      );
      return;
    }
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
      ConfigItem(
        name: "Switch Account",
        callback: () =>
            _navigate(context, () => LoginSelectToken(), removeUntil: true),
      ),
      ConfigItem(
        name: "Account",
        callback: () => _navigate(context, () => ConfigAccount()),
      ),
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
        callback: () => _navigate(context, () => ConfigHub()),
      ),
      ConfigItem(
        name: "Test",
        callback: () => _navigate(context, () => TestIOH()),
      ),
      ConfigItem(name: "About", callback: () => _notImplemented(context)),
      ConfigItem(name: "Licenses", callback: () => _notImplemented(context)),
    ];

    return IOHView(
      body: Column(
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
    );
  }

  Widget configItem(ConfigItem item) {
    return GestureDetector(
      onTap: () => item.callback(),
      child: IOCard(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [Text(item.name)]),
      ),
    );
  }
}
