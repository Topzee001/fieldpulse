import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import '../providers/form_provider.dart';
import '../../../services/photo_upload_service.dart';

class ChecklistPhotoField extends ConsumerStatefulWidget {
  final int jobId;
  final String fieldId;
  final String label;
  final int maxPhotos;

  const ChecklistPhotoField({
    super.key,
    required this.jobId,
    required this.fieldId,
    required this.label,
    this.maxPhotos = 1,
  });

  @override
  ConsumerState<ChecklistPhotoField> createState() =>
      _ChecklistPhotoFieldState();
}

class _ChecklistPhotoFieldState extends ConsumerState<ChecklistPhotoField> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<String?> _captureAndCompressPhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (photo == null) return null;

    setState(() => _isUploading = true);

    // Get location
    String locationText = '';
    try {
      final location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await location.requestService();
      
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
      }
      
      if (permissionGranted == PermissionStatus.granted || 
          permissionGranted == PermissionStatus.grantedLimited) {
        final locData = await location.getLocation();
        if (locData.latitude != null && locData.longitude != null) {
          locationText = 'Lat: ${locData.latitude!.toStringAsFixed(4)}, Lon: ${locData.longitude!.toStringAsFixed(4)}';
        }
      }
    } catch (e) {
      // Ignore location errors, just proceed without it
    }

    final File original = File(photo.path);
    final bytes = await original.readAsBytes();
    img.Image? capturedImage = img.decodeImage(bytes);
    if (capturedImage != null) {
      capturedImage = img.bakeOrientation(capturedImage);
      
      // Draw timestamp and location overlay
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final overlayText = locationText.isNotEmpty ? '$timestamp\n$locationText' : timestamp;
      
      // Draw text with a semi-transparent black background for readability
      // Using arial24 for good visibility on 1200px images
      final lines = overlayText.split('\n');
      final font = img.arial24;
      final padding = 10;
      final lineHeight = font.lineHeight;
      final totalHeight = (lines.length * lineHeight) + (padding * 2);
      
      // Draw background rect at bottom left
      img.fillRect(
        capturedImage, 
        x1: 0, 
        y1: capturedImage.height - totalHeight, 
        x2: capturedImage.width, 
        y2: capturedImage.height, 
        color: img.ColorRgb8(0, 0, 0),
      );
      
      // Draw text lines
      for (int i = 0; i < lines.length; i++) {
        img.drawString(
          capturedImage, 
          lines[i], 
          font: font, 
          x: padding, 
          y: capturedImage.height - totalHeight + padding + (i * lineHeight),
          color: img.ColorRgb8(255, 255, 255),
        );
      }

      final compressedBytes = img.encodeJpg(capturedImage, quality: 80);
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg')
        ..writeAsBytesSync(compressedBytes);
      return compressedFile.path;
    }
    return original.path;
  }

  Future<void> _addPhoto() async {
    final path = await _captureAndCompressPhoto();
    if (path == null) return;

    setState(() => _isUploading = true);

    try {
      final uploadService = ref.read(photoUploadServiceProvider);
      final uploadedUrl = await uploadService.uploadPhoto(
        jobId: widget.jobId,
        fieldId: widget.fieldId,
        filePath: path,
      );
      _addToFormState(uploadedUrl);
    } catch (e) {
      // Store local path for offline sync
      _addToFormState(path);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _addToFormState(String path) {
    final notifier =
        ref.read(checklistFormProvider(widget.jobId).notifier);
    final currentPhotos =
        List<String>.from(notifier.state.values[widget.fieldId] ?? []);
    currentPhotos.add(path);
    notifier.updateField(widget.fieldId, currentPhotos);
  }

  void _removePhoto(int index) {
    final notifier =
        ref.read(checklistFormProvider(widget.jobId).notifier);
    final currentPhotos =
        List<String>.from(notifier.state.values[widget.fieldId] ?? []);
    currentPhotos.removeAt(index);
    notifier.updateField(widget.fieldId, currentPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checklistFormProvider(widget.jobId));
    final photos =
        List<String>.from(state.values[widget.fieldId] ?? []);
    final canAddMore = photos.length < widget.maxPhotos;

    final error = state.errors[widget.fieldId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label} (${photos.length}/${widget.maxPhotos})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...photos.asMap().entries.map((entry) {
              return _buildPhotoThumbnail(entry.key, entry.value);
            }),
            if (canAddMore && !_isUploading) _buildAddButton(),
            if (_isUploading)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                    child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(int index, String path) {
    // Backend paths might come as '/media/...' or 'media/...'
    final isBackendMedia = path.startsWith('/media/') || path.startsWith('media/');
    // If it's a backend relative path, prepend localhost. 
    // Need to handle both with and without leading slash.
    final displayUrl = isBackendMedia 
        ? (path.startsWith('/') ? 'http://localhost:8000$path' : 'http://localhost:8000/$path') 
        : path;
    final isNetwork = displayUrl.startsWith('http');

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      InteractiveViewer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isNetwork
                              ? Image.network(displayUrl, fit: BoxFit.contain)
                              : Image.file(File(displayUrl), fit: BoxFit.contain),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetwork
                  ? Image.network(displayUrl,
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildErrorIcon())
                  : Image.file(File(displayUrl),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildErrorIcon()),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 24, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}