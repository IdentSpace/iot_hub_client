import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/api/models/device.dart';
import 'package:iot_hub_client/main.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_register.dart';
import 'package:iot_hub_client/views/config/config_overview.dart';
import 'package:iot_hub_client/widgets/dialog_nfc.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({super.key});

  @override
  State<DeviceList> createState() => _AdminDevicesState();
}

class _AdminDevicesState extends State<DeviceList> with RouteAware {
  List<Device> devices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  Future<void> _getDevices() async {
    setState(() => isLoading = true);

    final token = TokenStore.token;

    if (token == null) {
      return setState(() => isLoading = false);
    }

    final loadedDevices = await IHC.getDevices(token: token);
    setState(() {
      devices = loadedDevices;
      isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    _getDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Device list"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfigOverview()),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return DeviceListItem(device: devices[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeviceRegister()),
          );
        },
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
    IHC
        .getDeviceState(token: TokenStore.token!, deviceId: widget.device.id)
        .then((deviceState) {
          setState(() {
            isOn = deviceState == null ? false : deviceState.powerState;
            isReady = true;
          });
        });
  }

  void _changeState() {
    if (TokenStore.token == null) {
      debugPrint("NO TOKEN");
      return;
    }

    if (isOn) {
      IHC.setDeviceOff(token: TokenStore.token!, deviceId: widget.device.id);
      return setState(() {
        isOn = false;
      });
    }
    if (!isOn) {
      IHC.setDeviceOn(token: TokenStore.token!, deviceId: widget.device.id);
      return setState(() {
        isOn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceRegister(device: widget.device),
          ),
        ),
      },
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
              shortAction(context: context, driver: widget.device.driver),
            ],
          ],
        ),
      ),
    );
  }

  Widget shortAction({required BuildContext context, String? driver}) {
    debugPrint(driver);
    switch (driver) {
      case 'shelly_http':
        return IconButton(
          icon: Icon(
            isOn ? Icons.toggle_on : Icons.toggle_off,
            size: 32,
            color: isOn ? Colors.green : Colors.grey,
          ),
          onPressed: _changeState,
        );
      case 'nfc':
        return IconButton(
          onPressed: () => showNfcDialog(context),
          icon: Icon(Icons.nfc),
        );
      default:
        return Container();
    }
  }
}
