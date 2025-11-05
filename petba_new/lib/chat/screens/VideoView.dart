import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoViewPage extends StatefulWidget {
  const VideoViewPage({
    Key? key,
    required this.path,
    this.onVideoSend, // Add callback for video sending
  }) : super(key: key);

  final String path;
  final Function(String, String, String)? onVideoSend; // Callback function

  @override
  _VideoViewPageState createState() => _VideoViewPageState();
}

class _VideoViewPageState extends State<VideoViewPage> {
  late VideoPlayerController _controller;
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
              icon: Icon(
                Icons.crop_rotate,
                size: 27,
                color: Colors.white,
              ),
              onPressed: () {}
          ),
          IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                size: 27,
                color: Colors.white,
              ),
              onPressed: () {}
          ),
          IconButton(
              icon: Icon(
                Icons.title,
                size: 27,
                color: Colors.white,
              ),
              onPressed: () {}
          ),
          IconButton(
              icon: Icon(
                Icons.edit,
                size: 27,
                color: Colors.white,
              ),
              onPressed: () {}
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
              child: _controller.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : Container(),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                color: Colors.black38,
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: TextFormField(
                  controller: _captionController,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                  maxLines: 6,
                  minLines: 1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Add Caption....",
                    prefixIcon: Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 27,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () async {
                        await _sendVideoToChat(context);
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
            Align(
              alignment: Alignment.center,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.black38,
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendVideoToChat(BuildContext context) async {
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

      // Convert video to base64
      final bytes = await File(widget.path).readAsBytes();
      final base64Video = base64Encode(bytes);
      final fileName = widget.path.split('/').last;

      // Close loading dialog
      Navigator.of(context).pop();

      // If callback function is provided, use it
      if (widget.onVideoSend != null) {
        widget.onVideoSend!(widget.path, base64Video, fileName);
      }

      // Return to previous screen (chat screen)
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}