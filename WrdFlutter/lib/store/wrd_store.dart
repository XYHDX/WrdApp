import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../circles/circle_codec.dart';
import '../data/adhkar_library.dart';
import '../models/day_record.dart';
import '../models/gate.dart';
import '../models/khatma.dart';
import '../models/wird.dart';
import '../prayer/cities.dart';
import '../prayer/location_service.dart';
import '../prayer/prayer_calculator.dart';
import '../prayer/prayer_method.dart';
import '../util/arabic.dart';
import '../util/dates.dart';

/// In-app appearance — the founder's rule: parchment by day, candlelight by
/// night, user in control.
enum WrdTheme {
  auto,
  parchment,
  candlelight;

  String get arabicTitle {
    switch (this) {
      case WrdTheme.auto:
        return 'تلقائي';
      case WrdTheme.parchment:
        return 'المصحف (فاتح)';
      case WrdTheme.candlelight:
        return 'القنديل (داكن)';
    }
  }

  static WrdTheme fromWire(String? v) {
    for (final t in WrdTheme.values) {
      if (t.name == v) return t;
    }
    return WrdTheme.auto;
  }
}

/// The single source of truth: the user's awrād, day records, circles and
/// settings. Persisted as JSON in Application Support (`wrd-state.json` —
/// the same file the Swift app wrote, so an existing install carries over).
class WrdStore extends ChangeNotifier {
  WrdStore._(this._prefs);

  final SharedPreferences _prefs;

  // MARK: State
  List<Wird> awrad = [];
  Map<String, DayRecord> days = {};
  List<KhatmaCircle> circles = [];

  // MARK: Load

