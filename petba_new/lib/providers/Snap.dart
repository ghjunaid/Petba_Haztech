import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class SnapPage extends StatefulWidget {
  const SnapPage({super.key});

  @override
  State<SnapPage> createState() => _SnapPageState();
}

class _SnapPageState extends State<SnapPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _isFrontCamera = false;
  FlashMode _flashMode = FlashMode.off;
  String? _capturedMediaPath;
  bool _isVideo = false;

  // Snapchat-style recording
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  final int _maxRecordingSeconds = 10;
  AnimationController? _recordingAnimationController;
  Animation<double>? _recordingAnimation;

  // New animation controllers for Snapchat-style UI
  AnimationController? _captureButtonController;
  Animation<double>? _captureButtonScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Recording progress animation
    _recordingAnimationController = AnimationController(
      duration: Duration(seconds: _maxRecordingSeconds),
      vsync: this,
    );
    _recordingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController!,
      curve: Curves.linear,
    ));

    // Capture button animation
    _captureButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _captureButtonScale = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _captureButtonController!,
      curve: Curves.easeInOut,
    ));

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _recordingTimer?.cancel();
    _recordingAnimationController?.dispose();
    _captureButtonController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        int cameraIndex = _isFrontCamera ? 1 : 0;
        if (cameraIndex >= _cameras!.length) cameraIndex = 0;

        _cameraController = CameraController(
          _cameras![cameraIndex],
          ResolutionPreset.high,
          enableAudio: true,
        );

        await _cameraController!.initialize();
        await _cameraController!.setFlashMode(_flashMode);

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog('Failed to initialize camera: $e');
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isInitialized = false;
    });

    await _cameraController?.dispose();
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    setState(() {
      switch (_flashMode) {
        case FlashMode.off:
          _flashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          _flashMode = FlashMode.always;
          break;
        case FlashMode.always:
          _flashMode = FlashMode.off;
          break;
        case FlashMode.torch:
          _flashMode = FlashMode.off;
          break;
      }
    });

    try {
      await _cameraController!.setFlashMode(_flashMode);
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }

  Future<void> _capturePhoto() async {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    // Animate button press
    _captureButtonController!.forward().then((_) {
      _captureButtonController!.reverse();
    });

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String photoDir = '${appDir.path}/photos';
      await Directory(photoDir).create(recursive: true);

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String photoPath = '$photoDir/photo_$timestamp.jpg';

      final XFile photo = await cameraController.takePicture();
      await File(photo.path).copy(photoPath);

      if (mounted) {
        setState(() {
          _capturedMediaPath = photoPath;
          _isVideo = false;
        });

        _showSuccessDialog('Photo captured successfully!', Icons.camera_alt);
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        _showErrorDialog('Failed to capture photo: $e');
      }
    }
  }

  Future<void> _startVideoRecording() async {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    try {
      await cameraController.startVideoRecording();

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });

        // Start animation
        _recordingAnimationController!.forward();

        // Start timer for recording
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });

          // Auto-stop at max duration
          if (_recordingSeconds >= _maxRecordingSeconds) {
            _stopVideoRecording();
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting video recording: $e');
      if (mounted) {
        _showErrorDialog('Failed to start recording: $e');
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !_isRecording) return;

    // Cancel timer and animation
    _recordingTimer?.cancel();
    _recordingAnimationController!.reset();

    try {
      final XFile videoFile = await cameraController.stopVideoRecording();

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoDir = '${appDir.path}/videos';
      await Directory(videoDir).create(recursive: true);

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String videoPath = '$videoDir/video_$timestamp.mp4';

      await File(videoFile.path).copy(videoPath);

      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
          _capturedMediaPath = videoPath;
          _isVideo = true;
        });

        _showSuccessDialog('Video recorded successfully!', Icons.videocam);
      }
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      if (mounted) {
        _showErrorDialog('Failed to stop recording: $e');
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
        });
      }
    }
  }

  void _onCaptureButtonPressed() {
    if (!_isRecording) {
      _capturePhoto();
    }
  }

  void _onCaptureButtonLongPress() {
    if (!_isRecording) {
      _startVideoRecording();
    }
  }

  void _onCaptureButtonLongPressEnd() {
    if (_isRecording) {
      _stopVideoRecording();
    }
  }

  void _showSuccessDialog(String message, IconData icon) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCapturedMedia() {
    if (_capturedMediaPath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MediaPreviewPage(
            mediaPath: _capturedMediaPath!,
            isVideo: _isVideo,
            onMediaDeleted: () {
              setState(() {
                _capturedMediaPath = null;
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview (full screen)
          Positioned.fill(
            child: !_isInitialized
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
                : CameraPreview(_cameraController!),
          ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Flash button
                  IconButton(
                    icon: Icon(_getFlashIcon(), color: Colors.white, size: 28),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),

          // Recording timer (center top)
          if (_isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '0:${_recordingSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery preview
                    GestureDetector(
                      onTap: _capturedMediaPath != null ? _showCapturedMedia : null,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: _capturedMediaPath != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _isVideo
                              ? const Icon(Icons.videocam, color: Colors.white, size: 20)
                              : Image.file(
                            File(_capturedMediaPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(Icons.photo_library, color: Colors.white, size: 20),
                      ),
                    ),

                    // Snapchat-style capture button with circular progress
                    GestureDetector(
                      onTap: _onCaptureButtonPressed,
                      onLongPress: _onCaptureButtonLongPress,
                      onLongPressEnd: (_) => _onCaptureButtonLongPressEnd(),
                      child: AnimatedBuilder(
                        animation: _captureButtonScale!,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _captureButtonScale!.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring for recording progress
                                if (_isRecording)
                                  SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: AnimatedBuilder(
                                      animation: _recordingAnimation!,
                                      builder: (context, child) {
                                        return CircularProgressIndicator(
                                          value: _recordingAnimation!.value,
                                          strokeWidth: 4,
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                                        );
                                      },
                                    ),
                                  ),

                                // Main capture button
                                Container(
                                  width: 75,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isRecording ? Colors.red : Colors.white,
                                    border: Border.all(
                                      color: _isRecording ? Colors.red : Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: _isRecording
                                      ? const Icon(
                                    Icons.stop_rounded,
                                    color: Colors.white,
                                    size: 35,
                                  )
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Camera flip button
                    GestureDetector(
                      onTap: _cameras != null && _cameras!.length > 1 ? _switchCamera : null,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions overlay (only show when not recording)
          if (!_isRecording)
            Positioned(
              bottom: 220,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap to capture • Hold for video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// MediaPreviewPage remains the same as your original code
class MediaPreviewPage extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final VoidCallback? onMediaDeleted;

  const MediaPreviewPage({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    this.onMediaDeleted,
  });

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.mediaPath));
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.save_alt,
                  color: Colors.blue,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Save ${widget.isVideo ? 'Video' : 'Photo'} to Gallery?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _saveMedia();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete ${widget.isVideo ? 'Video' : 'Photo'}?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _deleteMedia();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveMedia() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String saveDir = '${appDir.path}/saved_media';
      await Directory(saveDir).create(recursive: true);

      final String fileName = widget.isVideo
          ? 'saved_video_${DateTime.now().millisecondsSinceEpoch}.mp4'
          : 'saved_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final String savePath = '$saveDir/$fileName';
      await File(widget.mediaPath).copy(savePath);

      if (context.mounted) {
        _showSuccessDialog('${widget.isVideo ? 'Video' : 'Photo'} saved successfully!', Icons.check_circle);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog('Failed to save: $e');
      }
    }
  }

  Future<void> _deleteMedia() async {
    try {
      final file = File(widget.mediaPath);
      if (await file.exists()) {
        await file.delete();
        if (context.mounted) {
          widget.onMediaDeleted?.call();
          Navigator.pop(context);
          _showSuccessDialog('${widget.isVideo ? 'Video' : 'Photo'} deleted!', Icons.delete);
        }
      } else {
        if (context.mounted) {
          _showErrorDialog('File not found!');
        }
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
      if (context.mounted) {
        _showErrorDialog('Failed to delete: $e');
      }
    }
  }

  void _showSuccessDialog(String message, IconData icon) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media preview
          Positioned.fill(
            child: Center(
              child: widget.isVideo
                  ? _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
                  : const CircularProgressIndicator(color: Colors.white)
                  : Image.file(
                File(widget.mediaPath),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
                    onPressed: () {
                      // Additional options can be added here
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Save button
                  GestureDetector(
                    onTap: _showSaveDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.save_alt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // Delete button
                  GestureDetector(
                    onTap: _showDeleteDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // Share button
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.share,
                                    color: Colors.blue,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Share functionality coming soon!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}