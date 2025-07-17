import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/api/models/device.dart';

IHCToken? tokenState;

class AdminDevices extends StatefulWidget {
  const AdminDevices({super.key, required this.title});

  final String title;

  @override
  State<AdminDevices> createState() => _AdminDevicesState();
}

class _AdminDevicesState extends State<AdminDevices> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<Device>> _getDevices() async {
    tokenState = IHC.auth(
      server: "http://localhost:8005",
      username: "username",
      password: "password",
    );

    return IHC.getDevices(token: tokenState!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder(
              future: _getDevices(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Device>> snapshot) {
                    if (snapshot.hasData) {
                      final items = snapshot.data!;

                      return Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 600),
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return DeviceListItem(device: items[index]);
                            },
                          ),
                        ),
                      );
                    }

                    return const Text("No Data");
                  },
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceListItem extends StatefulWidget {
  final Device device;
  const DeviceListItem({super.key, required this.device});

  @override
  State<DeviceListItem> createState() => _DeviceListItemState();
}

class _DeviceListItemState extends State<DeviceListItem> {
  bool isOn = false;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    IHC.getDeviceState(token: tokenState!, deviceId: widget.device.id!).then((
      deviceState,
    ) {
      setState(() {
        isOn = deviceState!.powerState;
        isReady = true;
      });
    });
  }

  void _changeState() {
    if (tokenState == null) {
      debugPrint("NO TOKEN");
      return;
    }

    if (isOn) {
      IHC.setDeviceOff(token: tokenState!, deviceId: widget.device.id!);
      return setState(() {
        isOn = false;
      });
    }
    if (!isOn) {
      IHC.setDeviceOn(token: tokenState!, deviceId: widget.device.id!);
      return setState(() {
        isOn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: isReady
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          if (!isReady)
            const Center(
              child: SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.device.name ?? 'unknow'),
                  Text(widget.device.host ?? 'unknow'),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isOn ? Icons.toggle_on : Icons.toggle_off,
                size: 32,
                color: isOn ? Colors.green : Colors.grey,
              ),
              onPressed: _changeState,
            ),
          ],
        ],
      ),
    );
  }
}
