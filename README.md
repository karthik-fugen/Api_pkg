# flutter_api_inspector

A powerful debugging toolkit for Flutter applications that automatically inspects API activity. 

`flutter_api_inspector` provides automatic request logging, error detection, schema change monitoring, performance profiling, and a visual debugging dashboard directly inside your app. It helps developers quickly detect API bugs, backend inconsistencies, and performance bottlenecks without manually writing logging code.

---

## 🚀 Main Features

### 📡 Advanced API Logging
Automatically intercepts and logs all outgoing API requests and incoming responses with deep diagnostics:
*   **Request Details:** Method, Full URL, Headers (masked), Query Parameters, and Request Body.
*   **Response Details:** Status Code, Headers, Pretty-printed Body, Size, and Duration.
*   **CURL Command Generation:** Automatically generates a reproducible `curl` command for every request.
*   **Sensitive Data Masking:** Automatically hides sensitive headers like `Authorization`, `API-Key`, and `Password`.
*   **Heatmap Timing:** Visual ASCII performance bars in the terminal.
*   **Rapid-Fire Detection:** Warns if an API is called too many times in a short interval (<200ms).

### 🧠 Smart Error Detection & Schema Intelligence
Detects common API issues automatically:
*   **Automatic Schema Learning:** Remembers response structures and alerts on **Breaking Changes**.
*   **Type Mismatches:** Warns when a field's type differs from the expected model.
*   **Null & Missing Fields:** Detects when required keys are absent or null.

### 📊 Performance Profiler & Session Recorder
*   **Metrics:** Monitor average response times and slowest endpoints.
*   **Timeline:** View a chronological history of all network calls.
*   **Recording:** Capture full API sessions and export them as **JSON** for sharing.

### 🛠 Visual Debug Dashboard (In-App)
A floating, draggable **Smart Button** (visible across all pages) shows live response times and error badges. Open the dashboard to search logs, replay requests, or copy CURLs.

---

## 📦 Installation

Add `flutter_api_inspector` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter_api_inspector: ^1.0.0
```

---

## ⚡️ Quick Start (2-Step Setup)

### 1. Configure your App
Initialize the inspector and wrap your app using the `builder` pattern. This ensures the floating button is **visible on every page**.

```dart
import 'package:flutter_api_inspector/flutter_api_inspector.dart';

void main() {
  APIInspector.initialize(showInRelease: true); // Enable for QA builds
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Essential for global navigation and visibility
      navigatorKey: APIInspector.navigatorKey, 
      builder: (context, child) => APIInspector.wrap(child!),
      home: const HomePage(),
    );
  }
}
```

### 2. Attach to your Dio Client
Simply attach the inspector to your `Dio` instance:

```dart
final dio = Dio();
APIInspector.attach(dio);
```

---

## 🛠 Advanced Features

### API Request Replay
Tapping a request in the dashboard allows you to **Replay** it instantly using the same headers and body.

### Mock API Responses
Bypass the network by registering static mocks for any endpoint:
```dart
APIInspector.mockResponse("/users", {"id": 1, "name": "Mock User"});
```

### Clipboard Sharing
*   **Copy CURL:** Copy a failing request to paste into terminal or Postman.
*   **Copy Full Log:** Share complete diagnostics via Slack or Email.

---

## 📱 In-App Dashboard Tabs

1.  **Logs:** Filterable list of all activity with a built-in **Search Bar**.
2.  **Performance:** Analytics on slow endpoints and a text-based timeline.
3.  **Session:** Controls for recording and exporting JSON session files.

---

## 📄 License

This project is licensed under the MIT License.
