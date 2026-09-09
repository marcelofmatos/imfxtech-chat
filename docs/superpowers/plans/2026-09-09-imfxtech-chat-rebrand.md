# IMFxTech Chat Rebrand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand this FluffyChat fork to "IMFxTech Chat" (name, `com.imfxtech.chat`
application/bundle ID, icons, theme color, and the identifiers/text tied to the old
brand) for Android and iOS, ending with a debug APK the user can install and test.

**Architecture:** This is a pure identity/asset rebrand, not a feature change. Work
proceeds native-platform-first (Android identity, then iOS identity — these are
independent file trees), then the shared Dart layer (central `app_config.dart`,
then the smaller scattered internal-namespace strings), then user-facing text
(config/privacy/l10n), then a final verification + build pass. Task 5 depends on
Task 4 having landed first (it deletes a constant that Task 4 makes provably
unused) — otherwise tasks are independent and can be reviewed/committed in
isolation.

**Tech Stack:** Flutter/Dart, Android (Kotlin, Gradle), iOS (Swift, Xcode project
files), Python 3 + Pillow for icon generation (already installed on this machine;
no new dependency is added to the Flutter project itself).

**Full spec:** `docs/superpowers/specs/2026-09-09-imfxtech-chat-rebrand-design.md`

**Environment note:** This machine is Linux — there is no Xcode here. Task 3 edits
iOS files correctly but cannot run an actual iOS build; Task 9 validates the iOS
files statically (well-formed XML) instead of building. The Android debug APK
(Task 9) is the actual runnable deliverable the user asked for.

