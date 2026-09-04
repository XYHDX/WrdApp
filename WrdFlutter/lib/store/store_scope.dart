import 'package:flutter/widgets.dart';

import 'wrd_store.dart';

/// Makes the store available down the tree; dependents rebuild on change.
class StoreScope extends InheritedNotifier<WrdStore> {
  const StoreScope({super.key, required WrdStore store, required super.child})
      : super(notifier: store);

  static WrdStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope missing above this widget');
    return scope!.notifier!;
  }

  /// Read without subscribing (for callbacks).
  static WrdStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<StoreScope>();
    return scope!.notifier!;
  }
}
