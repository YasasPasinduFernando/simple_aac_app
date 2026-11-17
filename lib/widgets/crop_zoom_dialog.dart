import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../utils/card_image.dart';
import '../utils/image_crop_helper.dart';

/// Modal dialog providing interactive 1:1 Crop & Zoom for card images.
/// Features:
/// - 1:1 square crop frame with subtle 3x3 rule-of-thirds grid
/// - Distinct white corner bracket markers
/// - Pinch-to-zoom and drag/pan gesture controls
/// - Clamp constraints preventing empty margins
/// - Precision zoom slider (1.0x to 3.5x) with minus/plus step buttons
/// - Reset to center 1.0x action
/// - Clean Cancel and Use Photo commitment
class CropZoomDialog extends StatefulWidget {
  final String imagePath;
  final int targetDimension;

  const CropZoomDialog({
    Key? key,
    required this.imagePath,
    this.targetDimension = 640,
  }) : super(key: key);

  /// Shows the Crop & Zoom dialog and returns the path to the newly cropped image file,
  /// or null if the user cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String imagePath,
    int targetDimension = 640,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CropZoomDialog(
        imagePath: imagePath,
        targetDimension: targetDimension,
      ),
    );
  }

  @override
  State<CropZoomDialog> createState() => _CropZoomDialogState();
}

class _CropZoomDialogState extends State<CropZoomDialog> {
  double _zoom = 1.0;
  Offset _pan = Offset.zero;

  double _baseZoom = 1.0;
  Offset _basePan = Offset.zero;

