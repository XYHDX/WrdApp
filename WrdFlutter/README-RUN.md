# WRD وِرْد — Flutter (iOS + Android)

النسخة ٠٫٨ — نقلٌ كامل لتطبيق وِرْد من SwiftUI إلى Flutter، مع:

- **مواقيت الصلاة العالمية**: تُختار طريقة الحساب تلقائيًا بحسب بلدك (أم القرى، المصرية، كراتشي، الديانة التركية، رابطة العالم الإسلامي، ISNA، جاكيم، إندونيسيا، دبي، الكويت، قطر، الأردن، طهران، المغرب، الجزائر، تونس، فرنسا، روسيا، سنغافورة)، مع مذهب العصر، وقاعدة العروض العالية، وتعديل دقيق بالدقائق. الموقع يُحدَّد من الجهاز ولا يغادره؛ وقائمة مدن للعمل بلا موقع.
- **أورادي: مقروء / غير مقروء** لكل وِرد في يومه، يتجدّد مع كل يوم، ويُعلَّم تلقائيًا عند إتمام العدّاد أو باليد بنقرة، ويهبط المقروء إلى أسفل بوابته.
- كل ما في نسخة iOS: البوابات الأربع، اليوم، المكتبة بالمصادر، العدّاد اللمسي، المشكاة ومشاركتها، الحلقات برموز واتساب وQR، الإعدادات، الترحيب.

---

## 1) أول تشغيل على الماك (خطوة واحدة تولّد مجلدات المنصّات)

```bash
cd ~/Desktop/Wrd/WrdFlutter
flutter create . --org com.yahyademeriah --project-name wrd --platforms ios,android
flutter pub get
flutter analyze
flutter test
```

> `--org com.yahyademeriah` يعطي المعرّف `com.yahyademeriah.wrd` — نفس معرّف تطبيق Swift، فيُثبَّت التحديث فوق النسخة الحالية على الآيفون **ويقرأ ملف الحالة نفسه** (`wrd-state.json`) فلا يضيع نور أحد.

إن ظهرت أخطاء من `flutter analyze` أرسلها لي كما هي (نصًا أو لقطة) — أعالجها ملفًا ملفًا كما نفعل مع Xcode.

## 2) إعدادات iOS (`ios/Runner/Info.plist`)

أضِف داخل `<dict>`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>يُستخدم موقعك لحساب مواقيت الصلاة بطريقة بلدك — ولا يغادر جهازك.</string>
<key>CFBundleDisplayName</key>
<string>وِرد</string>
<key>CFBundleDevelopmentRegion</key>
<string>ar</string>
<key>UISupportedInterfaceOrientations</key>
<array><string>UIInterfaceOrientationPortrait</string></array>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

ثم: `cd ios && pod install && cd ..` (إن طلب ذلك).

## 3) إعدادات Android

`android/app/src/main/AndroidManifest.xml` — داخل `<manifest>`:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

وداخل `<application>`:

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```

وفي `android/app/build.gradle.kts` (تحتاجه `flutter_local_notifications`):

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig { minSdk = 23 }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

## 4) التشغيل

```bash
flutter devices
flutter run            # على الجهاز/المحاكي المختار
flutter run -d <id>    # جهاز معيّن
```

## 5) خريطة الملفات

```
lib/
  main.dart · app.dart                 المدخل، الثيم، RTL، التبويبات، الترحيب
  models/   gate · wird · day_record · khatma
  data/     adhkar_library.dart        المكتبة المأثورة بالمصادر (المعرّفات نفسها)
  store/    wrd_store.dart             الحالة والإعدادات والحفظ (ملف Swift نفسه)
  prayer/   prayer_method.dart         طرق الحساب + خريطة البلدان
            prayer_calculator.dart     المحرّك الفلكي (مُتحقَّق منه مقابل adhan)
            cities.dart · location_service.dart
  notifications/ notification_manager.dart   الأذان وتذكير البوابات
  circles/  circle_codec.dart          رموز WRD1./WRDU. (متوافقة مع نسخة iOS)
  screens/  today · my_awrad · library · counter · compose · suggested
            mishkat · circles · settings · onboarding
  theme/ · widgets/ · util/
test/       prayer_test.dart · read_state_test.dart
```

## ملاحظات

- الخطوط: تُستخدم خطوط النظام العربية (SF Arabic / Noto Naskh). لإضافة Amiri لاحقًا: ضع الملفات في `assets/fonts/` وأعلنها في `pubspec.yaml` وحدّد `fontFamily` في `theme/wrd_theme.dart`.
- لجنة رؤية الهلال (Moonsighting) مُقرَّبة بزوايا ثابتة ١٨/١٨ — تُختار يدويًا فقط.
- الحلقات ما تزال بلا مخدّم (رموز يدوية) — المزامنة الحية تنتظر مفاتيح Supabase كما في الخطة.
