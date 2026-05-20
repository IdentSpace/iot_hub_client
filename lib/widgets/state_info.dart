import 'package:flutter/material.dart';

class StateInfo extends StatelessWidget {
  final String text;
  final bool isLoading;

  const StateInfo({super.key, required this.text, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1,
          color: isLoading
              ? const Color.fromARGB(255, 0, 0, 0).withAlpha(100)
              : Colors.grey.withAlpha(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Passt sich dem Inhalt an
        children: [
          if (isLoading) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ),
          ],

          if (isLoading && text.isNotEmpty) const SizedBox(width: 12),

          if (text.isNotEmpty)
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}
