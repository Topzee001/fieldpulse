import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isUploading = false;
  Size _canvasSize = const Size(400, 150);

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (_currentStroke.isNotEmpty) {
        _strokes.add(List.from(_currentStroke));
        _currentStroke.clear();
      }
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  bool get _isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  Future<String?> _captureSignature() async {
    if (_isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height),
      backgroundPaint,
    );

    final strokePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> stroke) {
      if (stroke.length < 2) return;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }

    for (final stroke in _strokes) {
      drawStroke(stroke);
    }
    drawStroke(_currentStroke);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _canvasSize.width.toInt(),
      _canvasSize.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
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
      final notifier = ref.read(checklistFormProvider(widget.jobId).notifier);
      notifier.updateField(widget.fieldId, uploadedUrl);
    } catch (e) {
      final notifier = ref.read(checklistFormProvider(widget.jobId).notifier);
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
    final isBackendMedia = signatureUrl.startsWith('/media/') || signatureUrl.startsWith('media/');
    final displayUrl = isBackendMedia
        ? (signatureUrl.startsWith('/')
            ? 'http://localhost:8000$signatureUrl'
            : 'http://localhost:8000/$signatureUrl')
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
                ? Image.network(displayUrl,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40))
                : Image.file(File(displayUrl),
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              final notifier = ref.read(checklistFormProvider(widget.jobId).notifier);
              notifier.updateField(widget.fieldId, null);
              _clear();
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(constraints.maxWidth, 150);
                return Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.white,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: SignaturePainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                      ),
                    ),
                  ),
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
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saveSignature,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> stroke) {
      if (stroke.length < 2) return;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
