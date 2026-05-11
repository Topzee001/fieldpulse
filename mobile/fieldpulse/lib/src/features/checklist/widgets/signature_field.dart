import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/form_provider.dart';
import '../../../services/photo_upload_service.dart';

class ChecklistSignatureField extends ConsumerStatefulWidget {
  final int jobId;
  final String fieldId;
  final String label;

  const ChecklistSignatureField({
    super.key,
    required this.jobId,
    required this.fieldId,
    required this.label,
  });

  @override
  ConsumerState<ChecklistSignatureField> createState() =>
      _ChecklistSignatureFieldState();
}

class _ChecklistSignatureFieldState
    extends ConsumerState<ChecklistSignatureField> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _isUploading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _captureSignature() async {
    if (_controller.isNotEmpty) {
      final signatureImage = await _controller.toImage();
      if (signatureImage == null) return null;
      final bytes =
          await signatureImage.toByteData(format: ImageByteFormat.png);
      if (bytes == null) return null;
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      return file.path;
    }
    return null;
  }

  Future<void> _saveSignature() async {
    final path = await _captureSignature();
    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please draw your signature first')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uploadService = ref.read(photoUploadServiceProvider);
      final uploadedUrl = await uploadService.uploadSignature(
        jobId: widget.jobId,
        fieldId: widget.fieldId,
        filePath: path,
      );
      final notifier =
          ref.read(checklistFormProvider(widget.jobId).notifier);
      notifier.updateField(widget.fieldId, uploadedUrl);
    } catch (e) {
      // Queue offline — store local path
      final notifier =
          ref.read(checklistFormProvider(widget.jobId).notifier);
      notifier.updateField(widget.fieldId, path);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checklistFormProvider(widget.jobId));
    final signatureUrl = state.values[widget.fieldId] as String?;
    final hasSignature = signatureUrl != null && signatureUrl.isNotEmpty;
    final error = state.errors[widget.fieldId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        if (hasSignature && !_isUploading)
          _buildSavedSignature(signatureUrl)
        else if (_isUploading)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _buildSignaturePad(),
      ],
    );
  }

  Widget _buildSavedSignature(String signatureUrl) {
    // Backend paths might come as '/media/...' or 'media/...'
    final isBackendMedia = signatureUrl.startsWith('/media/') || signatureUrl.startsWith('media/');
    final displayUrl = isBackendMedia 
        ? (signatureUrl.startsWith('/') ? 'http://localhost:8000$signatureUrl' : 'http://localhost:8000/$signatureUrl') 
        : signatureUrl;
    final isNetwork = displayUrl.startsWith('http');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: isNetwork
                ? Image.network(displayUrl, height: 80, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40))
                : Image.file(File(displayUrl),
                    height: 80, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              final notifier =
                  ref.read(checklistFormProvider(widget.jobId).notifier);
              notifier.updateField(widget.fieldId, null);
              _controller.clear();
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturePad() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Signature(
                  controller: _controller,
                  width: constraints.maxWidth,
                  height: 150,
                  backgroundColor: Colors.white,
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _controller.clear(),
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saveSignature,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}