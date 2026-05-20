import 'package:flutter/material.dart';

class IOHView extends StatefulWidget {
  final Widget body;
  final String? title;
  final double maxWidth;

  const IOHView({
    super.key,
    required this.body,
    this.title,
    this.maxWidth = 600,
  });

  @override
  State<IOHView> createState() => _IOHViewState();
}

class _IOHViewState extends State<IOHView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title ?? ''),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: widget.body,
        ),
      ),
    );
  }
}
