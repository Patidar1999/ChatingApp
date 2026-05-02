# 💬 Flutter Chat App

A beginner-friendly, production-ready chat application built with **Flutter** and **Firebase** — perfect for interview demonstrations and learning real-world app architecture.

---

## 📱 Screenshots

```
Login Screen → OTP Verify → Profile Setup → Home (Chats) → Chat Room → Profile
```

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔐 Phone Auth | OTP-based login via Firebase Authentication |
| 💾 Persistent Session | Stays logged in — no repeated logins |
| 👤 User Profile | Update name and profile photo |
| 📞 Device Contacts | Browse your phone's contact list |
| 💬 Real-Time Chat | 1-to-1 messaging powered by Firestore |
| 🕓 Chat History | All messages stored & retrievable forever |
| ✅ Read Receipts | Blue/grey double-tick indicator |
| 📅 Date Labels | Messages grouped by date |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter 3.x (Dart) |
| **Authentication** | Firebase Auth (Phone/OTP) |
| **Database** | Firebase Firestore (Real-Time) |
| **File Storage** | Firebase Storage |
| **Contact Access** | flutter_contacts |
| **Image Picker** | image_picker |

---

## 🗂️ Folder Structure

```
lib/
├── main.dart                     ← App entry point + auth gate
│
├── models/                       ← Data models (Plain Dart classes)
│   ├── user_model.dart           ← User profile data
│   ├── message_model.dart        ← Single chat message
│   └── chat_room_model.dart      ← Conversation metadata
│
├── services/                     ← Firebase logic (business layer)
│   ├── auth_service.dart         ← Phone OTP login/logout
│   ├── user_service.dart         ← Profile read/write/photo upload
│   ├── chat_service.dart         ← Send/receive messages (real-time)
│   └── contacts_service.dart     ← Device contact access
│
├── screens/                      ← UI pages
│   ├── auth/
│   │   ├── login_screen.dart     ← Phone number input
│   │   ├── otp_screen.dart       ← OTP verification
│   │   └── setup_profile_screen.dart  ← First-time name/photo setup
│   ├── home/
│   │   └── home_screen.dart      ← Conversations list
│   ├── chat/
│   │   ├── contacts_screen.dart  ← Pick a contact to chat
│   │   └── chat_screen.dart      ← Real-time 1-to-1 chat
│   └── profile/
│       └── profile_screen.dart   ← View & edit your profile
│
├── widgets/                      ← Reusable UI components
│   ├── message_bubble.dart       ← Chat bubble (sent/received)
│   └── chat_list_tile.dart       ← Home screen conversation row
│
└── utils/                        ← Helpers & constants
    ├── app_theme.dart            ← Colors, fonts, button styles
    └── app_constants.dart        ← Firestore paths, helper functions
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0` ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Firebase CLI (`npm install -g firebase-tools`)
- A Google Firebase account

---

### Step 1 — Clone the Project

```bash
git clone https://github.com/your-username/flutter_chat_app.git
cd flutter_chat_app
```

---

### Step 2 — Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project** → name it `flutter-chat-app`
3. Enable these services:
   - **Authentication** → Phone
   - **Firestore Database** → Start in test mode
   - **Storage** → Start in test mode

---

### Step 3 — Add Firebase to Flutter

Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

Configure your app:
```bash
flutterfire configure
```

This auto-generates `lib/firebase_options.dart` and updates `main.dart`.

Update `main.dart` initialization:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

### Step 4 — Android Setup

Add your SHA-1 key for Phone Auth (required):
```bash
cd android
./gradlew signingReport
```

Copy the **SHA-1** from output and add it in:
`Firebase Console → Project Settings → Your Android App → Add fingerprint`

---

### Step 5 — Deploy Security Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

Or copy the rules manually from `firestore.rules` and `storage.rules` into your Firebase Console.

---

### Step 6 — Install Dependencies

```bash
flutter pub get
```

---

### Step 7 — Run the App

```bash
flutter run
```

---

## 🔥 Firestore Data Structure

```
Firestore
├── users/
│   └── {uid}/
│       ├── uid: "abc123"
│       ├── phone: "+919876543210"
│       ├── name: "John Doe"
│       ├── photoUrl: "https://..."
│       └── createdAt: Timestamp
│
└── chats/
    └── {chatRoomId}/              ← phone1_phone2 (sorted)
        ├── chatRoomId: "..."
        ├── participants: [uid1, uid2]
        ├── lastMessage: "Hey!"
        ├── lastMessageTime: Timestamp
        ├── lastMessageSenderId: "uid1"
        └── messages/
            └── {messageId}/
                ├── messageId: "uuid"
                ├── senderId: "uid1"
                ├── receiverId: "uid2"
                ├── content: "Hello!"
                ├── type: "text"
                ├── sentAt: Timestamp
                └── isRead: false
```

---

## 🧑‍💻 Key Concepts for Interviewers

| Concept | Where Used |
|---|---|
| **StreamBuilder** | Real-time message updates, auth state |
| **FutureBuilder** | Loading user profiles |
| **Firebase Batch Writes** | Atomic message + chat room update |
| **Clean Architecture** | Models / Services / Screens / Widgets separation |
| **Navigation** | `pushAndRemoveUntil` for auth flow |
| **State Management** | `setState` (beginner-appropriate) |
| **Security Rules** | Per-user data protection in Firestore & Storage |

---

## 🔧 Customization

- **Country code**: Change `+91` in `contacts_service.dart` to your country
- **Theme colors**: Edit `lib/utils/app_theme.dart`
- **Add image messages**: Extend `MessageType` enum + upload to Storage

---

## 📄 License

MIT License — free to use, modify, and distribute.
