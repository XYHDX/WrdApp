import 'package:flutter/material.dart';

import 'app.dart';
import 'notifications/notification_manager.dart';
import 'store/wrd_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await WrdStore.load();
  await NotificationManager.initialize();
  runApp(WrdApp(store: store));
}
