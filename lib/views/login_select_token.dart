import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';
import 'package:iot_hub_client/views/io_view.dart';
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
    return IOHView(
      maxWidth: 1000,
      body: Column(
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
    );
  }
}
