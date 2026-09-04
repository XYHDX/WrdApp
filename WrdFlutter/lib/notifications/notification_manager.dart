import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../prayer/prayer_calculator.dart';
import '../store/wrd_store.dart';
import '../util/arabic.dart';

/// The reminder engine — anchored to real, on-device prayer times for the
/// user's country. Calm by design: one call per prayer, gate reminders after
/// Fajr and ʿIshāʼ, scheduled two days ahead and refreshed whenever the app
/// opens. Everything is a local one-shot (no repeating rules), so DST and
/// method changes are always picked up on the next refresh.
class NotificationManager {
  NotificationManager._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'wrd.reminders';
  static const _channelName = 'تذكير الأوراد';

  static Future<void> initialize() async {
    if (_initialized) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    await initialize();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    return true;
  }

  static Future<void> reschedule(WrdStore store) async {
    try {
      await initialize();
      await _plugin.cancelAll();
      if (!store.remindersEnabled) return;

      final now = DateTime.now();
      final place = store.placeLabel;

      for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
        final day = DateTime(now.year, now.month, now.day + dayOffset);
        final prayers = store.prayersFor(day);

        // The call at each prayer — الأذان كتنبيه
        if (store.adhanEnabled) {
          for (final prayer in PrayerName.prayersOnly) {
            final time = prayers.time(prayer);
            if (time == null || !time.isAfter(now)) continue;
            await _schedule(
              id: 'wrd.adhan.${prayer.name}.$dayOffset',
              at: time,
              title: 'حان وقتُ صلاة ${prayer.arabicName} 🕌',
              body: '${timeString(time)} في $place — ولا تنسَ وِردَ ما بعد الصلاة',
            );
          }
        }

        // Gate reminders anchored to the day's real times
        final fajr = prayers.time(PrayerName.fajr);
        if (fajr != null) {
          final time = fajr.add(const Duration(minutes: 20));
          if (time.isAfter(now)) {
            await _schedule(
              id: 'wrd.morning.$dayOffset',
              at: time,
              title: 'وِردُ الصباح ينتظرك',
              body: 'أذكار الصباح ووِردك من القرآن — أضِئ يومك',
            );
          }
        }
        final isha = prayers.time(PrayerName.isha);
        if (isha != null) {
          final time = isha.add(const Duration(minutes: 30));
          if (time.isAfter(now)) {
            await _schedule(
              id: 'wrd.night.$dayOffset',
              at: time,
              title: 'أنِر ليلتك بوِردك',
              body: 'أذكار النوم وسورة الملك من مصحفك',
            );
          }
        }

        // Per-wird reminders at the user's chosen time (today and tomorrow).
        for (final wird in store.awrad) {
          final minutes = wird.reminderMinutes;
          if (minutes == null) continue;
          final time = day.add(Duration(minutes: minutes));
          if (!time.isAfter(now)) continue;
          await _schedule(
            id: 'wrd.wird.${wird.id}.$dayOffset',
            at: time,
            title: 'وِردك: ${wird.title}',
            body: 'حان الموعدُ الذي اخترتَه — أضِئ وِردك',
          );
        }
      }
    } catch (error) {
      debugPrint('WRD: notifications unavailable — $error');
    }
  }

  static Future<void> _schedule({
    required String id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    // Schedule at the absolute instant (expressed in UTC) — no dependence on
    // resolving the device's IANA zone name.
    final when = tz.TZDateTime.from(at.toUtc(), tz.UTC);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'الأذان وتذكير الأوراد بمواقيت بلدك',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    if (!at.isAfter(DateTime.now())) return; // slipped into the past meanwhile
    final notificationId = _intId(id);
    try {
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Exact alarms may be disallowed on newer Android — fall back to inexact.
      // One failed notification must never cancel the rest of the schedule.
      try {
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (error) {
        debugPrint('WRD: could not schedule $id — $error');
      }
    }
  }

  /// Stable 31-bit id from a string key (FNV-1a).
  static int _intId(String key) {
    var hash = 0x811C9DC5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}