  static Future<WrdStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = WrdStore._(prefs);
    await store._loadState();
    store._startDayRollover();
    return store;
  }

  // ---------------------------------------------------------------------------
  // Settings (SharedPreferences-backed) — keys mirror the Swift app's.

  WrdTheme get theme => WrdTheme.fromWire(_prefs.getString('wrd.theme'));
  set theme(WrdTheme v) => _set(() => _prefs.setString('wrd.theme', v.name));

  bool get remindersEnabled => _prefs.getBool('wrd.reminder.enabled') ?? false;
  set remindersEnabled(bool v) => _set(() => _prefs.setBool('wrd.reminder.enabled', v));

  bool get adhanEnabled => _prefs.getBool('wrd.adhan.enabled') ?? true;
  set adhanEnabled(bool v) => _set(() => _prefs.setBool('wrd.adhan.enabled', v));

  String get userName => _prefs.getString('wrd.user.name') ?? '';
  set userName(String v) => _set(() => _prefs.setString('wrd.user.name', v));

  bool get largeText => _prefs.getBool('wrd.largeText') ?? false;
  set largeText(bool v) => _set(() => _prefs.setBool('wrd.largeText', v));

  bool get hasOnboarded => _prefs.getBool('wrd.onboarded') ?? false;
  set hasOnboarded(bool v) => _set(() => _prefs.setBool('wrd.onboarded', v));

  // Location ------------------------------------------------------------------

  /// Manual city (fallback, and the choice when device location is off).
  City get city => City.byName(_prefs.getString('wrd.city'));
  set city(City v) => _set(() => _prefs.setString('wrd.city', v.name));

  bool get useDeviceLocation => _prefs.getBool('wrd.location.auto') ?? false;
  set useDeviceLocation(bool v) => _set(() => _prefs.setBool('wrd.location.auto', v));

  ResolvedLocation? get resolvedLocation {
    final raw = _prefs.getString('wrd.location.resolved');
    if (raw == null) return null;
    try {
      return ResolvedLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  set resolvedLocation(ResolvedLocation? v) => _set(() => v == null
      ? _prefs.remove('wrd.location.resolved')
      : _prefs.setString('wrd.location.resolved', jsonEncode(v.toJson())));

  /// Tries the device location; on success switches to it. Returns the outcome
  /// so the UI can explain a denial. Nothing leaves the device.
  Future<LocationOutcome> refreshDeviceLocation() async {
    final (outcome, location) = await LocationService.resolve();
    if (outcome == LocationOutcome.resolved && location != null) {
      resolvedLocation = location;
      useDeviceLocation = true;
    }
    return outcome;
  }

  /// The coordinate prayer times are computed for.
  (double, double) get coordinates {
    final loc = resolvedLocation;
    if (useDeviceLocation && loc != null) return (loc.latitude, loc.longitude);
    return (city.latitude, city.longitude);
  }

  /// ISO country code in effect (device location first, else the city's).
  String get countryCode {
    final loc = resolvedLocation;
    if (useDeviceLocation && loc?.countryCode != null) return loc!.countryCode!;
    return city.countryCode;
  }

  /// A short Arabic-friendly place label for notifications and settings.
  String get placeLabel {
    final loc = resolvedLocation;
    if (useDeviceLocation && loc != null) {
      return loc.placeName ?? 'موقعك الحالي';
    }
    return city.arabicName;
  }

  // Prayer conventions --------------------------------------------------------

  /// null = automatic by country.
  PrayerMethod? get methodOverride => PrayerMethod.fromWire(_prefs.getString('wrd.prayer.method'));
  set methodOverride(PrayerMethod? v) => _set(() => v == null
      ? _prefs.remove('wrd.prayer.method')
      : _prefs.setString('wrd.prayer.method', v.wire));

  Madhab? get madhabOverride {
    final raw = _prefs.getString('wrd.prayer.madhab');
    return raw == null ? null : Madhab.fromWire(raw);
  }

  set madhabOverride(Madhab? v) => _set(() => v == null
      ? _prefs.remove('wrd.prayer.madhab')
      : _prefs.setString('wrd.prayer.madhab', v.name));

  HighLatitudeRule get highLatitudeRule =>
      HighLatitudeRule.fromWire(_prefs.getString('wrd.prayer.highLat'));
  set highLatitudeRule(HighLatitudeRule v) =>
      _set(() => _prefs.setString('wrd.prayer.highLat', v.name));

  PrayerAdjustments get userAdjustments {
    final raw = _prefs.getString('wrd.prayer.adjustments');
    if (raw == null) return PrayerAdjustments.none;
    try {
      return PrayerAdjustments.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PrayerAdjustments.none;
    }
  }

  set userAdjustments(PrayerAdjustments v) =>
      _set(() => _prefs.setString('wrd.prayer.adjustments', jsonEncode(v.toJson())));

  PrayerMethod get effectiveMethod => methodOverride ?? PrayerMethod.forCountry(countryCode);
  Madhab get effectiveMadhab => madhabOverride ?? PrayerMethod.madhabForCountry(countryCode);

  PrayerSettings prayerSettings([DateTime? date]) => PrayerSettings(
        method: effectiveMethod,
        madhab: effectiveMadhab,
        highLatitudeRule: highLatitudeRule,
        userAdjustments: userAdjustments,
        isRamadan: HijriDate.isRamadan(date),
      );

  DayPrayers prayersFor(DateTime date) {
    final (lat, lng) = coordinates;
    return PrayerCalculator.times(
      date: date,
      latitude: lat,
      longitude: lng,
      settings: prayerSettings(date),
    );
  }

  DayPrayers get todayPrayers => prayersFor(DateTime.now());

  void _set(FutureOr<void> Function() write) {
    write();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Day rollover — the day flips when the clock flips to 00:00

  String _dayKey = dayKey();
  String get currentDayKey => _dayKey;
  Timer? _midnightTimer;

  void _startDayRollover() => _scheduleMidnightTimer();

  /// Rolls the day forward if the calendar day changed. Safe to call often
  /// (the app calls it on every resume).
  void refreshDayIfNeeded() {
    final key = dayKey();
    if (key != _dayKey) {
      _dayKey = key;
      notifyListeners();
    }
    _scheduleMidnightTimer();
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _midnightTimer = Timer(nextMidnight.difference(now), refreshDayIfNeeded);
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  DayRecord get today => days[_dayKey] ?? DayRecord();

  // ---------------------------------------------------------------------------
  // Gate ordering — the founder's rule: morning leads until it is finished;
  // then the after-prayer awrād lead; after ʿIshāʼ the night wird leads.
  // Finished gates sink.

  List<Gate> gateOrder() {
    final now = DateTime.now();
    final prayers = todayPrayers;
    final isha = prayers.time(PrayerName.isha);
    final fajr = prayers.time(PrayerName.fajr);
    // Night runs from ʿIshāʼ until the next Fajr — including the hours after
    // midnight, when the calendar day has already rolled over.
    final afterIsha = isha != null ? !now.isBefore(isha) : now.hour >= 19;
    final beforeFajr = fajr != null ? now.isBefore(fajr) : now.hour < 4;
    final isNight = afterIsha || beforeFajr;

    List<Gate> order;
    if (isNight) {
      order = [Gate.night, Gate.afterPrayer, Gate.morning];
    } else if (progress(Gate.morning) >= 1) {
      order = [Gate.afterPrayer, Gate.morning, Gate.night];
    } else {
      order = [Gate.morning, Gate.afterPrayer, Gate.night];
    }
    final unfinished = order.where((g) => progress(g) < 1 || awradIn(g).isEmpty).toList();
    final finished = order.where((g) => progress(g) >= 1 && awradIn(g).isNotEmpty).toList();
    return [...unfinished, ...finished];
  }

  // ---------------------------------------------------------------------------
  // Queries

  List<Wird> awradIn(Gate gate) => awrad.where((w) => w.gate == gate).toList();

  int countFor(Wird wird) => today.count(wird);

  bool isDone(Wird wird) => today.isDone(wird);

  /// أورادي — read / not read today. "Read" is exactly "done today".
  bool isRead(Wird wird) => isDone(wird);

  /// When the wird was read today, if it was.
  DateTime? readAt(Wird wird) => today.readAt[wird.id];

  /// The timed awrād (everything but أوراد الأحوال) — what "the day" consists of.
  List<Wird> get timedAwrad => awrad.where((w) => w.gate != Gate.general).toList();

  int get readTodayCount => awrad.where(isRead).length;

  double progress(Gate gate) {
    final items = awradIn(gate);
    if (items.isEmpty) return 0;
    return items.where(isDone).length / items.length;
  }

  /// A day is "lit" when every wird of the three timed gates is complete.
  ///
  /// Today is evaluated live. Past days keep the `lit` flag recorded at the
  /// time — so adding a new wird later never un-lights history (light is
  /// never taken away). Days written by the Swift app have no flag and fall
  /// back to evaluating against the current awrād, as that app did.
  bool isLit(String key) {
    final record = days[key];
    if (record == null) return false;
    if (key != _dayKey && record.lit != null) return record.lit!;
    return _allTimedDone(record);
  }

  bool _allTimedDone(DayRecord record) {
    final timed = timedAwrad;
    if (timed.isEmpty) return false;
    return timed.every(record.isDone);
  }

  bool get todayIsLit => isLit(_dayKey);

  int get totalCompletedAllTime {
    var total = 0;
    for (final record in days.values) {
      record.completed.forEach((id, count) {
        final wird = awrad.where((w) => w.id == id).firstOrNull;
        if (wird != null ? count >= wird.targetCount : count > 0) total++;
      });
    }
    return total;
  }

  int get litDaysAllTime => days.keys.where(isLit).length;

  // ---------------------------------------------------------------------------
  // Mutations — light is never taken away

  void setCount(int count, Wird wird) {
    refreshDayIfNeeded(); // a tap after midnight belongs to the new day
    final record = today.copy();
    final previous = record.completed[wird.id] ?? 0;
    final next = count > previous ? count : previous; // never decreases
    record.completed[wird.id] = next;
    if (next >= wird.targetCount && !record.readAt.containsKey(wird.id)) {
      record.readAt[wird.id] = DateTime.now();
    }
    record.lit = _allTimedDone(record);
    days[_dayKey] = record;
    _saveAndNotify();
  }

  void markDone(Wird wird) => setCount(wird.targetCount, wird);

  /// Marks a wird as read today (from the أورادي checkmark).
  void markRead(Wird wird) => markDone(wird);

  /// Undo a mistaken tap — clears TODAY's progress for this wird only.
  /// Past days are history and stay lit; only the current day is editable.
  void resetToday(Wird wird) {
    refreshDayIfNeeded();
    final record = today.copy();
    record.completed[wird.id] = 0;
    record.readAt.remove(wird.id);
    record.lit = _allTimedDone(record);
    days[_dayKey] = record;
    _saveAndNotify();
  }

  void markUnread(Wird wird) => resetToday(wird);

  void toggleRead(Wird wird) => isRead(wird) ? markUnread(wird) : markRead(wird);

  bool contains(Wird wird) => awrad.any((w) => w.id == wird.id);

  void add(Wird wird) {
    if (contains(wird)) return;
    awrad = [...awrad, wird];
    _saveAndNotify();
  }

  /// Adds a library wird into a gate the user chose.
  void addToGate(Wird wird, Gate gate) => add(wird.copyWith(gate: gate));

  void update(Wird wird) {
    final index = awrad.indexWhere((w) => w.id == wird.id);
    if (index == -1) return;
    awrad = [...awrad]..[index] = wird;
    _saveAndNotify();
  }

  void remove(Wird wird) {
    awrad = awrad.where((w) => w.id != wird.id).toList();
    _saveAndNotify();
  }

  /// Re-adds any missing suggested awrād (after deletions) — nothing duplicated.
  void restoreStarters() {
    for (final wird in AdhkarLibrary.starterAwrad) {
      if (!contains(wird)) awrad = [...awrad, wird];
    }
    _saveAndNotify();
  }

  // ---------------------------------------------------------------------------
  // Khatma circles

  void addCircle(KhatmaCircle circle) {
    circles = [...circles, circle];
    _saveAndNotify();
  }

  void updateCircle(KhatmaCircle circle) {
    final index = circles.indexWhere((c) => c.id == circle.id);
    if (index == -1) return;
    circles = [...circles]..[index] = circle;
    _saveAndNotify();
  }

  void removeCircle(KhatmaCircle circle) {
    circles = circles.where((c) => c.id != circle.id).toList();
    _saveAndNotify();
  }

  KhatmaCircle? circleById(String id) => circles.where((c) => c.id == id).firstOrNull;

  /// Allocates the 30 ajzāʼ as sequential ranges by the creator's chosen counts.
  static List<KhatmaMember> allocateAjza(List<String> names, List<int> counts) {
    final members = <KhatmaMember>[];
    var next = 1;
    for (var i = 0; i < names.length; i++) {
      final count = counts[i];
      if (count <= 0) {
        members.add(KhatmaMember(name: names[i]));
        continue;
      }
      members.add(KhatmaMember(
        name: names[i],
        assigned: List.generate(count, (k) => next + k),
      ));
      next += count;
    }
    return members;
  }

  /// Even split of 30 for n members (remainder to the first members).
  static List<int> evenCounts(int memberCount) {
    if (memberCount <= 0) return [];
    final base = 30 ~/ memberCount;
    final remainder = 30 % memberCount;
    return List.generate(memberCount, (i) => i < remainder ? base + 1 : base);
  }

  /// Merges a pasted circle or progress code. Returns a human message.
  String merge(Decoded decoded) {
    switch (decoded) {
      case DecodedCircle(:final circle):
        if (circles.any((c) => c.id == circle.id)) {
          return 'هذه الحلقة موجودة عندك بالفعل';
        }
        circles = [...circles, circle];
        _saveAndNotify();
        return 'انضممتَ إلى حلقة «${circle.name}» — حدّد اسمك من داخل الحلقة';
      case DecodedProgress(:final update):
        final circle = circleById(update.circleId);
        if (circle == null) return 'لم أجد هذه الحلقة على جهازك';
        final member = circle.members.where((m) => m.id == update.memberId).firstOrNull;
        if (member == null) return 'لم أجد هذا العضو في الحلقة';
        final updated = circle.copy();
        updated.members.firstWhere((m) => m.id == update.memberId).completed =
            update.completed.toSet();
        updateCircle(updated);
        return 'تحدّث تقدم ${update.memberName} — ما شاء الله';
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}wrd-state.json');
  }

  /// Set when the state file existed but could not be parsed — saving is then
  /// preceded by a backup so nothing recoverable is overwritten.
  bool _loadFailed = false;

  Future<void> _loadState() async {
    File? file;
    try {
      file = await _file();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      awrad = (json['awrad'] as List? ?? [])
          .map((w) => Wird.fromJson(w as Map<String, dynamic>))
          .toList();
      final rawDays = json['days'] as Map<String, dynamic>? ?? {};
      days = {
        for (final e in rawDays.entries)
          e.key: DayRecord.fromJson(e.value as Map<String, dynamic>),
      };
      circles = (json['circles'] as List? ?? [])
          .map((c) => KhatmaCircle.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (error) {
      _loadFailed = file != null;
      debugPrint('WRD: could not load state — $error');
    }
  }

  // Writes are serialized: each save waits for the previous one, so two quick
  // taps can never interleave on the temp file. The JSON is snapshotted
  // synchronously at call time.
  Future<void> _pendingWrite = Future.value();

  Future<void> save() {
    final json = jsonEncode({
      'awrad': awrad.map((w) => w.toJson()).toList(),
      'days': {for (final e in days.entries) e.key: e.value.toJson()},
      'circles': circles.map((c) => c.toJson()).toList(),
    });
    _pendingWrite = _pendingWrite.then((_) => _write(json));
    return _pendingWrite;
  }

  Future<void> _write(String json) async {
    try {
      final file = await _file();
      if (_loadFailed && await file.exists()) {
        // Keep the unreadable original next to the new file — never clobber it.
        await file.copy('${file.path}.broken-${DateTime.now().millisecondsSinceEpoch}');
        _loadFailed = false;
      }
      final tmp = File('${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(file.path); // atomic replace
    } catch (error) {
      debugPrint('WRD: could not save state — $error');
    }
  }

  void _saveAndNotify() {
    notifyListeners();
    save();
  }
}
