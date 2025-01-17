import 'package:flutter/material.dart';

class MicPopup extends StatelessWidget {
  final VoidCallback onStopListening;

  const MicPopup({super.key, required this.onStopListening});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, size: 60, color: Colors.redAccent),
            SizedBox(height: 10),
            Text("Listening...", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                onStopListening();
                Navigator.pop(context);
              },
              icon: Icon(Icons.stop, color: Colors.white),
              label: Text("Stop"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
