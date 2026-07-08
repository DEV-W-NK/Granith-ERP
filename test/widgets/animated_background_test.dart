import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/widgets/animations/animation_background.dart';

void main() {
  testWidgets('AnimatedBackground renderiza pintura ambiente animada', (
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

    expect(
      find.descendant(
        of: find.byType(AnimatedBackground),
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter != null,
        ),
      ),
      findsOneWidget,
    );

    controller.dispose();
  });
}
