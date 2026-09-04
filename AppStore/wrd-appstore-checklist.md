# WRD وِرد — App Store Submission Checklist

*Prepared Sep 1, 2026 · App: Wrd.xcodeproj on Desktop · Version 1.0 (build 1)*

## ✅ Already done in the project (Sep 1)

- Bundle ID set to `com.yahyademeriah.wrd` (permanent after first upload — do not change again)
- iPhone-only (iPad runs it in compatibility mode; no iPad screenshots needed)
- Portrait-only orientation
- Deployment target lowered 26.5 → 17.0 (build once in Xcode to confirm no API warnings; raise to 18.0 only if the compiler demands it)
- Home-screen display name: **وِرد**
- Encryption compliance pre-answered (`ITSAppUsesNonExemptEncryption = NO`) — no export-compliance question at upload
- App icon: single 1024×1024, valid

## 1 · Apple Developer Program (the blocker — start today)

1. Go to developer.apple.com/programs/enroll → sign in with your Apple ID (enable two-factor first).
2. Enroll as **Individual** ($99/yr). You'll need a government ID matching your Apple ID name.
3. **Country note:** the Developer Program requires enrollment from a supported country/region — Syria is not on Apple's list. Your roadmap already plans a Jordan / UAE / US entity; an Individual enrollment needs a supported-country address and payment card. If you enroll through the future entity instead, that becomes an **Organization** enrollment and needs a D-U-N-S number (slower — weeks). For a free app, Individual is the fastest path; you can migrate to an Organization account later.
4. Approval usually takes 24–48h (sometimes an ID-verification call).
5. Once approved, in Xcode → Settings → Accounts, make sure the paid team appears; the project's team ID may need switching from the current personal team.

## 2 · App Store Connect — create the app record

1. appstoreconnect.apple.com → My Apps → **+** → New App.
2. Platform iOS · Name: **WRD وِرد: أذكار وأوراد** · Primary language: **Arabic** · Bundle ID: `com.yahyademeriah.wrd` · SKU: `wrd-ios-001`.
3. Category: **Lifestyle** (secondary: Reference). Price: **Free**. Availability: all territories.
4. Age rating questionnaire → all "None" → rating **4+**.
5. **App Privacy** → "Data Not Collected" (true: no accounts, no analytics, no network calls — everything on device). Add the privacy policy URL (step 3).

## 3 · Privacy policy URL (required field)

- `privacy-policy.md` (in this folder) is ready, Arabic + English.
- Host it anywhere public. Fastest: your existing GitHub repo → Settings → Pages, or a GitHub Gist opened in a browser. Best: wrd.app/privacy when the domain is live.
- Paste the URL into App Store Connect → App Privacy.

## 4 · Screenshots (the only asset left to make)

- Required: **6.9″ set** (iPhone 17 Pro Max simulator) — 3 to 10 images, 1320×2868. App Store Connect auto-scales it for smaller sizes.
- Take them in the simulator: ⌘S saves to Desktop. Suggested frames (per your brand guide — one message per frame, parchment day set):
  1. Today screen with gates partly lit — «وِردُكَ نُورُك»
  2. The tasbih counter mid-count
  3. The library with source lines visible
  4. The mishkāt month view with lit days
  5. A khatma circle
  6. Final frame: privacy creed + slogan
- Fill the simulator with real-looking data first (name set, a few awrād completed).

## 5 · Archive & upload (in Xcode)

1. Select scheme **Wrd** → destination **Any iOS Device (arm64)**.
2. Menu **Product → Archive**. Wait for the Organizer window.
3. **Distribute App → App Store Connect → Upload** → accept defaults (automatic signing) → Upload.
4. Wait ~15–30 min for processing (email arrives when the build is ready).

## 6 · Submit for review

1. In the app record → version 1.0 → select the processed build.
2. Paste description, keywords, promotional text (see `wrd-appstore-listing.md`), support URL, screenshots.
3. **App Review notes** — paste the English reviewer note from the listing doc (reviewers may not read Arabic; explain what the app is and that no login is needed).
4. Submit. First review typically takes 24–72h.
5. Choose **Manually release** if you want to hold the release for your Jan 15 launch date; otherwise it goes live on approval.

## Common first-submission rejections to avoid (already handled)

- ~~Metadata mentions features that don't exist~~ → listing copy below matches the shipped app only (no mushaf reader, no audio, no accounts — don't mention them)
- ~~Placeholder content~~ → make sure simulator screenshots show real adhkār, not lorem
- ~~Broken links~~ → test the privacy URL in an incognito window before submitting
- 4.3 spam/design: adhkār is a crowded category — your mishkāt + circles + sourced-content angle is the differentiator; the description leads with it

## After approval

- Reply to every review AR/EN (per your marketing playbook)
- Tag the repo: `git tag v1.0-appstore` after the accepted build
