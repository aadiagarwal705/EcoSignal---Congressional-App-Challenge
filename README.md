# EcoSignal MD

EcoSignal MD is a mobile app for keeping an eye on the environment in Maryland. It puts the state's real inspection records and reports from residents in one place, on a list and on a map, and it has an AI helper called EcoGuide that can explain what you're looking at.

There are two kinds of items in the app:

- Official records. These come from the Maryland Department of the Environment's public compliance inspection data, for all 24 counties. Nobody edits them in the app.
- Community reports. Anyone signed in can report a problem (erosion, flooding, water pollution, illegal dumping, habitat damage or something else) with up to 5 photos and 1 video, a spot on the map and a short description. These aren't verified, and the app says so.

You can also search and filter by county, save records and reports for later, set a home county so the Home tab shows what's near you, switch between light and dark mode, and change the text size and color theme. Admins get tools to remove reports and ban people who abuse the app.

EcoGuide is Gemini (2.5 Flash on Vertex AI) running in a Cloud Function. If you open it from a record or report, it gets that item's details along with your question. The button in the middle of the tab bar opens it for general questions, including how the app works.

## Tech

Flutter and Dart on the front end. Firebase for everything else: Google sign-in and anonymous guests (Auth), Firestore, Storage for photos and videos, Cloud Functions for EcoGuide, and Hosting for the privacy policy and terms pages. The map uses `flutter_map` with OpenStreetMap tiles.

## Running it

You need Flutter installed. Then:

```
flutter pub get
flutter run
```

Pick a simulator, emulator or connected phone when it asks. `flutter test` runs the tests.

The app talks to a Firebase project that is already set up (see `lib/firebase_options.dart`), so there's nothing to configure to try it out.

### On an iPhone

Building for a real iPhone needs a signing team. That part is personal, so it isn't saved in the project.

1. Run `open ios/Runner.xcworkspace` (the workspace, not the .xcodeproj).
2. In Xcode, click Runner, then the Runner target, then Signing & Capabilities.
3. Leave "Automatically manage signing" on and choose your own Team. If nothing is listed, add your Apple ID under Xcode > Settings > Accounts.
4. Plug the phone in, turn on Developer Mode (Settings > Privacy & Security), and run `flutter run` again. The first time you may also need to trust yourself under Settings > General > VPN & Device Management.

Picking a team edits `ios/Runner.xcodeproj/project.pbxproj`, so don't commit that change. With a free Apple account the app stops opening after 7 days, and running it again fixes that.

`video_compress` only supports CocoaPods, so iOS builds use CocoaPods next to Swift Package Manager. Flutter runs `pod install` for you.

### On the web

`flutter run -d chrome` works, with one catch. The geocoding plugin has no web version, so on Chrome you can open the map and drop a pin, but searching for an address and turning a pin into a place name or county won't work.

## Where things are

Everything is under `lib/`:

- `screens/` has the pages: `shell.dart` (the header and tab bar), `home.dart`, `explore.dart`, `new_report.dart`, `saved.dart`, `profile.dart`, `map_view.dart`, `ecoguide_chat.dart`, `settings.dart`, `admin.dart` and a few detail pages.
- `services/` talks to Firebase: `auth.dart`, `records.dart`, `reports.dart`, `uploads.dart` for Storage, `ecoguide_api.dart` for the Cloud Function and so on.
- `models/` holds the data classes and `widgets/` holds the reusable pieces.
- `constants/` has the theme and app-wide constants.

## Some behaviour worth knowing

- Reports need a Google sign-in. Everyone else browses as a guest, and whatever a guest saved moves to their account when they sign in.
- Each person gets 40 EcoGuide questions a day.
- Videos are shrunk to 720p on the phone before uploading, and anything still over 75 MB is turned down. Photos are capped at 8 MB by the storage rules.
- If an upload stalls, the app checks whether Firebase is actually reachable before it shows "Reconnecting". It gives up after 10 minutes of nothing.
- Deleting a report also deletes its photos and videos from Storage, through a Cloud Function.

The backend code (Cloud Functions, security rules, the script that imports the MDE data) lives outside this folder, in the same repository.
# EcoSignal---Congressional-App-Challenge
