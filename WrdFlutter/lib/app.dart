import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'notifications/notification_manager.dart';
import 'screens/circles_screen.dart';
import 'screens/library_screen.dart';
import 'screens/mishkat_screen.dart';
import 'screens/my_awrad_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/today_screen.dart';
import 'store/store_scope.dart';
import 'store/wrd_store.dart';
import 'theme/wrd_colors.dart';
import 'theme/wrd_theme.dart';

/// WRD وِرْد — the root. Arabic-first: the whole app runs right-to-left.
class WrdApp extends StatefulWidget {
  final WrdStore store;
  const WrdApp({super.key, required this.store});

  @override
  State<WrdApp> createState() => _WrdAppState();
}

class _WrdAppState extends State<WrdApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationManager.reschedule(widget.store);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.store.refreshDayIfNeeded();
      NotificationManager.reschedule(widget.store);
    }
  }

  ThemeMode _mode(WrdTheme theme) {
    switch (theme) {
      case WrdTheme.auto:
        return ThemeMode.system;
      case WrdTheme.parchment:
        return ThemeMode.light;
      case WrdTheme.candlelight:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: widget.store,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final store = widget.store;
          return MaterialApp(
            title: 'وِرْد',
            debugShowCheckedModeBanner: false,
            theme: wrdTheme(Brightness.light),
            darkTheme: wrdTheme(Brightness.dark),
            themeMode: _mode(store.theme),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: media.copyWith(
                    textScaler: TextScaler.linear(store.largeText ? 1.3 : 1.0),
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: store.hasOnboarded ? const RootTabs() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  static const _screens = [
    TodayScreen(),
    MyAwradScreen(),
    LibraryScreen(),
    MishkatScreen(),
    CirclesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: c.groundHigh,
        selectedItemColor: c.gold,
        unselectedItemColor: c.muted,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wb_twilight_outlined), label: 'اليوم'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: 'أورادي'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'المكتبة'),
          BottomNavigationBarItem(icon: Icon(Icons.nightlight_outlined), label: 'المشكاة'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: 'الحلقات'),
        ],
      ),
    );
  }
}