**Environment status (already done, do not repeat):** Flutter 3.47.2, Android SDK
37 (with a `platforms/android-37 -> android-37.0` symlink — the bare `android-37`
package name doesn't exist upstream, only versioned `android-37.0`), NDK, cmake and
ninja-build are installed and working on this machine. `pubspec.lock`'s pinned
`matrix` git dependency commit was refreshed (the upstream branch had been
force-pushed past it). A baseline `flutter build apk --debug` already succeeded
before this plan's changes, producing a 306MB APK — the toolchain is confirmed
working end to end. If `flutter build apk --debug` in Task 9 fails, check first
whether a Gradle/Kotlin daemon is stuck (`cd android && ./gradlew --stop`) before
assuming a code problem — repeated builds on this machine have left daemons
lingering and briefly starved memory.

---

### Task 1: Generate the new launcher icons (Android + iOS)

**Files:**
- Create: `scripts/generate_brand_icons.py`
- Modify (overwritten by the script, not by hand): `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (20 files), `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`, `android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_foreground.png`, `android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_monochrome.png`
- Modify: `android/app/src/main/res/values/ic_launcher_background.xml`
- Modify: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Delete: `android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_background.png`, `android/app/src/main/res/drawable/ic_launcher_foreground.xml`, `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`

Source assets (already prepared by the designer, do not regenerate/reprocess them):
`~/HD3/botDon/branding/imfxtech-chat-icone-apple-appstore-1024.png` (iOS, full
bleed, no alpha), `imfxtech-chat-icone-android-recentrado-1024.png` (Android
legacy launcher, safe-zone centered, no alpha), and
`imfxtech-chat-icone-android-adaptativo-frente-1024.png` (Android adaptive
foreground layer, with alpha).

- [ ] **Step 1: Confirm the source assets are where the script expects them**

Run:
```bash
ls ~/HD3/botDon/branding/imfxtech-chat-icone-apple-appstore-1024.png \
   ~/HD3/botDon/branding/imfxtech-chat-icone-android-recentrado-1024.png \
   ~/HD3/botDon/branding/imfxtech-chat-icone-android-adaptativo-frente-1024.png
```
Expected: all three paths printed, no "No such file" error. If this fails, stop
and ask the user where the branding assets are — do not substitute placeholder
images.

- [ ] **Step 2: Write the icon generation script**

Create `scripts/generate_brand_icons.py`:

```python
#!/usr/bin/env python3
"""Generate IMFxTech Chat launcher icons from the branding source PNGs.

Source assets live outside this repo, in ~/HD3/botDon/branding/ (prepared by
the brand designer with the safe-zone recentering already done). Re-run this
script whenever those source PNGs are updated.
"""
import json
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
BRANDING = Path.home() / "HD3/botDon/branding"

APPLE_SRC = BRANDING / "imfxtech-chat-icone-apple-appstore-1024.png"
ANDROID_LEGACY_SRC = BRANDING / "imfxtech-chat-icone-android-recentrado-1024.png"
ANDROID_FG_SRC = BRANDING / "imfxtech-chat-icone-android-adaptativo-frente-1024.png"

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
LEGACY_BASE_DP = 48
FOREGROUND_BASE_DP = 108


def resize(src, size):
    return src.resize((size, size), Image.Resampling.LANCZOS)


def generate_ios_icons():
    src = Image.open(APPLE_SRC).convert("RGB")
    contents_path = (
        REPO / "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
    )
    contents = json.loads(contents_path.read_text())
    for entry in contents["images"]:
        size_pt = float(entry["size"].split("x")[0])
        scale = float(entry["scale"].rstrip("x"))
        px = round(size_pt * scale)
        out = contents_path.parent / entry["filename"]
        resize(src, px).save(out)
        print(f"iOS  {entry['filename']}: {px}x{px}")


def generate_android_legacy_icons():
    src = Image.open(ANDROID_LEGACY_SRC).convert("RGB")
    for density, mult in DENSITIES.items():
        px = round(LEGACY_BASE_DP * mult)
        out = REPO / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
        resize(src, px).save(out)
        print(f"Android legacy {density}: {px}x{px}")


def generate_android_foreground_icons():
    src = Image.open(ANDROID_FG_SRC).convert("RGBA")
    for density, mult in DENSITIES.items():
        px = round(FOREGROUND_BASE_DP * mult)
        out = (
            REPO
            / f"android/app/src/main/res/drawable-{density}/ic_launcher_foreground.png"
        )
        resize(src, px).save(out)
        print(f"Android foreground {density}: {px}x{px}")


def generate_android_monochrome_icons():
    src = Image.open(ANDROID_FG_SRC).convert("RGBA")
    alpha = src.getchannel("A")
    white_silhouette = Image.new("RGBA", src.size, (255, 255, 255, 0))
    white_silhouette.putalpha(alpha)
    for density, mult in DENSITIES.items():
        px = round(FOREGROUND_BASE_DP * mult)
        out = (
            REPO
            / f"android/app/src/main/res/drawable-{density}/ic_launcher_monochrome.png"
        )
        resize(white_silhouette, px).save(out)
        print(f"Android monochrome {density}: {px}x{px}")


def remove_old_background_pngs():
    for density in DENSITIES:
        f = (
            REPO
            / f"android/app/src/main/res/drawable-{density}/ic_launcher_background.png"
        )
        if f.exists():
            f.unlink()
            print(f"removed {f}")


if __name__ == "__main__":
    generate_ios_icons()
    generate_android_legacy_icons()
    generate_android_foreground_icons()
    generate_android_monochrome_icons()
    remove_old_background_pngs()
```

- [ ] **Step 3: Run the script**

Run: `python3 scripts/generate_brand_icons.py`

Expected: prints one line per generated file (20 iOS lines + 5 legacy + 5
foreground + 5 monochrome = 35 lines), then 5 "removed ..." lines for the deleted
background PNGs. No traceback.

- [ ] **Step 4: Verify no leftover old background PNGs and sample a couple of sizes**

Run:
```bash
find android/app/src/main/res -iname "ic_launcher_background.png"
python3 -c "
from PIL import Image
print(Image.open('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png').size)
print(Image.open('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png').size)
print(Image.open('android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png').size)
"
```
Expected: the `find` prints nothing (all 5 background PNGs gone). The Python
block prints `(1024, 1024)`, `(192, 192)`, `(432, 432)`.

- [ ] **Step 5: Simplify the adaptive icon background to a flat color**

Read `android/app/src/main/res/values/ic_launcher_background.xml`, then replace
its content:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0B1622</color>
</resources>
```

Read `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, then change:

```xml
  <background android:drawable="@drawable/ic_launcher_background"/>
```
to:
```xml
  <background android:drawable="@color/ic_launcher_background"/>
```

- [ ] **Step 6: Delete the dead vector fallback icons (old FluffyChat paw logo)**

Run:
```bash
git rm android/app/src/main/res/drawable/ic_launcher_foreground.xml \
       android/app/src/main/res/drawable/ic_launcher_monochrome.xml
```
Expected: both files listed as deleted.

- [ ] **Step 7: Commit**

```bash
git add scripts/generate_brand_icons.py \
        ios/Runner/Assets.xcassets/AppIcon.appiconset \
        android/app/src/main/res/mipmap-mdpi/ic_launcher.png \
        android/app/src/main/res/mipmap-hdpi/ic_launcher.png \
        android/app/src/main/res/mipmap-xhdpi/ic_launcher.png \
        android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png \
        android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png \
        android/app/src/main/res/drawable-mdpi \
        android/app/src/main/res/drawable-hdpi \
        android/app/src/main/res/drawable-xhdpi \
        android/app/src/main/res/drawable-xxhdpi \
        android/app/src/main/res/drawable-xxxhdpi \
        android/app/src/main/res/values/ic_launcher_background.xml \
        android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
git commit -m "feat: generate IMFxTech Chat launcher icons"
```

---

### Task 2: Android native identity

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Move: `android/app/src/main/kotlin/chat/fluffy/fluffychat/MainActivity.kt` → `android/app/src/main/kotlin/com/imfxtech/chat/MainActivity.kt`
- Move: `android/app/src/main/kotlin/chat/fluffy/fluffychat/FcmPushService.kt` → `android/app/src/main/kotlin/com/imfxtech/chat/FcmPushService.kt`
- Modify: `scripts/add-firebase-messaging.sh`

- [ ] **Step 1: Update the application ID / namespace**

Read `android/app/build.gradle.kts`, then change:
```kotlin
    namespace = "chat.fluffy.fluffychat"
```
to:
```kotlin
    namespace = "com.imfxtech.chat"
```
and change:
```kotlin
        applicationId = "chat.fluffy.fluffychat"
```
to:
```kotlin
        applicationId = "com.imfxtech.chat"
```

- [ ] **Step 2: Move the Kotlin package**

Run:
```bash
mkdir -p android/app/src/main/kotlin/com/imfxtech/chat
git mv android/app/src/main/kotlin/chat/fluffy/fluffychat/MainActivity.kt \
       android/app/src/main/kotlin/com/imfxtech/chat/MainActivity.kt
git mv android/app/src/main/kotlin/chat/fluffy/fluffychat/FcmPushService.kt \
       android/app/src/main/kotlin/com/imfxtech/chat/FcmPushService.kt
find android/app/src/main/kotlin/chat -type d -empty -delete
```
Expected: both `git mv` commands succeed, and
`android/app/src/main/kotlin/chat` no longer exists afterwards (check with
`ls android/app/src/main/kotlin` — only `com` should be listed).

- [ ] **Step 3: Update the package declaration in both moved files**

Read `android/app/src/main/kotlin/com/imfxtech/chat/MainActivity.kt`, then change:
```kotlin
package chat.fluffy.fluffychat
```
to:
```kotlin
package com.imfxtech.chat
```

Read `android/app/src/main/kotlin/com/imfxtech/chat/FcmPushService.kt` (note: this
whole file is commented out — the package line still has the `/*` comment marker
in front of it, keep it), then change:
```kotlin
/*package chat.fluffy.fluffychat
```
to:
```kotlin
/*package com.imfxtech.chat
```

- [ ] **Step 4: Fix the path this Kotlin file's activation script points to**

Read `scripts/add-firebase-messaging.sh`, then change (both occurrences — the
macOS and Linux branches of the same `sed` call):
```bash
  sed -i '' -e 's,^/\*,,' -e 's,\*/$,,' android/app/src/main/kotlin/chat/fluffy/fluffychat/FcmPushService.kt
else
  sed -i 's,//<GOOGLE_SERVICES>,,g' lib/utils/background_push.dart
  sed -i -e 's,^/\*,,' -e 's,\*/$,,' android/app/src/main/kotlin/chat/fluffy/fluffychat/FcmPushService.kt
```
to:
```bash
  sed -i '' -e 's,^/\*,,' -e 's,\*/$,,' android/app/src/main/kotlin/com/imfxtech/chat/FcmPushService.kt
else
  sed -i 's,//<GOOGLE_SERVICES>,,g' lib/utils/background_push.dart
  sed -i -e 's,^/\*,,' -e 's,\*/$,,' android/app/src/main/kotlin/com/imfxtech/chat/FcmPushService.kt
```

- [ ] **Step 5: Update the app label and the two custom URL-scheme intent filters**

Read `android/app/src/main/AndroidManifest.xml`, then change:
```xml
        android:label="FluffyChat"
```
to:
```xml
        android:label="IMFxTech Chat"
```

Then change:
```xml
            <!-- App can open im.fluffychat:// uris -->
            <intent-filter>
               <action android:name="android.intent.action.VIEW" />
               <category android:name="android.intent.category.DEFAULT" />
               <category android:name="android.intent.category.BROWSABLE" />
               <data android:scheme="im.fluffychat" android:host="chat" />
            </intent-filter>
```
to:
```xml
            <!-- App can open com.imfxtech.chat:// uris -->
            <intent-filter>
               <action android:name="android.intent.action.VIEW" />
               <category android:name="android.intent.category.DEFAULT" />
               <category android:name="android.intent.category.BROWSABLE" />
               <data android:scheme="com.imfxtech.chat" android:host="chat" />
            </intent-filter>
```

Then change:
```xml
                <data android:scheme="im.fluffychat.auth" android:path="/login"/>
```
to:
```xml
                <data android:scheme="com.imfxtech.chat.auth" android:path="/login"/>
```

- [ ] **Step 6: Verify no old identifiers remain in the files touched this task**

Run:
```bash
grep -rn "chat.fluffy.fluffychat\|im\.fluffychat" \
  android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml \
  android/app/src/main/kotlin scripts/add-firebase-messaging.sh
```
Expected: no output (empty).

- [ ] **Step 7: Commit**

```bash
git add android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml \
        android/app/src/main/kotlin scripts/add-firebase-messaging.sh
git commit -m "feat: rename Android application ID and package to com.imfxtech.chat"
```

---

### Task 3: iOS native identity

**Files:**
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `ios/Runner/Runner.entitlements`
- Modify: `ios/FluffyChat Share/FluffyChat Share.entitlements`
- Modify: `ios/Notification Service Extension/Notification Service Extension.entitlements`
- Modify: `ios/Notification Service Extension/NotificationService.swift`

Note: the Xcode target/folder names themselves (`FluffyChat Share`, `Notification
Service Extension`) are intentionally **not** renamed (see spec, "Não mexe") — only
bundle IDs, the App Group, and user-facing text change.

- [ ] **Step 1: Rewrite Info.plist with the new name, URL scheme, and permission text**

Read `ios/Runner/Info.plist`, then replace its entire content with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BGTaskSchedulerPermittedIdentifiers</key>
	<array>
		<string>com.imfxtech.chat</string>
	</array>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>IMFxTech Chat</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>IMFxTechChat</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>com.imfxtech.chat.uris</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)</string>
				<string>com.imfxtech.chat</string>
				<string>matrix</string>
			</array>
		</dict>
	</array>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>NSAppleMusicUsageDescription</key>
	<string>Play audio and voice messages in the app.</string>
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>Play audio and voice messages via bluetooth devices.</string>
	<key>NSBluetoothPeripheralUsageDescription</key>
	<string>Play audio and voice messages on bluetooth devices</string>
	<key>NSCalendarsUsageDescription</key>
	<string>Share calendar dates with your contacts in IMFxTech Chat.</string>
	<key>NSCameraUsageDescription</key>
	<string>Open the camera and take a picture to share them with your contacts on IMFxTech Chat.</string>
	<key>NSContactsUsageDescription</key>
	<string>Share contacts with your contacts in IMFxTech Chat.</string>
	<key>NSFaceIDUsageDescription</key>
	<string>IMFxTech Chat uses an app lock for an additional security level</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>Share your location with your contacts in IMFxTech Chat.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>Share your location with your contacts in IMFxTech Chat.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>Share your location with your contacts in IMFxTech Chat.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>Record voice message and share them with your contacts on IMFxTech Chat.</string>
	<key>NSMotionUsageDescription</key>
	<string>Share motions with your contacts in IMFxTech Chat.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Open photos from your gallery and share them with your contacts on IMFxTech Chat.</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>Share data with your contacts in IMFxTech Chat.</string>
	<key>UIBackgroundModes</key>
	<array>
		<string>voip</string>
		<string>audio</string>
		<string>fetch</string>
		<string>processing</string>
		<string>remote-notification</string>
	</array>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UIStatusBarHidden</key>
	<false/>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UIViewControllerBasedStatusBarAppearance</key>
	<false/>
	<key>io.flutter.embedded_views_preview</key>
	<true/>
	<key>NSAppTransportSecurity</key>
	<dict>
  	<key>NSAllowsArbitraryLoads</key>
  	<true/>
</dict>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>UIApplicationSceneManifest</key>
	<dict>
	<key>UIApplicationSupportsMultipleScenes</key>
	<false/>
	<key>UISceneConfigurations</key>
	<dict>
	<key>UIWindowSceneSessionRoleApplication</key>
		<array>
		<dict>
			<key>UISceneClassName</key>
			<string>UIWindowScene</string>
			<key>UISceneDelegateClassName</key>
			<string>FlutterSceneDelegate</string>
			<key>UISceneConfigurationName</key>
			<string>flutter</string>
			<key>UISceneStoryboardFile</key>
			<string>Main</string>
		</dict>
		</array>
	</dict>
	</dict>
</dict>
</plist>
```

- [ ] **Step 2: Verify Info.plist is still well-formed XML**

Run:
```bash
python3 -c "import plistlib; plistlib.load(open('ios/Runner/Info.plist', 'rb')); print('OK')"
```
Expected: `OK`. If this raises an exception, the plist is malformed — fix before continuing.

- [ ] **Step 3: Update the bundle identifiers in the Xcode project file**

Run:
```bash
sed -i \
  -e 's/PRODUCT_BUNDLE_IDENTIFIER = im\.fluffychat\.app;/PRODUCT_BUNDLE_IDENTIFIER = com.imfxtech.chat;/g' \
  -e 's/PRODUCT_BUNDLE_IDENTIFIER = "im\.fluffychat\.app\.FluffyChat-Share";/PRODUCT_BUNDLE_IDENTIFIER = com.imfxtech.chat.Share;/g' \
  -e 's/PRODUCT_BUNDLE_IDENTIFIER = "im\.fluffychat\.app\.Notification-Service-Extension";/PRODUCT_BUNDLE_IDENTIFIER = com.imfxtech.chat.NotificationService;/g' \
  ios/Runner.xcodeproj/project.pbxproj
```

- [ ] **Step 4: Verify the bundle ID replacement counts**

Run:
```bash
grep -c "PRODUCT_BUNDLE_IDENTIFIER = com.imfxtech.chat;" ios/Runner.xcodeproj/project.pbxproj
grep -c "PRODUCT_BUNDLE_IDENTIFIER = com.imfxtech.chat.Share;" ios/Runner.xcodeproj/project.pbxproj
grep -c "PRODUCT_BUNDLE_IDENTIFIER = com.imfxtech.chat.NotificationService;" ios/Runner.xcodeproj/project.pbxproj
grep -c "im\.fluffychat" ios/Runner.xcodeproj/project.pbxproj
```
Expected: `3`, `3`, `3`, then `0`. (The many other `FluffyChat`-capitalized matches
in this file — target names, group names, file references — are untouched by
design; this last grep is case-sensitive lowercase `fluffychat` only, so it only
catches what we intended to change.)

- [ ] **Step 5: Update the App Group in all three entitlements files**

Read `ios/Runner/Runner.entitlements`, then change:
```xml
		<string>group.im.fluffychat.app</string>
```
to:
```xml
		<string>group.com.imfxtech.chat</string>
```

Read `ios/FluffyChat Share/FluffyChat Share.entitlements`, then change:
```xml
		<string>group.im.fluffychat.app</string>
```
to:
```xml
		<string>group.com.imfxtech.chat</string>
```

Read `ios/Notification Service Extension/Notification Service Extension.entitlements`,
then change:
```xml
		<string>group.im.fluffychat.app</string>
```
to:
```xml
		<string>group.com.imfxtech.chat</string>
```

- [ ] **Step 6: Verify all three entitlements files are still well-formed XML and use the new group**

Run:
```bash
for f in "ios/Runner/Runner.entitlements" \
         "ios/FluffyChat Share/FluffyChat Share.entitlements" \
         "ios/Notification Service Extension/Notification Service Extension.entitlements"; do
  python3 -c "import plistlib,sys; plistlib.load(open(sys.argv[1],'rb')); print('OK', sys.argv[1])" "$f"
done
grep -rl "group.im.fluffychat.app" ios --include="*.entitlements"
```
Expected: three `OK ...` lines, then the final `grep -rl` prints nothing.

- [ ] **Step 7: Update the App Group and log tag in the Notification Service Extension's Swift code**

Run:
```bash
sed -i \
  -e 's/group\.im\.fluffychat\.app/group.com.imfxtech.chat/g' \
  -e 's/FluffyChatPushHelper/IMFxTechChatPushHelper/g' \
  "ios/Notification Service Extension/NotificationService.swift"
```

- [ ] **Step 8: Verify the Swift file replacement counts**

Run:
```bash
grep -c "group.com.imfxtech.chat" "ios/Notification Service Extension/NotificationService.swift"
grep -c "IMFxTechChatPushHelper" "ios/Notification Service Extension/NotificationService.swift"
grep -c "group.im.fluffychat.app\|FluffyChatPushHelper" "ios/Notification Service Extension/NotificationService.swift"
```
Expected: `2`, `15`, then `0`.

- [ ] **Step 9: Commit**

```bash
git add ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj \
        ios/Runner/Runner.entitlements \
        "ios/FluffyChat Share/FluffyChat Share.entitlements" \
        "ios/Notification Service Extension/Notification Service Extension.entitlements" \
        "ios/Notification Service Extension/NotificationService.swift"
git commit -m "feat: rename iOS bundle IDs, App Group and display name to IMFxTech Chat"
```

---

### Task 4: Remove the donation references pointing to the original creator

**Files:**
- Modify: `lib/pages/chat_list/client_chooser_button.dart`
- Modify: `lib/utils/show_update_snackbar.dart`

Both of these currently link to `ko-fi.com/.../How-can-I-support-FluffyChat...` —
the original FluffyChat creator's personal donation page. IMFxTech doesn't have an
equivalent page, so relabeling the text would send donations to the wrong person.
Remove the buttons instead (see spec, "Remoção do menu de doação").

- [ ] **Step 1: Remove the "Support FluffyChat" menu item**

Read `lib/pages/chat_list/client_chooser_button.dart`, then change:
```dart
      PopupMenuItem(
        value: SettingsAction.support,
        child: Row(
          children: [
            Icon(Icons.favorite, color: Colors.red),
            const SizedBox(width: 18),
            Text(L10n.of(context).supportFluffyChat),
          ],
        ),
      ),
      const PopupMenuDivider(),
```
to:
```dart
      const PopupMenuDivider(),
```

- [ ] **Step 2: Remove the menu action's handler**

In the same file, change:
```dart
        case SettingsAction.support:
          launchUrlString(
            'https://ko-fi.com/post/How-can-I-support-FluffyChat-J2G325WE6I',
          );
          break;
        case SettingsAction.settings:
```
to:
```dart
        case SettingsAction.settings:
```

- [ ] **Step 3: Remove the now-unused enum value**

In the same file, change:
```dart
enum SettingsAction {
  addAccount,
  newGroup,
  setStatus,
  invite,
  support,
  settings,
  archive,
}
```
to:
```dart
enum SettingsAction {
  addAccount,
  newGroup,
  setStatus,
  invite,
  settings,
  archive,
}
```

- [ ] **Step 4: Remove the now-unused `url_launcher_string` import**

In the same file, check first that `launchUrlString` has no remaining uses:

Run: `grep -n "launchUrlString" lib/pages/chat_list/client_chooser_button.dart`
Expected: no output (empty) — Steps 1-2 removed the only call site.

Then change:
```dart
import 'package:url_launcher/url_launcher_string.dart';
```
to remove that line entirely (delete it).

- [ ] **Step 5: Remove the "Support" button from the post-update dialog**

Read `lib/utils/show_update_snackbar.dart`, then change:
```dart
              AdaptiveDialogAction(
                bigButtons: true,
                onPressed: () => launchUrlString(AppConfig.helpUrl),
                child: Row(
                  mainAxisSize: .min,
                  spacing: 4,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    Text(
                      l10n.support,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              AdaptiveDialogAction(
                bigButtons: true,
                onPressed: () => launchUrlString(AppConfig.changelogUrl),
```
to:
```dart
              AdaptiveDialogAction(
                bigButtons: true,
                onPressed: () => launchUrlString(AppConfig.changelogUrl),
```

Note: keep both the `AppConfig` and `url_launcher_string` imports in this file —
both are still used by the Changelog button right below.

- [ ] **Step 6: Run static analysis to confirm nothing broke**

Run: `flutter analyze lib/pages/chat_list/client_chooser_button.dart lib/utils/show_update_snackbar.dart`
Expected: `No issues found!` (pre-existing unrelated issues elsewhere in the repo,
if any, don't count — only these two files matter for this step).

- [ ] **Step 7: Commit**

```bash
git add lib/pages/chat_list/client_chooser_button.dart lib/utils/show_update_snackbar.dart
git commit -m "fix: remove donation links pointing to the original FluffyChat creator"
```

---

### Task 5: Rewrite `lib/config/app_config.dart`

**Files:**
- Modify: `lib/config/app_config.dart`

Depends on Task 4 (it deletes `helpUrl`, which Task 4 makes provably unused).

- [ ] **Step 1: Confirm `helpUrl` has no remaining callers**

Run: `grep -rn "AppConfig.helpUrl" lib`
Expected: no output (empty). If this prints something, stop — Task 4 wasn't
completed correctly.

- [ ] **Step 2: Rewrite the file**

Read `lib/config/app_config.dart`, then replace its entire content with:

```dart
// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:ui';

abstract class AppConfig {
  static const Color primaryColor = Color(0xFFD8A954);

  static const Color chatColor = primaryColor;
  static const double messageFontSize = 16.0;
  static const bool allowOtherHomeservers = true;
  static const bool enableRegistration = true;
  static const bool hideTypingUsernames = false;

  static const String inviteLinkPrefix = 'https://matrix.to/#/';
  static const String deepLinkPrefix = 'com.imfxtech.chat://chat/';
  static const String schemePrefix = 'matrix:';
  static const String pushNotificationsChannelId = 'imfxtech_chat_push';
  static const String pushNotificationsAppId = 'com.imfxtech.chat';
  static const double borderRadius = 18.0;
  static const double spaceBorderRadius = 11.0;
  static const double columnWidth = 360.0;

  static const String enablePushTutorial =
      'https://ko-fi.com/post/How-can-I-get-Push-Notifications-without-Google-N7Q825URG6?fromEditor=true';
  static const String encryptionTutorial =
      'https://ko-fi.com/post/How-to-use-end-to-end-encryption-in-FluffyChat-A5O725WDR5';
  static const String howDoIGetStickersTutorial =
      'https://ko-fi.com/post/How-to-add-a-sticker-pack-to-FluffyChat-N4N01OXATI';
  static const String appId = 'com.imfxtech.chat.IMFxTechChat';
  static const String appOpenUrlScheme = 'com.imfxtech.chat';
  static const String appSsoUrlScheme = 'com.imfxtech.chat.auth';

  static const String sourceCodeUrl =
      'https://github.com/marcelofmatos/imfxtech-chat';
  static const String supportUrl =
      'https://github.com/marcelofmatos/imfxtech-chat/issues';
  static const String changelogUrl =
      'https://github.com/marcelofmatos/imfxtech-chat/blob/main/CHANGELOG.md';

  static const Set<String> defaultReactions = {'👍', '❤️', '😂', '😮', '😢'};

  static final Uri newIssueUrl = Uri(
    scheme: 'https',
    host: 'github.com',
    path: '/marcelofmatos/imfxtech-chat/issues/new',
  );

  static final Uri homeserverList = Uri(
    scheme: 'https',
    host: 'raw.githubusercontent.com',
    path:
        'marcelofmatos/imfxtech-chat/refs/heads/main/recommended_homeservers.json',
  );

  static final Uri crashReportEndpoint = Uri(
    scheme: 'https',
    host: 'crash.fluffy.chat',
  );

  static const String mainIsolatePortName = 'main_isolate';
  static const String pushIsolatePortName = 'push_isolate';
  static const String pushHelperCrashReportKey = 'push_helper_crash_report';
}
```

Note: `enablePushTutorial`/`encryptionTutorial`/`howDoIGetStickersTutorial` (generic
Matrix/E2E help content — AGPL requires keeping attribution anyway) and
`crashReportEndpoint` (dead code, referenced nowhere) are deliberately left
unchanged — see spec.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/config/app_config.dart`
Expected: `No issues found!`

- [ ] **Step 4: Verify nothing else in the repo still expects `helpUrl`**

Run: `grep -rn "helpUrl" lib`
Expected: no output (empty).

- [ ] **Step 5: Commit**

```bash
git add lib/config/app_config.dart
git commit -m "feat: rebrand app_config.dart identifiers, theme color and links to IMFxTech Chat"
```

---

### Task 6: Internal namespace strings scattered across the Dart layer

**Files:**
- Modify: `lib/utils/event_checkbox_extension.dart`
- Modify: `lib/utils/client_manager.dart`
- Modify: `lib/utils/account_config.dart`
- Modify: `lib/utils/account_bundles.dart`
- Modify: `lib/pages/chat_list/chat_list.dart`
- Modify: `lib/utils/fluffy_share.dart`
- Modify: `lib/widgets/fluffy_chat_app.dart`
- Modify: `lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/builder.dart`
- Modify: `lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/cipher.dart`

- [ ] **Step 1: `event_checkbox_extension.dart`**

Read the file, then change:
```dart
  static const String relationshipType = 'im.fluffychat.checkboxes';
```
to:
```dart
  static const String relationshipType = 'com.imfxtech.chat.checkboxes';
```

- [ ] **Step 2: `client_manager.dart`**

Read the file, then change:
```dart
  static const String clientNamespace = 'im.fluffychat.store.clients';
```
to:
```dart
  static const String clientNamespace = 'com.imfxtech.chat.store.clients';
```

- [ ] **Step 3: `account_config.dart`**

Read the file, then change:
```dart
  static const String accountDataKey = 'im.fluffychat.account_config';
```
to:
```dart
  static const String accountDataKey = 'com.imfxtech.chat.account_config';
```

- [ ] **Step 4: `account_bundles.dart`**

Read the file, then change:
```dart
const accountBundlesType = 'im.fluffychat.account_bundles';
```
to:
```dart
const accountBundlesType = 'com.imfxtech.chat.account_bundles';
```

- [ ] **Step 5: `chat_list.dart`**

Read the file, then change:
```dart
  static const String _serverStoreNamespace = 'im.fluffychat.search.server';
```
to:
```dart
  static const String _serverStoreNamespace = 'com.imfxtech.chat.search.server';
```

- [ ] **Step 6: `fluffy_share.dart`**

Read the file, then change:
```dart
        'https://matrix.to/#/${client.userID}?client=im.fluffychat',
```
to:
```dart
        'https://matrix.to/#/${client.userID}?client=com.imfxtech.chat',
```

- [ ] **Step 7: `fluffy_chat_app.dart`**

Read the file, then change:
```dart
        'sharemedia-im.fluffychat.app',
```
to:
```dart
        'sharemedia-com.imfxtech.chat',
```

- [ ] **Step 8: `builder.dart` (two occurrences of the same line)**

Read the file, then change **both** occurrences of:
```dart
        appGroupIdentifier: 'group.im.fluffychat.app',
```
to:
```dart
        appGroupIdentifier: 'group.com.imfxtech.chat',
```
(Use the replace-all form of your edit tool for this one file since the line is
identical at both call sites, lines 57 and 173.)

- [ ] **Step 9: `cipher.dart`**

Read the file, then change:
```dart
  const iosOptions = IOSOptions(groupId: 'group.im.fluffychat.app');
```
to:
```dart
  const iosOptions = IOSOptions(groupId: 'group.com.imfxtech.chat');
```

- [ ] **Step 10: Verify no old identifiers remain in any of these files**

Run:
```bash
grep -rn "im\.fluffychat" \
  lib/utils/event_checkbox_extension.dart \
  lib/utils/client_manager.dart \
  lib/utils/account_config.dart \
  lib/utils/account_bundles.dart \
  lib/pages/chat_list/chat_list.dart \
  lib/utils/fluffy_share.dart \
  lib/widgets/fluffy_chat_app.dart \
  lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/builder.dart \
  lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/cipher.dart
```
Expected: no output (empty).

- [ ] **Step 11: Run static analysis**

Run: `flutter analyze lib/utils/event_checkbox_extension.dart lib/utils/client_manager.dart lib/utils/account_config.dart lib/utils/account_bundles.dart lib/pages/chat_list/chat_list.dart lib/utils/fluffy_share.dart lib/widgets/fluffy_chat_app.dart lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/builder.dart lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/cipher.dart`
Expected: `No issues found!`

- [ ] **Step 12: Commit**

```bash
git add lib/utils/event_checkbox_extension.dart lib/utils/client_manager.dart \
        lib/utils/account_config.dart lib/utils/account_bundles.dart \
        lib/pages/chat_list/chat_list.dart lib/utils/fluffy_share.dart \
        lib/widgets/fluffy_chat_app.dart \
        lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/builder.dart \
        lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/cipher.dart
git commit -m "feat: rename internal im.fluffychat.* namespaces to com.imfxtech.chat.*"
```

---

### Task 7: `config.sample.json` and `PRIVACY.md`

**Files:**
- Modify: `config.sample.json`
- Modify: `PRIVACY.md`

- [ ] **Step 1: Update `config.sample.json`**

Read `config.sample.json`, then change:
```json
  "applicationName": "FluffyChat",
```
to:
```json
  "applicationName": "IMFxTech Chat",
```

Then change:
```json
  "privacyUrl": "https://github.com/krille-chan/fluffychat/blob/main/PRIVACY.md",
```
to:
```json
  "privacyUrl": "https://github.com/marcelofmatos/imfxtech-chat/blob/main/PRIVACY.md",
```

Then change:
```json
  "colorSchemeSeedInt": 4283835834,
```
to:
```json
  "colorSchemeSeedInt": 4292389204,
```

`defaultHomeserver` (`"matrix.org"`) and `presetHomeserver` (`""`) are
**unchanged** — see spec: there's no single fixed homeserver, `presetHomeserver`
already stays empty so users keep entering their own.

- [ ] **Step 2: Verify `config.sample.json` is still valid JSON**

Run: `python3 -c "import json; json.load(open('config.sample.json')); print('OK')"`
Expected: `OK`

- [ ] **Step 3: Rewrite `PRIVACY.md`**

Read `PRIVACY.md`, then replace its entire content with:

```markdown
<!--
SPDX-FileCopyrightText: 2019-Present Christian Kußowski
SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat

SPDX-License-Identifier: AGPL-3.0-or-later
-->

A política de privacidade própria do IMFxTech Chat ainda está em elaboração.

Enquanto isso, veja a política do projeto original em que este app se baseia
(FluffyChat): https://fluffychat.im/privacy
```

- [ ] **Step 4: Commit**

```bash
git add config.sample.json PRIVACY.md
git commit -m "feat: update config.sample.json and PRIVACY.md for IMFxTech Chat"
```

---

### Task 8: User-facing text (English + Portuguese)

**Files:**
- Modify: `lib/l10n/intl_en.arb`
- Modify: `lib/l10n/intl_pt_BR.arb`
- Modify: `lib/l10n/intl_pt_PT.arb`

Scope is deliberately limited to these 3 files — see spec ("Textos visíveis (l10n)
— apenas inglês e português"). The `supportFluffyChat` key is intentionally left
untouched (orphaned) in all languages, since Task 4 removed its only usage.

- [ ] **Step 1: `intl_en.arb` — `inviteText`**

Read the file, then change:
```json
    "inviteText": "{username} invited you to FluffyChat.\n1. Visit fluffychat.im and install the app \n2. Sign up or sign in \n3. Open the invite link: \n {link}",
```
to:
```json
    "inviteText": "{username} invited you to IMFxTech Chat.\n1. Install IMFxTech Chat \n2. Sign up or sign in \n3. Open the invite link: \n {link}",
```

- [ ] **Step 2: `intl_en.arb` — `newMessageInFluffyChat`**

In the same file, change:
```json
    "newMessageInFluffyChat": "💬 New message in FluffyChat",
```
to:
```json
    "newMessageInFluffyChat": "💬 New message in IMFxTech Chat",
```

- [ ] **Step 3: `intl_en.arb` — `signUpGreeting`**

In the same file, change:
```json
    "signUpGreeting": "FluffyChat is decentralized! Select a server where you want to create your account and let's go!",
```
to:
```json
    "signUpGreeting": "IMFxTech Chat is decentralized! Select a server where you want to create your account and let's go!",
```

- [ ] **Step 4: `intl_en.arb` — `possibleByYou`**

In the same file, change:
```json
    "possibleByYou": "This release was only possible thanks to your support. FluffyChat remains free, open-source, and entirely community-driven.",
```
to:
```json
    "possibleByYou": "Thanks for updating! You're now on the latest version of IMFxTech Chat.",
```

- [ ] **Step 5: `intl_en.arb` — `newPassphraseDescription`**

In the same file, change:
```json
    "newPassphraseDescription": "FluffyChat uses end to end encryption. To not lose your messages, please choose a strong passphrase to secure your crypto identity and your encrypted message backup.",
```
to:
```json
    "newPassphraseDescription": "IMFxTech Chat uses end to end encryption. To not lose your messages, please choose a strong passphrase to secure your crypto identity and your encrypted message backup.",
```

- [ ] **Step 6: Verify `intl_en.arb` is still valid JSON and the old name is gone (except the orphaned key)**

Run:
```bash
python3 -c "import json; json.load(open('lib/l10n/intl_en.arb')); print('OK')"
grep -n "FluffyChat" lib/l10n/intl_en.arb
```
Expected: `OK`, then only 2 lines left: `"supportFluffyChat": "Support FluffyChat",`
and its `"@supportFluffyChat": {` metadata block header — both expected to remain
(orphaned key, left untouched by design).

- [ ] **Step 7: `intl_pt_BR.arb` — `inviteText` and `newMessageInFluffyChat`**

Read the file, then change:
```json
    "inviteText": "{username} convidou você para o FluffyChat.\n1. Visite fluffychat.im e instale o aplicativo\n2. Entre ou crie uma conta\n3. Abra o link do convite:\n{link}",
```
to:
```json
    "inviteText": "{username} convidou você para o IMFxTech Chat.\n1. Instale o IMFxTech Chat\n2. Entre ou crie uma conta\n3. Abra o link do convite:\n{link}",
```

Then change:
```json
    "newMessageInFluffyChat": "💬 Nova mensagem no FluffyChat",
```
to:
```json
    "newMessageInFluffyChat": "💬 Nova mensagem no IMFxTech Chat",
```

- [ ] **Step 8: Verify `intl_pt_BR.arb` is still valid JSON**

Run: `python3 -c "import json; json.load(open('lib/l10n/intl_pt_BR.arb')); print('OK')"`
Expected: `OK`

- [ ] **Step 9: `intl_pt_PT.arb` — `inviteText`, `newMessageInFluffyChat`, `noGoogleServicesWarning`**

Read the file, then change:
```json
    "inviteText": "{username} convidou-te para o FluffyChat.\n1. Instala o FluffyChat: https://fluffychat.im\n2. Regista-te ou inicia sessão.\n3. Abre a ligação de convite: {link}",
```
to:
```json
    "inviteText": "{username} convidou-te para o IMFxTech Chat.\n1. Instala o IMFxTech Chat\n2. Regista-te ou inicia sessão.\n3. Abre a ligação de convite: {link}",
```

Then change:
```json
    "newMessageInFluffyChat": "Nova mensagem no FluffyChat",
```
to:
```json
    "newMessageInFluffyChat": "Nova mensagem no IMFxTech Chat",
```

Then change:
```json
    "noGoogleServicesWarning": "Parece que não tens nenhuns serviços da Google no seu telemóvel. É uma boa decisão para a sua privacidade! Para receber notificações instantâneas no FluffyChat, recomendamos que uses https://microg.org/ ou https://unifiedpush.org/.",
```
to:
```json
    "noGoogleServicesWarning": "Parece que não tens nenhuns serviços da Google no seu telemóvel. É uma boa decisão para a sua privacidade! Para receber notificações instantâneas no IMFxTech Chat, recomendamos que uses https://microg.org/ ou https://unifiedpush.org/.",
```

- [ ] **Step 10: Verify `intl_pt_PT.arb` is still valid JSON**

Run: `python3 -c "import json; json.load(open('lib/l10n/intl_pt_PT.arb')); print('OK')"`
Expected: `OK`

- [ ] **Step 11: Commit**

```bash
git add lib/l10n/intl_en.arb lib/l10n/intl_pt_BR.arb lib/l10n/intl_pt_PT.arb
git commit -m "feat: update English and Portuguese strings for IMFxTech Chat"
```

---

### Task 9: Final verification and debug APK build

**Files:** none (verification only — no commit at the end of this task unless a
problem is found and fixed).

- [ ] **Step 1: Full-repo sweep for anything left over in what we changed**

Run:
```bash
grep -rn "chat\.fluffy\.fluffychat\|im\.fluffychat" \
  android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml \
  android/app/src/main/kotlin ios/Runner/Info.plist \
  ios/Runner.xcodeproj/project.pbxproj ios/Runner/Runner.entitlements \
  "ios/FluffyChat Share/FluffyChat Share.entitlements" \
  "ios/Notification Service Extension/Notification Service Extension.entitlements" \
  "ios/Notification Service Extension/NotificationService.swift" \
  lib/config/app_config.dart \
  lib/utils/event_checkbox_extension.dart lib/utils/client_manager.dart \
  lib/utils/account_config.dart lib/utils/account_bundles.dart \
  lib/pages/chat_list/chat_list.dart lib/utils/fluffy_share.dart \
  lib/widgets/fluffy_chat_app.dart \
  lib/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database \
  config.sample.json
```
Expected: no output (empty). If anything prints, go back and fix it in the
relevant task before continuing.

- [ ] **Step 2: Confirm the deliberately-untouched items are still exactly as before**

Run:
```bash
grep -n "^name:" pubspec.yaml
grep -c "package:fluffychat/" lib/main.dart
grep -n "crash.fluffy.chat" lib/config/app_config.dart
```
Expected: `name: fluffychat`, a non-zero count (the import is still there,
unchanged), and one line with `host: 'crash.fluffy.chat',`. These three
confirm the "não mexe" scope boundary from the spec wasn't accidentally crossed.

- [ ] **Step 3: Statically validate the touched iOS plist/entitlements files**

(No Xcode on this machine — this is the closest available check.)

Run:
```bash
for f in "ios/Runner/Info.plist" "ios/Runner/Runner.entitlements" \
         "ios/FluffyChat Share/FluffyChat Share.entitlements" \
         "ios/Notification Service Extension/Notification Service Extension.entitlements"; do
  python3 -c "import plistlib,sys; plistlib.load(open(sys.argv[1],'rb')); print('OK', sys.argv[1])" "$f"
done
```
Expected: 4 `OK ...` lines.

- [ ] **Step 4: Full static analysis**

Run: `flutter analyze`
Expected: `No issues found!` (or only pre-existing issues unrelated to any file
this plan touched — if you see a new error mentioning a file from this plan,
stop and fix it).

- [ ] **Step 5: Clean build and generate the debug APK**

If this is the first build attempt in this task, first stop any stale daemons
from previous runs (this machine has had memory pressure from lingering Gradle/
Kotlin daemons across repeated builds):
```bash
(cd android && ./gradlew --stop) || true
pkill -f KotlinCompileDaemon || true
```

Then:
```bash
flutter pub get
flutter build apk --debug
```
(`flutter clean` is not required — a baseline build already succeeded in this
checkout before this plan's changes, so build caches are warm. Only run
`flutter clean` if the build fails with a stale-cache-looking error.)

Expected: build succeeds, ending with a line like
`✓ Built build/app/outputs/flutter-apk/app-debug.apk`.

If the build is killed for low memory, stop the daemons again (command above),
wait for `free -h` to show at least ~10GB "disponível", and retry.

- [ ] **Step 6: Confirm the APK exists and report its path to the user**

Run: `ls -lh build/app/outputs/flutter-apk/app-debug.apk`
Expected: the file is listed with a non-zero size. Report this exact path back to
the user as the test build — this file is git-ignored (Flutter's default
`.gitignore` already excludes `build/`), so it is not committed.

- [ ] **Step 7 (manual, when a device/emulator is available — not automatable here): install and spot-check**

`adb install build/app/outputs/flutter-apk/app-debug.apk`, then confirm: launcher
name reads "IMFxTech Chat", the icon looks correct (check both a round-icon and a
squircle-icon launcher if possible), the theme accent is gold, and the login
screen still accepts a custom homeserver URL (e.g. `chat.<cliente>.vps.imfxtech.com`).
This step has no pass/fail command — note the outcome back to the user.