  double? _srcWidth;
  double? _srcHeight;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  static const double _viewportSize = 280.0;
  static const double _minZoom = 1.0;
  static const double _maxZoom = 3.5;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    try {
      final Uint8List bytes;
      if (isAssetImagePath(widget.imagePath) && !File(widget.imagePath).existsSync()) {
        final data = await rootBundle.load(widget.imagePath);
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } else {
        final f = File(widget.imagePath);
        if (!f.existsSync()) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = 'Source image not found';
          });
          return;
        }
        bytes = f.readAsBytesSync();
      }

      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final baked = img.bakeOrientation(decoded);
        if (!mounted) return;
        setState(() {
          _srcWidth = baked.width.toDouble();
          _srcHeight = baked.height.toDouble();
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to decode image';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading image: $e';
      });
    }
  }

  void _clampPan() {
    if (_srcWidth == null || _srcHeight == null || _srcWidth! <= 0 || _srcHeight! <= 0) return;
    final baseScale = math.max(_viewportSize / _srcWidth!, _viewportSize / _srcHeight!);
    final effScale = baseScale * _zoom;
    final dispW = _srcWidth! * effScale;
    final dispH = _srcHeight! * effScale;

    final maxPanX = math.max(0.0, (dispW - _viewportSize) / 2.0);
    final maxPanY = math.max(0.0, (dispH - _viewportSize) / 2.0);

    final clampedX = _pan.dx.clamp(-maxPanX, maxPanX);
    final clampedY = _pan.dy.clamp(-maxPanY, maxPanY);

    _pan = Offset(clampedX, clampedY);
  }

  void _updateZoom(double newZoom) {
    setState(() {
      _zoom = newZoom.clamp(_minZoom, _maxZoom);
      _clampPan();
    });
  }

  void _stepZoom(double delta) {
    _updateZoom(_zoom + delta);
  }

  void _reset() {
    setState(() {
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  Future<void> _handleUsePhoto() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final croppedFile = await ImageCropHelper.cropSquare(
        sourcePath: widget.imagePath,
        zoom: _zoom,
        panX: _pan.dx,
        panY: _pan.dy,
        viewportSize: _viewportSize,
        targetDimension: widget.targetDimension,
      );

      if (!mounted) return;
      Navigator.of(context).pop(croppedFile.path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to crop image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(colorScheme, isDark),
              const SizedBox(height: 14),
              _buildInfoBanner(colorScheme, isDark),
              const SizedBox(height: 16),
              _buildCropViewport(isDark),
              const SizedBox(height: 12),
              _buildBadge(colorScheme),
              const SizedBox(height: 14),
              _buildZoomControls(colorScheme, isDark),
              const SizedBox(height: 10),
              _buildResetButton(colorScheme),
              const SizedBox(height: 16),
              _buildFooterActions(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.crop_rounded,
            color: Color(0xFF0284C7),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop & Zoom',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Drag to position • Pinch to zoom',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(null),
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
          tooltip: 'Cancel',
        ),
      ],
    );
  }

  Widget _buildInfoBanner(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFFBAE6FD),
          ),
          const Expanded(
            child: Text(
              'For Gallery and Camera still photos ONLY\n(not GIF or video).',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropViewport(bool isDark) {
    if (_isLoading) {
      return Container(
        height: _viewportSize,
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: Colors.white54,
          size: 40,
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: _viewportSize,
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    final srcW = _srcWidth ?? _viewportSize;
    final srcH = _srcHeight ?? _viewportSize;
    final baseScale = math.max(_viewportSize / srcW, _viewportSize / srcH);
    final effScale = baseScale * _zoom;
    final dispW = srcW * effScale;
    final dispH = srcH * effScale;

    final imgLeft = (_viewportSize - dispW) / 2.0 + _pan.dx;
    final imgTop = (_viewportSize - dispH) / 2.0 + _pan.dy;

    return Center(
      child: GestureDetector(
        onScaleStart: (details) {
          _baseZoom = _zoom;
          _basePan = _pan;
        },
        onScaleUpdate: (details) {
          setState(() {
            _zoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
            _pan = _basePan + details.focalPointDelta;
            _clampPan();
          });
        },
        child: Container(
          width: _viewportSize,
          height: _viewportSize,
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Scaled and panned image
              Positioned(
                left: imgLeft,
                top: imgTop,
                width: dispW,
                height: dispH,
                child: isAssetImagePath(widget.imagePath) && !File(widget.imagePath).existsSync()
                    ? Image.asset(
                        widget.imagePath,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      )
                    : Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      ),
              ),
              // Corner brackets and 3x3 alignment grid overlay
              const Positioned.fill(
                child: CustomPaint(
                  painter: _CropOverlayPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(ColorScheme colorScheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '1:1 Card Image',
          style: TextStyle(
            color: Color(0xFF0369A1),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls(ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Material(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _zoom > _minZoom ? () => _stepZoom(-0.1) : null,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.remove_rounded,
                size: 20,
                color: _zoom > _minZoom
                    ? (isDark ? Colors.white : const Color(0xFF1E293B))
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: const Color(0xFF0284C7),
              inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF0284C7),
              overlayColor: const Color(0xFF0284C7).withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _zoom,
              min: _minZoom,
              max: _maxZoom,
              onChanged: _updateZoom,
            ),
          ),
        ),
        Material(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _zoom < _maxZoom ? () => _stepZoom(0.1) : null,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: _zoom < _maxZoom
                    ? (isDark ? Colors.white : const Color(0xFF1E293B))
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            '${_zoom.toStringAsFixed(1)}×',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(ColorScheme colorScheme) {
    return Center(
      child: TextButton.icon(
        onPressed: (_zoom != 1.0 || _pan != Offset.zero) ? _reset : null,
        icon: const Icon(Icons.restart_alt_rounded, size: 18),
        label: const Text(
          'Reset',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0284C7),
          disabledForegroundColor: Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildFooterActions(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(null),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton(
            onPressed: (_isLoading || _isProcessing || _errorMessage != null)
                ? null
                : _handleUsePhoto,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Use Photo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the 3x3 alignment grid and corner bracket markers.
class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 16.0;
    final rect = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    // 1. Subtle 3x3 rule-of-thirds grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final stepX = rect.width / 3.0;
    final stepY = rect.height / 3.0;

    canvas.drawLine(
      Offset(rect.left + stepX, rect.top),
      Offset(rect.left + stepX, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left + stepX * 2, rect.top),
      Offset(rect.left + stepX * 2, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + stepY),
      Offset(rect.right, rect.top + stepY),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + stepY * 2),
      Offset(rect.right, rect.top + stepY * 2),
      gridPaint,
    );

    // 2. Thick rounded white corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const cornerArm = 22.0;
    const cornerRadius = 6.0;

    // Top-Left
    final pathTL = Path()
      ..moveTo(rect.left, rect.top + cornerArm)
      ..lineTo(rect.left, rect.top + cornerRadius)
      ..arcToPoint(
        Offset(rect.left + cornerRadius, rect.top),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(rect.left + cornerArm, rect.top);
    canvas.drawPath(pathTL, cornerPaint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(rect.right - cornerArm, rect.top)
      ..lineTo(rect.right - cornerRadius, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(rect.right, rect.top + cornerArm);
    canvas.drawPath(pathTR, cornerPaint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(rect.left, rect.bottom - cornerArm)
      ..lineTo(rect.left, rect.bottom - cornerRadius)
      ..arcToPoint(
        Offset(rect.left + cornerRadius, rect.bottom),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(rect.left + cornerArm, rect.bottom);
    canvas.drawPath(pathBL, cornerPaint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(rect.right - cornerArm, rect.bottom)
      ..lineTo(rect.right - cornerRadius, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(rect.right, rect.bottom - cornerArm);
    canvas.drawPath(pathBR, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
