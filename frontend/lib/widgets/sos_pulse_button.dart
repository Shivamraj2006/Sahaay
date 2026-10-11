import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SosPulseButton extends StatefulWidget {
  final VoidCallback onTap;

  const SosPulseButton({super.key, required this.onTap});

  @override
  State<SosPulseButton> createState() => _SosPulseButtonState();
}

class _SosPulseButtonState extends State<SosPulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Concentric Pulse Ring 1 (280px)
            Transform.scale(
              scale: _scaleAnimation.value * 1.15,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandRed.withOpacity(
                    0.08 * _glowAnimation.value,
                  ),
                ),
              ),
            ),
            // Inner Concentric Pulse Ring 2 (230px)
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandRed.withOpacity(
                    0.16 * _glowAnimation.value,
                  ),
                ),
              ),
            ),
            // The Interactive Main SOS Button (180px)
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 175,
                height: 175,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.brandRedDark, AppColors.brandRed],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandRed.withOpacity(0.35),
                      blurRadius: 36,
                      spreadRadius: 6,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rotated Phone Alert Icon
                    Transform(
                      transform: Matrix4.rotationZ(-0.25),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap for emergency',
                      style: TextStyle(
                        color: AppColors.brandRedSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
