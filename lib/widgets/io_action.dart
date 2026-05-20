import 'package:flutter/material.dart';

class IOAction extends StatelessWidget {
  final String typeSlug;

  const IOAction({super.key, required this.typeSlug});

  @override
  Widget build(BuildContext context) {
    if (typeSlug.isEmpty) {
      return Container();
    }

    switch (typeSlug) {
      case 'lamp':
        return _defaulswitch(isOn: false);
      default:
        return Container();
    }
  }

  Widget _defaulswitch({required bool isOn, Function? callback}) {
    return IconButton(
      icon: Icon(
        isOn ? Icons.toggle_on : Icons.toggle_off,
        size: 32,
        color: isOn ? Colors.green : Colors.grey,
      ),
      onPressed: callback?.call(),
    );
  }
}
