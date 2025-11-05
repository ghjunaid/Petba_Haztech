import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:convert';

class Replymessage extends StatefulWidget {
  const Replymessage({
    Key? key,
    required this.message,
    required this.time,
    this.messageType = "text",
    this.base64Image,
    this.fileName,
    this.senderName,
  }) : super(key: key);

  final String message;
  final String time;
  final String messageType;
  final String? base64Image;
  final String? fileName;
  final String? senderName;

  @override
  _ReplymessageState createState() => _ReplymessageState();
}

class _ReplymessageState extends State<Replymessage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.messageType == "video") {
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    try {
      // For video messages, try multiple approaches
      if (widget.base64Image != null && widget.base64Image!.isNotEmpty) {
        // For base64 video data, we'll show a placeholder for now
        // In a real app, you'd need to save base64 to temp file first
        print('Video base64 data available, showing placeholder');
        return;
      }

      // Check if it's a local file path
      if (widget.message.isNotEmpty &&
          (widget.message.startsWith('/') || widget.message.contains('/'))) {
        File videoFile = File(widget.message);
        if (videoFile.existsSync()) {
          _videoController = VideoPlayerController.file(videoFile);
          _videoController!.initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
            }
          }).catchError((error) {
            print('Error initializing video player: $error');
          });
        }
      }
    } catch (e) {
      print('Error setting up video player: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatTime(String timeString) {
    try {
      // Handle different time formats
      if (timeString.contains(':') && timeString.length <= 5) {
        // Already formatted as HH:MM
        return timeString;
      }

      DateTime dateTime;
      if (timeString.contains('T') || timeString.contains('-')) {
        // ISO format or date string
        dateTime = DateTime.parse(timeString);
      } else {
        // Assume timestamp in milliseconds
        int timestamp = int.tryParse(timeString) ?? DateTime.now().millisecondsSinceEpoch;
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      String hour = dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      print('Error formatting time: $e');
      return "00:00";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 45,
        ),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name header for received messages
                  if (widget.senderName != null && widget.senderName!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(left: 20, right: 10, top: 8),
                      child: Text(
                        widget.senderName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),

                  // Message content
                  Padding(
                    padding: EdgeInsets.only(
                      left: (widget.messageType == "image" ||
                          widget.messageType == "video") ? 5 : 20,
                      right: 10,
                      top: (widget.senderName != null && widget.senderName!.isNotEmpty) ? 4 :
                      (widget.messageType == "image" || widget.messageType == "video") ? 5 : 10,
                      bottom: 20,
                    ),
                    child: _buildMessageContent(),
                  ),
                ],
              ),
              Positioned(
                bottom: 4,
                right: 10,
                child: Text(
                  _formatTime(widget.time),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.messageType?.toLowerCase()) {
      case "text":
      case "adoption_request":
        return Text(
          widget.message,
          style: TextStyle(fontSize: 16, color: Colors.black),
        );
      case "image":
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(),
        );
      case "video":
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildVideoWidget(),
        );
      default:
        return Text(
          widget.message,
          style: TextStyle(fontSize: 16, color: Colors.black),
        );
    }
  }

  Widget _buildImageWidget() {
    print('Building reply image widget - messageType: ${widget.messageType}, message: ${widget.message}, base64Image exists: ${widget.base64Image != null}');

    // Try base64 data first (most common for received images)
    if (widget.base64Image != null && widget.base64Image!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(widget.base64Image!),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error displaying base64 image: $error');
            return _buildErrorWidget("image");
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    }

    // Try local file path (less common for received messages)
    if (widget.message.isNotEmpty) {
      // Check if it looks like a file path
      if (widget.message.startsWith('/') ||
          widget.message.contains('/') ||
          widget.message.contains('\\')) {
        try {
          File imageFile = File(widget.message);
          if (imageFile.existsSync()) {
            return Image.file(
              imageFile,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error displaying local image: $error');
                return _buildErrorWidget("image");
              },
            );
          } else {
            print('Image file does not exist: ${widget.message}');
          }
        } catch (e) {
          print('Error accessing local file: $e');
        }
      }

      // Try as base64 data (fallback)
      try {
        return Image.memory(
          base64Decode(widget.message),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget("image");
          },
        );
      } catch (e) {
        print('Error decoding message as base64: $e');
      }
    }

    return _buildErrorWidget("image");
  }

  Widget _buildVideoWidget() {
    print('Building reply video widget - message: ${widget.message}, base64Image exists: ${widget.base64Image != null}');

    // For received videos with base64 data, show enhanced placeholder
    if (widget.base64Image != null && widget.base64Image!.isNotEmpty) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail placeholder
            Icon(
              Icons.video_library,
              size: 60,
              color: Colors.white70,
            ),

            // Play button (placeholder)
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Video playback not available for received videos'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            // Video indicator
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      widget.fileName ?? "Video",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // For local videos, use the existing video player logic
    return Container(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player or placeholder
          if (_videoController != null && _isVideoInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          else
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.video_library,
                size: 50,
                color: Colors.grey[600],
              ),
            ),

          // Play/Pause button overlay
          GestureDetector(
            onTap: () {
              if (_videoController != null && _isVideoInitialized) {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Video cannot be played')),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                (_videoController != null && _videoController!.value.isPlaying)
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          // Video duration indicator (if available)
          if (_videoController != null && _isVideoInitialized)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(_videoController!.value.duration),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String type) {
    IconData icon = type == "video" ? Icons.video_library : Icons.broken_image;
    String text = type == "video" ? "Video unavailable" : "Image unavailable";

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[600], size: 40),
          SizedBox(height: 8),
          Text(
            widget.fileName ?? text,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}