import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/core/data/app_data_refresh_bus.dart';

void main() {
  test('notifica apenas ouvintes de escopos correspondentes', () async {
    final events = <AppDataRefreshEvent>[];
    final subscription = AppDataRefreshBus.instance.listen(const [
      AppDataRefreshBus.projects,
    ], events.add);
    addTearDown(subscription.cancel);

    AppDataRefreshBus.instance.notify(
      scopes: const [AppDataRefreshBus.suppliers],
      source: 'test',
    );
    await pumpEventQueue();

    expect(events, isEmpty);

    AppDataRefreshBus.instance.notify(
      scopes: const [AppDataRefreshBus.projects],
      source: 'test',
    );
    await pumpEventQueue();

    expect(events, hasLength(1));
    expect(events.single.scopes, contains(AppDataRefreshBus.projects));
    expect(events.single.source, 'test');
  });
}
