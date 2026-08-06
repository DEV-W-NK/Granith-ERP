import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class GranithWordmark extends StatelessWidget {
  const GranithWordmark({
    this.width = 310,
    this.height = 96,
    this.scale = 1.55,
    super.key,
  });

  final double width;
  final double height;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Granith',
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: Align(
            alignment: Alignment.center,
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                'assets/branding/granith_logo_transparent.png',
                width: width,
                height: width,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder:
                    (_, _, _) => const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'GRANITH',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
