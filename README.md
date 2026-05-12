# ☕ Grace Coffee House

> **A beautifully crafted mobile app for discovering and ordering from your favorite local coffee shop — built with Flutter.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow?style=flat)

---

## 📖 About

**Grace Coffee House** is a cross-platform mobile application that lets customers browse the menu, customize their orders, and stay connected with their favorite coffee shop — all from their phone. Designed with a warm, modern UI, the app brings the cozy coffee shop experience to the digital world.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| State Management | Provider / Riverpod |
| Backend | Firebase (Firestore + Auth) |
| UI Components | Material 3 |
| Local Storage | shared_preferences |

---

## ✨ Features

- **Menu Browsing** — Browse drinks and food items by category with photos and descriptions
- **Order Customization** — Customize drink size, milk type, and add-ons before adding to cart
- **User Authentication** — Sign up and log in via Firebase Auth (email/password)
- **Shopping Cart** — Add, remove, and review items before checkout
- **Order History** — View past orders stored in Firestore
- **Responsive UI** — Adapts cleanly to different Android and iOS screen sizes

---

## 📱 Screenshots

> *Add screenshots here once the UI is complete — drag images into this section on GitHub.*

| Home Screen | Menu Page | Cart |
|---|---|---|
| `screenshot_home.png` | `screenshot_menu.png` | `screenshot_cart.png` |

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed before cloning:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **v3.0 or higher**
- [Dart SDK](https://dart.dev/get-dart) (comes bundled with Flutter)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/) (for running on a simulator/emulator)
- A Firebase project (see Environment Variables section below)

Verify your Flutter setup is ready:
```bash
flutter doctor
```

---

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/gracecoffeehouse.git
cd gracecoffeehouse
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Set up environment variables** *(see next section)*

**4. Run the app**
```bash
# On a connected device or running emulator:
flutter run

# To run on a specific platform:
flutter run -d android
flutter run -d ios
```

---

### 🔑 Environment Variables

This project uses Firebase. You'll need to connect your own Firebase project:

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a new project
2. Add an **Android** and/or **iOS** app to your Firebase project
3. Download the config files and place them in the correct directories:

| File | Location |
|---|---|
| `google-services.json` | `android/app/google-services.json` |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

> ⚠️ **Never commit these files to GitHub.** They are already listed in `.gitignore`.

If the project uses a `.env` file for any additional keys, create one at the root:
```
# .env
API_BASE_URL=https://your-api-url.com
SOME_OTHER_KEY=value
```

---

## 📲 How to Use the App

Once the app is running on your device or emulator:

1. **Create an account** or log in on the welcome screen
2. **Browse the menu** by scrolling through categories on the Home tab
3. **Tap any item** to see its details and customization options
4. **Add to cart** using the button on the item detail page
5. **Review your cart** from the Cart tab and adjust quantities
6. **Place your order** by tapping "Checkout" — your order is saved to Firestore

---

## 🤝 Contributing

Contributions are welcome! Here's how to get involved:

**1. Fork the repository**

Click the **Fork** button at the top right of this page.

**2. Create a feature branch**
```bash
git checkout -b feature/your-feature-name
```

**3. Make your changes and commit**
```bash
git add .
git commit -m "feat: add your feature description"
```

**4. Push your branch**
```bash
git push origin feature/your-feature-name
```

**5. Open a Pull Request**

Go to the original repo on GitHub and click **"New Pull Request"**. Describe what your PR does and link any relevant issues.

> Please make sure your code runs without errors (`flutter run`) before submitting.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

You are free to use, copy, modify, and distribute this project, as long as the original license is included.

---

*Made with ❤️ and a lot of coffee.*
