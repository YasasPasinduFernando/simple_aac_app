import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../utils/card_image.dart';
import '../utils/image_crop_helper.dart';

enum CropMode {
  square1x1,
  free,
}

enum _DragHandle {
  none,
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  insideCropRect,
  panImage,
  pinchZoom,
}

/// Modal dialog providing interactive Crop & Zoom for card images.
/// Features:
/// - Interactive adjustable crop rectangle with 4 corner & 4 edge handles
/// - 1:1 Card square crop and Free Crop modes
/// - Live rule-of-thirds grid and dimmed non-crop overlay
/// - Touch-friendly: Two-finger pinch-to-zoom, single-finger pan and handle resizing
/// - Precision zoom slider (1.0x to 3.5x) with minus/plus step buttons
/// - Non-destructive editing with Reset, Cancel, and Use Photo commitments
/// - High-performance background isolate decoding and cropping
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

  CropMode _cropMode = CropMode.square1x1;
  Rect? _cropRect;
  _DragHandle _activeDragHandle = _DragHandle.none;

  double? _srcWidth;
  double? _srcHeight;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  static const double _minZoom = 1.0;
  static const double _maxZoom = 3.5;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    try {
      final dims = await ImageCropHelper.decodeDimensions(widget.imagePath);
      if (!mounted) return;
      setState(() {
        _srcWidth = dims.width;
        _srcHeight = dims.height;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading image: $e';
      });
    }
  }

  Rect _calculateImageRect(double viewportWidth, double viewportHeight) {
    if (_srcWidth == null || _srcHeight == null || _srcWidth! <= 0 || _srcHeight! <= 0) {
      return Rect.fromLTWH(0, 0, viewportWidth, viewportHeight);
    }
    final fitScale = math.min(viewportWidth / _srcWidth!, viewportHeight / _srcHeight!);
    final effectiveScale = fitScale * _zoom;
    final dispW = _srcWidth! * effectiveScale;
    final dispH = _srcHeight! * effectiveScale;

    final left = (viewportWidth - dispW) / 2.0 + _pan.dx;
    final top = (viewportHeight - dispH) / 2.0 + _pan.dy;
    return Rect.fromLTWH(left, top, dispW, dispH);
  }

  void _initCropRectIfNeeded(double viewportWidth, double viewportHeight) {
    if (_cropRect != null || _srcWidth == null || _srcHeight == null) return;
    final imageRect = _calculateImageRect(viewportWidth, viewportHeight);
    if (_cropMode == CropMode.square1x1) {
      final size = math.min(imageRect.width, imageRect.height) * 0.90;
      _cropRect = Rect.fromCenter(
        center: imageRect.center,
        width: size,
        height: size,
      );
    } else {
      _cropRect = Rect.fromCenter(
        center: imageRect.center,
        width: imageRect.width * 0.90,
        height: imageRect.height * 0.90,
      );
    }
  }

  void _clampPan(double viewportWidth, double viewportHeight) {
    if (_srcWidth == null || _srcHeight == null) return;
    final fitScale = math.min(viewportWidth / _srcWidth!, viewportHeight / _srcHeight!);
    final effScale = fitScale * _zoom;
    final dispW = _srcWidth! * effScale;
    final dispH = _srcHeight! * effScale;

    final maxPanX = math.max(0.0, (dispW - viewportWidth) / 2.0 + 40.0);
    final maxPanY = math.max(0.0, (dispH - viewportHeight) / 2.0 + 40.0);

    _pan = Offset(
      _pan.dx.clamp(-maxPanX, maxPanX),
      _pan.dy.clamp(-maxPanY, maxPanY),
    );
  }

  void _clampCropRectToImage(double viewportWidth, double viewportHeight) {
    if (_cropRect == null) return;
    final imageRect = _calculateImageRect(viewportWidth, viewportHeight);
    const minSize = 44.0;

    double w = _cropRect!.width;
    double h = _cropRect!.height;

    if (_cropMode == CropMode.square1x1) {
      final maxAllowed = math.min(imageRect.width, imageRect.height);
      if (w > maxAllowed || h > maxAllowed) {
        w = maxAllowed;
        h = maxAllowed;
      }
      w = math.max(minSize, w);
      h = w;
    } else {
      if (w > imageRect.width) w = imageRect.width;
      if (h > imageRect.height) h = imageRect.height;
      w = math.max(minSize, w);
      h = math.max(minSize, h);
    }

    double l = _cropRect!.left;
    double t = _cropRect!.top;

    if (l < imageRect.left) l = imageRect.left;
    if (l + w > imageRect.right) l = imageRect.right - w;
    if (t < imageRect.top) t = imageRect.top;
    if (t + h > imageRect.bottom) t = imageRect.bottom - h;

    _cropRect = Rect.fromLTWH(l, t, w, h);
  }

  void _snapCropRectToSquare(double viewportWidth, double viewportHeight) {
    if (_cropRect == null) return;
    final imageRect = _calculateImageRect(viewportWidth, viewportHeight);
    final center = _cropRect!.center;
    final maxAllowed = math.min(imageRect.width, imageRect.height);
    final size = math.min(math.min(_cropRect!.width, _cropRect!.height), maxAllowed);
    final half = size / 2.0;

    double l = center.dx - half;
    double t = center.dy - half;
    if (l < imageRect.left) l = imageRect.left;
    if (l + size > imageRect.right) l = imageRect.right - size;
    if (t < imageRect.top) t = imageRect.top;
    if (t + size > imageRect.bottom) t = imageRect.bottom - size;
    _cropRect = Rect.fromLTWH(l, t, size, size);
  }

  void _handleDragStart(Offset localPos, double viewportWidth, double viewportHeight, int pointerCount) {
    if (pointerCount >= 2) {
      _activeDragHandle = _DragHandle.pinchZoom;
      _baseZoom = _zoom;
      _basePan = _pan;
      return;
    }

    if (_cropRect == null) return;

    final l = _cropRect!.left;
    final t = _cropRect!.top;
    final r = _cropRect!.right;
    final b = _cropRect!.bottom;
    final cx = _cropRect!.center.dx;
    final cy = _cropRect!.center.dy;

    const hitRadius = 32.0;

    if ((localPos - Offset(l, t)).distance <= hitRadius) {
      _activeDragHandle = _DragHandle.topLeft;
    } else if ((localPos - Offset(r, t)).distance <= hitRadius) {
      _activeDragHandle = _DragHandle.topRight;
    } else if ((localPos - Offset(l, b)).distance <= hitRadius) {
      _activeDragHandle = _DragHandle.bottomLeft;
    } else if ((localPos - Offset(r, b)).distance <= hitRadius) {
      _activeDragHandle = _DragHandle.bottomRight;
    } else if ((localPos - Offset(cx, t)).distance <= hitRadius) {
      _activeDragHandle = _DragHandle.topCenter;
    } else if ((localPos - Offset(cx, b)).distance <= hitRadius) {
      _activeDragHandle = _DragHandle.bottomCenter;
    } else if ((localPos - Offset(l, cy)).distance <= hitRadius) {
      _activeDragHandle = _DragHandle.centerLeft;
    } else if ((localPos - Offset(r, cy)).distance <= hitRadius) {
      _activeDragHandle = _DragHandle.centerRight;
    } else if (_cropRect!.contains(localPos)) {
      _activeDragHandle = _DragHandle.insideCropRect;
    } else {
      _activeDragHandle = _DragHandle.panImage;
      _basePan = _pan;
    }
  }

  void _handleDragUpdate(ScaleUpdateDetails details, double viewportWidth, double viewportHeight) {
    if (details.pointerCount >= 2 || _activeDragHandle == _DragHandle.pinchZoom) {
      setState(() {
        _zoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
        _pan = _basePan + details.focalPointDelta;
        _clampPan(viewportWidth, viewportHeight);
        _clampCropRectToImage(viewportWidth, viewportHeight);
      });
      return;
    }

    if (_cropRect == null) return;
    final imageRect = _calculateImageRect(viewportWidth, viewportHeight);
    final delta = details.focalPointDelta;
    const minSize = 44.0;

    setState(() {
      double l = _cropRect!.left;
      double t = _cropRect!.top;
      double r = _cropRect!.right;
      double b = _cropRect!.bottom;

      if (_activeDragHandle == _DragHandle.insideCropRect) {
        double newL = l + delta.dx;
        double newT = t + delta.dy;
        if (newL < imageRect.left) newL = imageRect.left;
        if (newL + _cropRect!.width > imageRect.right) newL = imageRect.right - _cropRect!.width;
        if (newT < imageRect.top) newT = imageRect.top;
        if (newT + _cropRect!.height > imageRect.bottom) newT = imageRect.bottom - _cropRect!.height;
        _cropRect = Rect.fromLTWH(newL, newT, _cropRect!.width, _cropRect!.height);
        return;
      }

      if (_activeDragHandle == _DragHandle.panImage) {
        _pan += delta;
        _clampPan(viewportWidth, viewportHeight);
        _clampCropRectToImage(viewportWidth, viewportHeight);
        return;
      }

      if (_cropMode == CropMode.free) {
        switch (_activeDragHandle) {
          case _DragHandle.topLeft:
            l = (l + delta.dx).clamp(imageRect.left, r - minSize);
            t = (t + delta.dy).clamp(imageRect.top, b - minSize);
            break;
          case _DragHandle.topCenter:
            t = (t + delta.dy).clamp(imageRect.top, b - minSize);
            break;
          case _DragHandle.topRight:
            r = (r + delta.dx).clamp(l + minSize, imageRect.right);
            t = (t + delta.dy).clamp(imageRect.top, b - minSize);
            break;
          case _DragHandle.centerLeft:
            l = (l + delta.dx).clamp(imageRect.left, r - minSize);
            break;
          case _DragHandle.centerRight:
            r = (r + delta.dx).clamp(l + minSize, imageRect.right);
            break;
          case _DragHandle.bottomLeft:
            l = (l + delta.dx).clamp(imageRect.left, r - minSize);
            b = (b + delta.dy).clamp(t + minSize, imageRect.bottom);
            break;
          case _DragHandle.bottomCenter:
            b = (b + delta.dy).clamp(t + minSize, imageRect.bottom);
            break;
          case _DragHandle.bottomRight:
            r = (r + delta.dx).clamp(l + minSize, imageRect.right);
            b = (b + delta.dy).clamp(t + minSize, imageRect.bottom);
            break;
          default:
            break;
        }
        _cropRect = Rect.fromLTRB(l, t, r, b);
      } else {
        // 1:1 Card Mode: preserve square aspect ratio
        switch (_activeDragHandle) {
          case _DragHandle.bottomRight: {
            final d = (delta.dx + delta.dy) / 2.0;
            final maxW = imageRect.right - l;
            final maxH = imageRect.bottom - t;
            final maxS = math.min(maxW, maxH);
            final newSize = (_cropRect!.width + d).clamp(minSize, maxS);
            _cropRect = Rect.fromLTWH(l, t, newSize, newSize);
            break;
          }
          case _DragHandle.topLeft: {
            final d = (-delta.dx - delta.dy) / 2.0;
            final maxW = r - imageRect.left;
            final maxH = b - imageRect.top;
            final maxS = math.min(maxW, maxH);
            final newSize = (_cropRect!.width + d).clamp(minSize, maxS);
            _cropRect = Rect.fromLTWH(r - newSize, b - newSize, newSize, newSize);
            break;
          }
          case _DragHandle.bottomLeft: {
            final d = (-delta.dx + delta.dy) / 2.0;
            final maxW = r - imageRect.left;
            final maxH = imageRect.bottom - t;
            final maxS = math.min(maxW, maxH);
            final newSize = (_cropRect!.width + d).clamp(minSize, maxS);
            _cropRect = Rect.fromLTWH(r - newSize, t, newSize, newSize);
            break;
          }
          case _DragHandle.topRight: {
            final d = (delta.dx - delta.dy) / 2.0;
            final maxW = imageRect.right - l;
            final maxH = b - imageRect.top;
            final maxS = math.min(maxW, maxH);
            final newSize = (_cropRect!.width + d).clamp(minSize, maxS);
            _cropRect = Rect.fromLTWH(l, b - newSize, newSize, newSize);
            break;
          }
          case _DragHandle.topCenter: {
            final d = -delta.dy;
            final maxH = b - imageRect.top;
            final newSize = (_cropRect!.width + d).clamp(minSize, maxH);
            final dHalf = (newSize - _cropRect!.width) / 2.0;
            double newL = l - dHalf;
            if (newL < imageRect.left) newL = imageRect.left;
            if (newL + newSize > imageRect.right) newL = imageRect.right - newSize;
            _cropRect = Rect.fromLTWH(newL, b - newSize, newSize, newSize);
            break;
          }
          case _DragHandle.bottomCenter: {
            final d = delta.dy;
            final maxH = imageRect.bottom - t;
            final newSize = (_cropRect!.width + d).clamp(minSize, maxH);
            final dHalf = (newSize - _cropRect!.width) / 2.0;
            double newL = l - dHalf;
            if (newL < imageRect.left) newL = imageRect.left;
            if (newL + newSize > imageRect.right) newL = imageRect.right - newSize;
            _cropRect = Rect.fromLTWH(newL, t, newSize, newSize);
            break;
          }
          case _DragHandle.centerLeft: {
            final d = -delta.dx;
            final maxW = r - imageRect.left;
            final newSize = (_cropRect!.width + d).clamp(minSize, maxW);
            final dHalf = (newSize - _cropRect!.height) / 2.0;
            double newT = t - dHalf;
            if (newT < imageRect.top) newT = imageRect.top;
            if (newT + newSize > imageRect.bottom) newT = imageRect.bottom - newSize;
            _cropRect = Rect.fromLTWH(r - newSize, newT, newSize, newSize);
            break;
          }
          case _DragHandle.centerRight: {
            final d = delta.dx;
            final maxW = imageRect.right - l;
            final newSize = (_cropRect!.width + d).clamp(minSize, maxW);
            final dHalf = (newSize - _cropRect!.height) / 2.0;
            double newT = t - dHalf;
            if (newT < imageRect.top) newT = imageRect.top;
            if (newT + newSize > imageRect.bottom) newT = imageRect.bottom - newSize;
            _cropRect = Rect.fromLTWH(l, newT, newSize, newSize);
            break;
          }
          default:
            break;
        }
      }
    });
  }

  void _updateZoom(double newZoom, double viewportWidth, double viewportHeight) {
    setState(() {
      _zoom = newZoom.clamp(_minZoom, _maxZoom);
      _clampPan(viewportWidth, viewportHeight);
      _clampCropRectToImage(viewportWidth, viewportHeight);
    });
  }

  void _reset(double viewportWidth, double viewportHeight) {
    setState(() {
      _zoom = 1.0;
      _pan = Offset.zero;
      _cropMode = CropMode.square1x1;
      _cropRect = null;
      _initCropRectIfNeeded(viewportWidth, viewportHeight);
    });
  }

  Future<void> _handleUsePhoto(double viewportWidth, double viewportHeight) async {
    if (_isProcessing || _cropRect == null) return;
    setState(() => _isProcessing = true);

    try {
      final imageRect = _calculateImageRect(viewportWidth, viewportHeight);

      final normLeft = ((_cropRect!.left - imageRect.left) / imageRect.width).clamp(0.0, 1.0);
      final normTop = ((_cropRect!.top - imageRect.top) / imageRect.height).clamp(0.0, 1.0);
      final normWidth = (_cropRect!.width / imageRect.width).clamp(0.001, 1.0 - normLeft);
      final normHeight = (_cropRect!.height / imageRect.height).clamp(0.001, 1.0 - normTop);

      final croppedFile = await ImageCropHelper.cropNormalized(
        sourcePath: widget.imagePath,
        normLeft: normLeft,
        normTop: normTop,
        normWidth: normWidth,
        normHeight: normHeight,
        isSquare: _cropMode == CropMode.square1x1,
        targetDimension: widget.targetDimension,
      );

      PaintingBinding.instance.imageCache.evict(FileImage(File(widget.imagePath)));
      PaintingBinding.instance.imageCache.evict(FileImage(croppedFile));

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
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final dialogWidth = math.min(mediaQuery.size.width - 32, 420.0);
    final viewportWidth = dialogWidth - 40.0;
    final viewportHeight = isLandscape ? 190.0 : 260.0;

    _initCropRectIfNeeded(viewportWidth, viewportHeight);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(colorScheme, isDark),
              const SizedBox(height: 12),
              _buildInfoBanner(colorScheme, isDark),
              const SizedBox(height: 14),
              _buildCropViewport(viewportWidth, viewportHeight, isDark),
              const SizedBox(height: 12),
              _buildModeToggle(viewportWidth, viewportHeight, isDark),
              const SizedBox(height: 12),
              _buildZoomControls(viewportWidth, viewportHeight, colorScheme, isDark),
              const SizedBox(height: 6),
              _buildResetButton(viewportWidth, viewportHeight, colorScheme),
              const SizedBox(height: 14),
              _buildFooterActions(viewportWidth, viewportHeight, colorScheme),
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
                'Pinch to zoom • Drag image or crop handles',
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
          color: const Color(0xFFBAE6FD).withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withOpacity(0.12),
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
              'Gallery and Camera photos only\n(not GIF or video)',
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

  Widget _buildCropViewport(double viewportWidth, double viewportHeight, bool isDark) {
    if (_isLoading) {
      return Container(
        width: viewportWidth,
        height: viewportHeight,
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
        width: viewportWidth,
        height: viewportHeight,
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

    final imageRect = _calculateImageRect(viewportWidth, viewportHeight);

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          _handleDragStart(
            details.localFocalPoint,
            viewportWidth,
            viewportHeight,
            details.pointerCount,
          );
        },
        onScaleUpdate: (details) {
          _handleDragUpdate(details, viewportWidth, viewportHeight);
        },
        onScaleEnd: (_) {
          setState(() {
            _activeDragHandle = _DragHandle.none;
          });
        },
        child: Container(
          width: viewportWidth,
          height: viewportHeight,
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
              // 1. Render scaled and panned image
              Positioned(
                left: imageRect.left,
                top: imageRect.top,
                width: imageRect.width,
                height: imageRect.height,
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
              // 2. Dimmed overlay, rule-of-thirds grid, and 8 circular handles
              if (_cropRect != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CropOverlayPainter(
                      cropRect: _cropRect!,
                      viewportRect: Rect.fromLTWH(0, 0, viewportWidth, viewportHeight),
                      isInteracting: _activeDragHandle != _DragHandle.none,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(double viewportWidth, double viewportHeight, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: '1:1 Card',
              isSelected: _cropMode == CropMode.square1x1,
              onTap: () {
                if (_cropMode != CropMode.square1x1) {
                  setState(() {
                    _cropMode = CropMode.square1x1;
                    _snapCropRectToSquare(viewportWidth, viewportHeight);
                  });
                }
              },
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildModeButton(
              label: 'Free Crop',
              isSelected: _cropMode == CropMode.free,
              onTap: () {
                if (_cropMode != CropMode.free) {
                  setState(() {
                    _cropMode = CropMode.free;
                  });
                }
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls(double viewportWidth, double viewportHeight, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Material(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _zoom > _minZoom
                ? () => _updateZoom(_zoom - 0.1, viewportWidth, viewportHeight)
                : null,
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
              overlayColor: const Color(0xFF0284C7).withOpacity(0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _zoom,
              min: _minZoom,
              max: _maxZoom,
              onChanged: (v) => _updateZoom(v, viewportWidth, viewportHeight),
            ),
          ),
        ),
        Material(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _zoom < _maxZoom
                ? () => _updateZoom(_zoom + 0.1, viewportWidth, viewportHeight)
                : null,
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

  Widget _buildResetButton(double viewportWidth, double viewportHeight, ColorScheme colorScheme) {
    final canReset = _zoom != 1.0 || _pan != Offset.zero || _cropMode != CropMode.square1x1;
    return Center(
      child: TextButton.icon(
        onPressed: canReset ? () => _reset(viewportWidth, viewportHeight) : null,
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

  Widget _buildFooterActions(double viewportWidth, double viewportHeight, ColorScheme colorScheme) {
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
                : () => _handleUsePhoto(viewportWidth, viewportHeight),
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

/// Custom painter for rule-of-thirds grid, dimmed outer overlay, and 8 circular handles.
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Rect viewportRect;
  final bool isInteracting;

  const _CropOverlayPainter({
    required this.cropRect,
    required this.viewportRect,
    required this.isInteracting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dimmed area outside the crop rectangle
    final bgPath = Path()..addRect(viewportRect);
    final cropPath = Path()..addRect(cropRect);
    final dimmedPath = Path.combine(PathOperation.difference, bgPath, cropPath);
    final dimmedPaint = Paint()..color = Colors.black.withOpacity(0.55);
    canvas.drawPath(dimmedPath, dimmedPaint);

    // 2. Crop rectangle boundary outline
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(cropRect, borderPaint);

    // 3. Rule of thirds 3x3 grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(isInteracting ? 0.60 : 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final stepX = cropRect.width / 3.0;
    final stepY = cropRect.height / 3.0;

    canvas.drawLine(
      Offset(cropRect.left + stepX, cropRect.top),
      Offset(cropRect.left + stepX, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + stepX * 2, cropRect.top),
      Offset(cropRect.left + stepX * 2, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + stepY),
      Offset(cropRect.right, cropRect.top + stepY),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + stepY * 2),
      Offset(cropRect.right, cropRect.top + stepY * 2),
      gridPaint,
    );

    // 4. Draw 8 circular handles (4 corners + 4 edge midpoints)
    final handleFill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const radius = 6.5;

    final handles = [
      // 4 corners
      Offset(cropRect.left, cropRect.top),
      Offset(cropRect.right, cropRect.top),
      Offset(cropRect.left, cropRect.bottom),
      Offset(cropRect.right, cropRect.bottom),
      // 4 edge midpoints
      Offset(cropRect.center.dx, cropRect.top),
      Offset(cropRect.center.dx, cropRect.bottom),
      Offset(cropRect.left, cropRect.center.dy),
      Offset(cropRect.right, cropRect.center.dy),
    ];

    for (final pos in handles) {
      canvas.drawCircle(pos, radius, handleFill);
      canvas.drawCircle(pos, radius, handleBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.viewportRect != viewportRect ||
        oldDelegate.isInteracting != isInteracting;
  }
}
