# Nexora Flutter Chat & WebRTC Calling Client

Next-Gen real-time instant messaging, group channels, and WebRTC HD audio/video calling application built with Flutter, matching the full design system and backend integration of the Next.js web application.

---

## 🚀 Features

- **🎨 Design & Theme**:
  - Premium Dark Slate & Emerald design system (`#020617` background, `#0F172A` surface, `#10B981` primary).
  - Glassmorphic rounded containers, Inter/Poppins typography, fluid animations.
  - Adaptive layout: Split multi-pane view on Desktop/Web/Tablet and native stacked navigation on Mobile.

- **🔐 Authentication & User Profile**:
  - User Registration with form validation.
  - Email Verification screen with token input and resend support.
  - JWT Login with persistent session storage (`SharedPreferences`).
  - Profile Management: Update display name, change password, upload avatar via Camera/Gallery.
  - Dynamic Backend API & Socket endpoint switcher for testing on localhost / LAN / production.

- **💬 Real-Time Messaging**:
  - Live 1-to-1 direct peer chats and multi-member group channels.
  - Real-time message streaming via Socket.IO (`new_message`, `message_edited`, `message_deleted`, `message_read`).
  - Read receipts (`✓` Sent, `✓✓` Read in Emerald).
  - Media attachments (Images with full-screen zoom, Documents & file download, Audio wave playback).
  - Voice note recording with live timer and AAC encoding.
  - Quotation reply previews & inline message editing.
  - Live typing indicators & real-time online presence status badges.

- **📞 WebRTC Voice & Video Calling**:
  - Real-time signaling over Socket.IO (`call_user`, `incoming_call`, `call_offer`, `answer_call`, `call_answered`, `reject_call`, `ice_candidate`, `end_call`).
  - Full-screen HD video call & voice call interface.
  - Floating Picture-in-Picture (PIP) local camera view.
  - In-call floating controls: Microphone Mute/Unmute, Camera On/Off, Front/Back Camera flip, Hang Up.
  - Global incoming call popup dialog with ringing animations and Accept / Decline actions.

---

## 📁 Architecture Overview

```
lib/
├── config/
│   └── constants.dart         # Backend URL, Socket URL, WebRTC ICE STUN/TURN configuration
├── models/
│   ├── user_model.dart        # User profile, presence, and auth models
│   ├── room_model.dart        # Chat room (1-to-1 & Group) and members
│   ├── member_model.dart      # Room member & admin role model
│   ├── message_model.dart     # Message, attachment, reply quote models
│   └── call_model.dart        # WebRTC call state, participant, and incoming call models
├── services/
│   ├── api_service.dart       # Dio HTTP client with JWT interceptor & error handling
│   ├── auth_service.dart      # User auth & profile REST endpoints (/api/v1/users)
│   ├── chat_service.dart      # Room & member REST endpoints (/api/v1/chat/rooms)
│   ├── message_service.dart   # Message & multipart file endpoints (/api/v1/chat/messages)
│   ├── socket_service.dart    # Socket.IO client with event dispatching
│   └── webrtc_service.dart    # WebRTC PeerConnection, Local/Remote streams & media controls
├── providers/
│   ├── auth_provider.dart     # Authentication state & persistent session management
│   ├── chat_provider.dart     # Chat rooms, message stream, typing, and actions
│   ├── socket_provider.dart   # Socket connection & online presence tracker
│   └── call_provider.dart     # WebRTC call signaling, status, and device actions
├── ui/
│   ├── screens/
│   │   ├── landing_screen.dart       # Hero landing page
│   │   ├── login_screen.dart         # Login screen
│   │   ├── register_screen.dart      # Registration screen
│   │   ├── verify_email_screen.dart  # Email verification screen
│   │   ├── home_screen.dart          # Main conversation list & adaptive shell
│   │   ├── chat_screen.dart          # Chat conversation view with rich attachments
│   │   ├── call_screen.dart          # WebRTC video/audio calling screen
│   │   └── profile_screen.dart       # Profile & endpoint configuration
│   ├── widgets/
│   │   ├── custom_avatar.dart        # Avatar with fallback initials & online status badge
│   │   ├── message_bubble.dart       # Message bubble with media previews & reply quotes
│   │   ├── audio_wave_player.dart    # Voice note wave player
│   │   ├── voice_record_bar.dart     # Voice note recorder with timer
│   │   ├── incoming_call_dialog.dart # Global incoming call overlay modal
│   │   ├── new_chat_dialog.dart      # Start direct chat & create group modal
│   │   └── group_info_sheet.dart     # Group members & admin controls
│   └── theme/
│       └── app_theme.dart            # Slate 950 & Emerald dark design system
└── main.dart                         # MultiProvider setup & AuthGate entry point
```

---

## ⚡ Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run App**:
   ```bash
   flutter run
   ```

3. **Backend Configuration**:
   - Backend endpoints are loaded dynamically from [`.env`](.env) with fallback to [`lib/config/constants.dart`](lib/config/constants.dart):
     ```env
     API_URL=https://195.35.6.141
     SOCKET_URL=https://195.35.6.141
     ```

4. **Generate App Launcher Icons**:
   - If you update [`assets/icon/app_icon.png`](assets/icon/app_icon.png), regenerate the Android & iOS launcher icons with:
     ```bash
     dart run flutter_launcher_icons
     ```

---

## 📦 Building for Production (Release)

### 🤖 Android Release Build

> [!TIP]
> **Why is the default release APK large (~87 MB)?**
> `flutter build apk --release` generates a **"FAT APK"** containing native C++ binaries (especially WebRTC) for **all 4 CPU architectures** (`arm64-v8a`, `armeabi-v7a`, `x86_64`, `x86`) in a single bundle.
> To produce lightweight **~25-30 MB APKs**, use the **Split per-ABI** command below.

1. **Recommended: Optimized Split per-ABI APKs** (~25–30 MB each):
   ```bash
   flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
   ```
   *Outputs*:
   - `app-arm64-v8a-release.apk` (For 99% of modern Android smartphones)
   - `app-armeabi-v7a-release.apk` (For older 32-bit Android phones)
   - `app-x86_64-release.apk` (For 64-bit Emulators / Tablets)

2. **Universal APK** (Single fat APK that installs on any Android device, ~70-80 MB):
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
   ```
   *Output file*: `build/app/outputs/flutter-apk/app-release.apk`

3. **Google Play App Bundle (AAB)** (Recommended for Play Store — Google automatically serves the smallest APK per device):
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
   ```
   *Output file*: `build/app/outputs/bundle/release/app-release.aab`


---

### 🍏 iOS Release Build (macOS with Xcode required)

1. **Build iOS Release Runner**:
   ```bash
   flutter build ios --release
   ```

2. **Build iOS IPA / Archive** (For TestFlight & App Store distribution):
   ```bash
   flutter build ipa --release
   ```
   *Output directory*: `build/ios/archive/` & `build/ios/ipa/`

3. **Open in Xcode for Manual Signing & Archiving**:
   ```bash
   open ios/Runner.xcworkspace
   ```
   - In Xcode: Go to **Product > Archive** to validate and upload to App Store Connect / TestFlight.

