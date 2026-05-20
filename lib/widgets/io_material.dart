import 'package:flutter/material.dart';

InputDecoration ioInputDecoration({String hintText = ''}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

Widget formFieldContainer({required FormField formField, String label = ''}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(label), formField],
  );
}
