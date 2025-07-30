import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';
import 'package:iot_hub_client/views/login.dart';

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Select Account", style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),

            FutureBuilder(
              future: _futureList,
              builder: (BuildContext context, AsyncSnapshot snap) {
                if (snap.hasData) {
                  final list = snap.data;

                  if (list.isEmpty && !_navigated) {
                    _navigated = true;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                }),
              },
              child: Text("Add Account"),
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
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async => {
                    await widget.db.deleteToken(token.token ?? ''),
                    setState(() {
                      _getTokens();
                    }),
                  },
                  label: Text("Logout"),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Text(token.name ?? "NO NAME"), Text(token.server)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
