import 'package:flutter/material.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/widgets/io_card.dart';
import 'package:iot_hub_client/widgets/state_info.dart';

class HubCard extends StatefulWidget {
  final Token token;
  final Function? onClick;
  final Function? onLogout;

  const HubCard({required this.token, this.onClick, this.onLogout, super.key});

  @override
  State<HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<HubCard> {
  bool hasConnection = false;
  late Stream<IOHState?> _hubStream;
  late IOHubClient _ioHubClient;

  final AppDatabase db = AppDatabase.instance;

  @override
  void initState() {
    super.initState();
    _ioHubClient = IOHubClient(widget.token.server, widget.token.token ?? '');
    _hubStream = Stream.periodic(const Duration(seconds: 2)).asyncMap((
      _,
    ) async {
      try {
        final state = await _ioHubClient.state();
        if (state == null) {
          setState(() {
            hasConnection = false;
          });
          return null;
        }
        setState(() {
          hasConnection = true;
        });
        return state;
      } catch (e) {
        setState(() {
          hasConnection = false;
        });
        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hasConnection ? widget.onClick?.call() : null,
      child: Container(
        height: 200,
        width: 300,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: EdgeInsets.all(8),

        child: IOCard(
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
                      await db.deleteToken(widget.token.token ?? ''),
                      if (widget.onLogout != null) {widget.onLogout?.call()},
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
                  children: [
                    Text(widget.token.name ?? "IOHub"),
                    Text(widget.token.server),
                    SizedBox(height: 10),
                    StreamBuilder<IOHState?>(
                      stream: _hubStream,
                      builder:
                          ((
                            BuildContext buildContext,
                            AsyncSnapshot<IOHState?> snap,
                          ) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return StateInfo(text: "", isLoading: true);
                            }

                            if (snap.hasError) {
                              return StateInfo(text: "Fehler");
                            }

                            if (snap.data == null) {
                              return StateInfo(text: "No Connection");
                            }

                            return StateInfo(text: snap.data!.version);
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
