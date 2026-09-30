import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/ocr_service.dart';
import '../theme/app_colors.dart';
import '../widgets/camera/crop_framing_overlay.dart';
import 'receipt_review_screen.dart';
import 'sample_receipts_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Đang khởi động camera...';

  // Tap-to-focus animation state
  Offset? _focusPoint;
  bool _showFocusRing = false;

  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isCameraInitialized = false;
          _statusMessage = 'Không tìm thấy thiết bị Camera trên máy này.';
        });
        return;
      }

      await _startCamera(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _isCameraInitialized = false;
        _statusMessage = 'Không thể kết nối Camera: $e\nBạn có thể chọn ảnh từ thư viện hoặc thử hóa đơn mẫu.';
      });
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _statusMessage = 'Lỗi khởi động camera: $e';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode nextMode;
    if (_flashMode == FlashMode.off) {
      nextMode = FlashMode.torch;
    } else if (_flashMode == FlashMode.torch) {
      nextMode = FlashMode.auto;
    } else {
      nextMode = FlashMode.off;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_selectedCameraIndex]);
  }

  void _onTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final x = details.localPosition.dx / constraints.maxWidth;
    final y = details.localPosition.dy / constraints.maxHeight;

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusRing = true;
    });

    try {
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setExposurePoint(Offset(x, y));
    } catch (e) {
      debugPrint('Error setting focus: $e');
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showFocusRing = false);
      }
    });
  }

  Rect _calculateFrameRect(Size screenSize) {
    // Aspect ratio 3:4 for receipts
    final width = screenSize.width * 0.84;
    final height = width * 1.35;
    final left = (screenSize.width - width) / 2;
    final top = (screenSize.height - height) / 2 - 20;
    return Rect.fromLTWH(left, top, width, height);
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang chụp & nhận diện Google ML Kit...';
    });

    try {
      final xFile = await _controller!.takePicture();
      final originalFile = File(xFile.path);

      // Crop image strictly to framing rect
      final croppedPath = await _cropImageToFraming(originalFile);

      // Run Google ML Kit OCR and regex heuristics
      final parsedReceipt = await _ocrService.processReceiptImage(croppedPath);

      if (mounted) {
        setState(() => _isProcessing = false);
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ReceiptReviewScreen(
              parsedReceipt: parsedReceipt,
              capturedImagePath: croppedPath,
            ),
          ),
        );
        if (saved == true && mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang xử lý ảnh từ thư viện...';
    });

    try {
      final parsed = await _ocrService.processReceiptImage(image.path);
      if (mounted) {
        setState(() => _isProcessing = false);
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ReceiptReviewScreen(
              parsedReceipt: parsed,
              capturedImagePath: image.path,
            ),
          ),
        );
        if (saved == true && mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xử lý ảnh: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<String> _cropImageToFraming(File sourceFile) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return sourceFile.path;

      // Crop central 80% width and 75% height
      final cropW = (decoded.width * 0.82).toInt();
      final cropH = (decoded.height * 0.72).toInt();
      final cropX = ((decoded.width - cropW) / 2).toInt();
      final cropY = ((decoded.height - cropH) / 2).toInt();

      final cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final tempDir = await getTemporaryDirectory();
      final croppedFile = File(
        p.join(tempDir.path, 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg'),
      );
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));
      return croppedFile.path;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return sourceFile.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewfinder or Fallback
          if (_isCameraInitialized && _controller != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _onTapToFocus(details, constraints),
                  child: Center(
                    child: CameraPreview(_controller!),
                  ),
                );
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded, size: 54, color: AppColors.darkTextMuted),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SampleReceiptsScreen()),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('Thử hóa đơn siêu thị mẫu'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Crop Framing Overlay with Corner Brackets & Laser
          if (_isCameraInitialized)
            CropFramingOverlay(
              onGetFrameRect: _calculateFrameRect,
            ),

          // 3. Tap to Focus Ring
          if (_showFocusRing && _focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 32,
              top: _focusPoint!.dy - 32,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.filter_center_focus_rounded, size: 28, color: AppColors.accent),
                ),
              ),
            ),

          // 4. Top Controls (Back, Flash, Switch Camera, Sample Demo)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                Row(
                  children: [
                    // Flash Mode Toggle
                    CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.torch
                              ? Icons.flash_on_rounded
                              : (_flashMode == FlashMode.auto ? Icons.flash_auto_rounded : Icons.flash_off_rounded),
                          color: _flashMode != FlashMode.off ? AppColors.warning : Colors.white,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Switch Camera (Front/Back)
                    if (_cameras.length > 1)
                      CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                          onPressed: _switchCamera,
                        ),
                      ),
                    const SizedBox(width: 8),

                    // Sample Receipts Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SampleReceiptsScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.85),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.receipt_rounded, size: 16),
                      label: const Text('Mẫu test', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 5. Instruction banner above bottom controls
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Căn hóa đơn vừa khung hình • Chạm để lấy nét',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),

          // 6. Bottom Controls (Gallery, Shutter Button, Sample)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery Picker
                IconButton(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 32),
                  tooltip: 'Chọn ảnh từ thư viện',
                ),

                // Capture Shutter Button
                GestureDetector(
                  onTap: _captureAndProcess,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),

                // Mock Sample Receipts Trigger
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SampleReceiptsScreen()),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.warning, size: 32),
                  tooltip: 'Thử mẫu hóa đơn có sẵn',
                ),
              ],
            ),
          ),

          // 7. Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.accent),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đang phân tích số tiền, ngày và cửa hàng...',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
