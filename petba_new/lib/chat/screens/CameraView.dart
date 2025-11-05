import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class CameraViewPage extends StatelessWidget {
  final String path;
  final Function(String, String, String)? onImageSend; // Callback function to handle image sending

  const CameraViewPage({
    Key? key,
    required this.path,
    this.onImageSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              // Add any image editing functionality here
            },
            icon: Icon(Icons.crop_rotate, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              // Add text overlay functionality
            },
            icon: Icon(Icons.text_fields, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              // Add drawing functionality
            },
            icon: Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - 150,
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                color: Colors.black54,
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: TextFormField(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                  maxLines: 6,
                  minLines: 1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Add Caption...",
                    hintStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                    prefixIcon: Icon(
                      Icons.add_photo_alternate,
                      color: Colors.white,
                      size: 27,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () async {
                        await _sendImageToChat(context);
                      },
                      child: CircleAvatar(
                        radius: 27,
                        backgroundColor: Colors.tealAccent[700],
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImageToChat(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Convert image to base64
      final bytes = await File(path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final fileName = path.split('/').last; // Alternative to basename

      // Close loading dialog
      Navigator.of(context).pop();

      // If callback function is provided, use it
      if (onImageSend != null) {
        onImageSend!(path, base64Image, fileName);
      }

      // Return to previous screen (chat screen)
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}