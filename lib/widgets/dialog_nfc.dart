import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';

Future<void> showNfcDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      String? result;
      bool isLoading = true;

      late StateSetter setState;

      return StatefulBuilder(
        builder: (context, innerSetState) {
          setState = innerSetState;

          if (isLoading) {
            IHC
                .readNFC(demo: true)
                .then((onValue) {
                  if (context.mounted) {
                    setState(() {
                      result = onValue;
                      isLoading = false;
                    });
                  }
                })
                .catchError((onError) {
                  if (context.mounted) {
                    setState(() {
                      result = "ERROR";
                      isLoading = false;
                      debugPrint(onError.toString());
                    });
                  }
                });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("READ NFC", style: TextStyle(fontSize: 20)),
                  SizedBox(height: 50),

                  if (isLoading) ...[
                    CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text("Waiting for a NFC Card..."),
                  ] else ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text("NFC-ID: $result", textAlign: TextAlign.center),
                  ],

                  SizedBox(height: 50),
                  if (isLoading) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text("Cancel"),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text("OK"),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
