
# 🌌 TaskOrbit

[![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.22-blue)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Made with ❤️](https://img.shields.io/badge/Made%20with-%E2%9D%A4-red)](https://github.com/moizsahto)

A beautiful and highly interactive Flutter task manager app with real-time filtering, priority-based task separation, and stunning animations like shimmer and glassmorphism.

---

## ✨ Features

- 🧠 Filter tasks by **category** or **priority**
- ✅ Toggle **completion status** with visual feedback
- 🎨 Shimmer loading effects
- 💎 Glassmorphic UI panels
- 🗂 SQLite local storage for offline access
- 🔁 State managed with **Provider**
- 🚀 Smooth splash screen & transitions with animations

---

## 📸 Screenshots

| Splash Screen | Task List | Add/Edit Task |
|---------------|------------|----------------|
| ![Splash](assets/screenshots/splash.png) | ![TaskList](assets/screenshots/taskList.png) | ![AddEdit](assets/screenshots/taskAdd.png) |

> ℹ️ To add your screenshots:  
> 1. Run the app  
> 2. Capture using emulator or real device  
> 3. Save in `assets/screenshots/` and link above.

---

## 🚀 Getting Started

### 1. Clone the Repo

```bash
git clone https://github.com/your-username/taskorbit.git
cd taskorbit
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

---

## 🧪 Optional: Auto-Screenshot Integration Test

Create a test file at: `integration_test/screenshot_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taskorbit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Take UI screenshots", (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.binding.takeScreenshot('assets/screenshots/splash.png');

    // Navigate to Task List (if needed) and take more screenshots
  });
}
```

Then run:

```bash
flutter test integration_test/screenshot_test.dart
```

---

## 📂 Folder Structure (Simplified)

```
lib/
├── main.dart
├── models/
│   └── task.dart
├── providers/
│   └── task_provider.dart
├── screens/
│   ├── splash_screen.dart
│   └── task_list_screen.dart
├── services/
│   └── database_service.dart
├── widgets/
│   ├── task_card.dart
│   └── glass_panel.dart
assets/
└── screenshots/
```

---

## 📃 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙌 Contributions

Pull requests are welcome. For major changes, please open an issue first to discuss what you’d like to change.

Made with ❤️ by [Moiz Sahto](https://github.com/moizsahto)
