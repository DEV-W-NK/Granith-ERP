import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/ai_assistant_models.dart';

void main() {
  group('AiAssistantArea', () {
    test('mantem isolamento por area conhecida', () {
      expect(
        AiAssistantArea.fromValue('human_resources'),
        AiAssistantArea.humanResources,
      );
      expect(AiAssistantArea.supplies.value, 'supplies');
      expect(AiAssistantArea.administrative.title, 'IA Administrativa');
    });
  });

  group('AiPricingConfig', () {
    test('serializa preco manual por modelo', () {
      final pricing = AiPricingConfig(
        id: '',
        model: 'gemini-2.5-flash',
        inputPerMillionUsd: 0.30,
        outputPerMillionUsd: 2.50,
      );

      final map = pricing.toMap(updatedBy: 'dev@granith.com');

      expect(map['id'], 'gemini-2.5-flash');
      expect(map['model'], 'gemini-2.5-flash');
      expect(map['input_per_million_usd'], 0.30);
      expect(map['output_per_million_usd'], 2.50);
      expect(map['updated_by'], 'dev@granith.com');
    });
  });
}
