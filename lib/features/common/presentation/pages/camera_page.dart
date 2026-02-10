import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart'; // For coordinates in watermark

class CameraPage extends StatefulWidget {
  final String? address;
  final Position? position;

  const CameraPage({super.key, this.address, this.position});

  @override
  State<CameraPage> createState() => _CameraPageState();
}
class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFrontCamera = true;
  File? _previewFile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _setCamera(_isFrontCamera);
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Camera Init Error: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _setCamera(bool isFront) async {
    setState(() => _isCameraInitialized = false);

    final camera = cameras!.firstWhere(
      (c) =>
          c.lensDirection ==
          (isFront ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => cameras!.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
        _isFrontCamera = isFront;
      });
    }
  }

  void _switchCamera() {
    if (cameras == null || cameras!.length < 2) return;
    _setCamera(!_isFrontCamera);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile imageFile = await _controller!.takePicture();
      final File processedImage = await _addWatermark(File(imageFile.path));

      if (mounted) {
        setState(() {
          _previewFile = processedImage;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Take Picture Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengambil foto: $e")));
        setState(() => _isProcessing = false);
      }
    }
  }

  void _retakePicture() {
    setState(() {
      _previewFile = null;
    });
  }

  void _submitPicture() {
    if (_previewFile != null) {
      Navigator.pop(context, _previewFile);
    }
  }

  Future<File> _addWatermark(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) return originalFile;

      // Prepare Text Content
      final DateTime now = DateTime.now();
      final String date =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      final String time =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} WIB";
      final String latLong = widget.position != null
          ? "Lat: ${widget.position!.latitude.toStringAsFixed(5)}, Long: ${widget.position!.longitude.toStringAsFixed(5)}"
          : "Lokasi Tidak Diketahui";
      final String address = widget.address ?? "-";

      // Combine text with labels
      final String watermarkText =
          "Tgl : $date\nJam : $time\n$latLong\nLokasi : $address";

      // Draw watermark text
      // Using basic font, white color
      img.drawString(
        image,
        watermarkText,
        font: img.arial24,
        x: 20,
        y: image.height - 120, // Position near bottom
        color: img.ColorRgb8(255, 255, 255),
      );

      final Directory dir = await getTemporaryDirectory();
      final String newPath =
          "${dir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final File newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(image));

      return newFile;
    } catch (e) {
      debugPrint("Watermark Error: $e");
      return originalFile;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_previewFile != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.file(_previewFile!, fit: BoxFit.contain),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.extended(
                    heroTag: "retake",
                    onPressed: _retakePicture,
                    label: const Text("Foto Ulang"),
                    icon: const Icon(Icons.refresh),
                    backgroundColor: Colors.red,
                  ),
                  FloatingActionButton.extended(
                    heroTag: "submit",
                    onPressed: _submitPicture,
                    label: const Text("Kirim"),
                    icon: const Icon(Icons.check),
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _switchCamera,
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Container(
                          margin: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
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
