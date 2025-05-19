# Travely

Travely is an iOS app for planning and sharing trips, with collaborative features, push notifications, and location-based reminders. This README will guide you through setting up, building, and running the app on your local machine.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Setup Instructions](#setup-instructions)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Install Dependencies](#2-install-dependencies)
  - [3. Create a Firebase Project](#3-create-a-firebase-project)
  - [4. Add GoogleService-Info.plist](#4-add-googleservice-infoplist)
  - [5. Configure Secrets.xcconfig](#5-configure-secretsxcconfig)
  - [6. Configure Info.plist for API Keys](#6-configure-infoplist-for-api-keys)
  - [7. Open and Build the Project](#7-open-and-build-the-project)
- [Push Notifications Setup](#push-notifications-setup)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

- User authentication (Email/Password, Google Sign-In)
- Trip creation, collaboration, and sharing
- Push notifications for trip events and reminders
- Location-based reminders
- Secure storage of API keys and secrets

---

## Requirements

- **macOS:** 13.0 (Ventura) or later recommended
- **Xcode:** 15.0 or later
- **iOS Deployment Target:** 16.0 or later
- **Apple Developer Account:** Required for push notifications on real devices
- **Swift Package Manager:** For [Firebase](https://github.com/firebase/firebase-ios-sdk) and [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) SDK integration

---

## Setup Instructions

### 1. Clone the Repository

```sh
git clone https://github.com/Jaysuun01/Travely.git
cd Travely
```

### 2. Install Dependencies

- The app uses Firebase iOS and GoogleSignIn iOS SDKs. You can use either CocoaPods or Swift Package Manager (SPM).

#### Using Swift Package Manager (Recommended):

1. Open the project in Xcode.
2. Go to **File > Add Packages...**
3. Enter `https://github.com/firebase/firebase-ios-sdk.git` and add the following products:
   - FirebaseAuth
   - FirebaseFirestore
   - GoogleSignIn

### 3. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and follow the steps.
3. Add an iOS app to your Firebase project:
   - Use your app's bundle identifier (e.g., `com.travely.travely`).
4. Download the generated `GoogleService-Info.plist` file.

### 4. Add GoogleService-Info.plist

- Place the `GoogleService-Info.plist` file in the root of your Xcode project (ensure it is included in the app target).

### 5. Configure Secrets.xcconfig

- Go to `https://www.api-ninjas.com/` and create an account
- After creating account, then sign in and go to `https://www.api-ninjas.com/profile` and click "Show API KEY" to get your API key
- Create a file named `Secrets.xcconfig` in your project root (if not already present).
- Add your Airport API key (from api-ninja ):
  ```
  AIRPORT_API_KEY=your_airport_api_key_here
  ```
- **Do NOT commit your real API keys to version control.**

### 6. Configure Info.plist for API Keys

- In your `Info.plist`, add a key for the Airport API:
  ```xml
  <key>AIRPORT_API_KEY</key>
  <string>$(AIRPORT_API_KEY)</string>
  ```
- This allows you to reference the key securely from your code.

### 7. Open and Build the Project

1. Open `Travely.xcodeproj` in Xcode.
2. Select your target device or simulator.
3. Build and run the app.

---

## Troubleshooting

- **API key not found?**
  - Ensure `Secrets.xcconfig` is included in your build settings under `Swift Compiler - Custom Flags` and `Info.plist` references the key as `$(AIRPORT_API_KEY)`.

---

## License

This project is for educational and demonstration purposes. Please do not use real API keys or secrets in public repositories.
