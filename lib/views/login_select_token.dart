import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';

class LoginSelectToken extends StatelessWidget {
  const LoginSelectToken({super.key});

  @override
  Widget build(BuildContext context) {
    AppDatabase db = AppDatabase.instance;

    Future<List> getTokens() async {
      final List<Token> tokens = await (db.select(db.tokens)).get();

      final List<Widget> list = [];

      for (var t in tokens) {
        list.add(
          userCard(
            t,
            () => {
              TokenStore.setToken(IHCToken(t.name ?? '', t.server)),
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeviceList()),
              ),
            },
          ),
        );
      }

      return list;
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Select User", style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),

            FutureBuilder(
              future: getTokens(),
              builder: (BuildContext context, AsyncSnapshot snap) {
                if (snap.hasData) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [...snap.data],
                  );
                }

                return CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget userCard(Token token, Function callback) {
    return GestureDetector(
      onTap: () => callback(),
      child: Container(
        height: 150,
        width: 250,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: EdgeInsets.all(8),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text(token.name ?? "NO NAME"), Text(token.server)],
        ),
      ),
    );
  }
}
