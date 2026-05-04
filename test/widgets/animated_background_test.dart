import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/widgets/animations/animation_background.dart';

void main() {
  testWidgets('AnimatedBackground desenha tres fontes de luz ambiente', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    )..value = 0.5;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AnimatedBackground(controller: controller)),
      ),
    );

    expect(find.byType(ImageFiltered), findsNWidgets(3));

    controller.dispose();
  });
}
