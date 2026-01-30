import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animated face scanner overlay for face detection screens
class FaceScannerOverlay extends StatefulWidget {
  final double size;
  final bool isScanning;
  final bool isSuccess;
  final bool isError;

  const FaceScannerOverlay({
    super.key,
    this.size = 280,
    this.isScanning = false,
    this.isSuccess = false,
    this.isError = false,
  });

  @override
  State<FaceScannerOverlay> createState() => _FaceScannerOverlayState();
}

class _FaceScannerOverlayState extends State<FaceScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FaceScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (widget.isSuccess) return AppColors.success;
    if (widget.isError) return AppColors.error;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Corner markers
          _buildCornerMarker(Alignment.topLeft),
          _buildCornerMarker(Alignment.topRight),
          _buildCornerMarker(Alignment.bottomLeft),
          _buildCornerMarker(Alignment.bottomRight),
          
          // Scan line
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned(
                  top: _scanAnimation.value * (widget.size - 4),
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _borderColor,
                          _borderColor,
                          Colors.transparent,
                        ],
                        stops: const [0, 0.2, 0.8, 1],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker(Alignment alignment) {
    const cornerSize = 40.0;
    const thickness = 4.0;

    BorderRadius borderRadius;
    double? top, bottom, left, right;

    switch (alignment) {
      case Alignment.topLeft:
        top = 0;
        left = 0;
        borderRadius = const BorderRadius.only(topLeft: Radius.circular(16));
        break;
      case Alignment.topRight:
        top = 0;
        right = 0;
        borderRadius = const BorderRadius.only(topRight: Radius.circular(16));
        break;
      case Alignment.bottomLeft:
        bottom = 0;
        left = 0;
        borderRadius = const BorderRadius.only(bottomLeft: Radius.circular(16));
        break;
      case Alignment.bottomRight:
      default:
        bottom = 0;
        right = 0;
        borderRadius = const BorderRadius.only(bottomRight: Radius.circular(16));
        break;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: cornerSize,
        height: cornerSize,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border(
            top: top != null
                ? BorderSide(color: _borderColor, width: thickness)
                : BorderSide.none,
            bottom: bottom != null
                ? BorderSide(color: _borderColor, width: thickness)
                : BorderSide.none,
            left: left != null
                ? BorderSide(color: _borderColor, width: thickness)
                : BorderSide.none,
            right: right != null
                ? BorderSide(color: _borderColor, width: thickness)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
