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
*   **Request ID Tracking:** Assigns unique IDs (e.g., `#123`) to link requests and responses clearly.

### 🧠 Smart Error Detection
Detects common API issues automatically:
*   **Slow APIs:** Warns when response times exceed thresholds.
*   **Invalid JSON:** Identifies malformed or unexpected response formats.
*   **Null Values:** Scans for unexpected null fields in JSON maps.
*   **Missing Fields:** Detects when required keys are absent.
*   **Type Mismatches:** Warns when a field's type differs from the expected model.

### 🔍 Schema Intelligence
Automatically learns API response structures and monitors for backend changes:
*   **New Field Detection:** Alerts when the backend adds new data.
*   **Removed Field Detection:** Alerts when previously existing fields disappear.
*   **Breaking Change Detection:** Identifies when field types change.

### 📊 Performance Profiler
Tracks critical endpoint metrics:
*   **Average Response Time:** Monitor the latency of specific endpoints.
*   **Slow Endpoint Ranking:** Identify your worst-performing APIs.
*   **API Timeline:** View a chronological history of all network calls.

### 🎬 Session Recorder
Record entire sequences of API activity and export them as a structured JSON file for sharing with backend teams or reproducing issues.

### 🛠 Visual Debug Dashboard
A floating, draggable debug button (visible only in debug mode) opens an in-app dashboard to inspect logs, performance, and sessions visually.

---

## 📦 Installation

Add `flutter_api_inspector` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter_api_inspector: ^1.0.0
```

---

## ⚡️ Quick Start

Initialize the inspector and wrap your application widget to enable the debug overlay. The overlay button will automatically appear only in **debug mode**.

```dart
import 'package:flutter_api_inspector/flutter_api_inspector.dart';

void main() {
  // 1. Initialize the inspector
  APIInspector.initialize();

  runApp(
    // 2. Wrap your app with the overlay
    APIInspector.wrap(
      const MyApp(),
    ),
  );
}
```

### Attaching to a Dio Client

To start inspecting activity, simply attach the inspector to your `Dio` instance:

```dart
final dio = Dio();
APIInspector.attach(dio);
```

After attaching, all requests made through this `dio` instance will be automatically analyzed and logged.

---

## 🛠 Advanced Usage

### Detailed Configuration
Customize the inspector's behavior during initialization:

```dart
APIInspector.initialize(
  enabled: true,                       // Enable/Disable the inspector
  enableSchemaLearning: true,          // Automatically learn API structures
  enableBreakingChangeDetection: true, // Alert on schema changes
  enableDetailedLogs: true,            // Capture headers, bodies, etc.
  enableCurlGeneration: true,          // Generate CURL commands
  enablePrettyResponse: true,          // Indent JSON responses
  maskSensitiveData: true,             // Mask Auth/API keys
);
```

### Manual Schema Validation
While the inspector learns schemas automatically, you can also register expected schemas for stricter validation:

```dart
// Register required fields
APIInspector.registerSchema("/users", ["id", "name", "email"]);

// Register expected field types
APIInspector.registerSchemaTypes("/users", {
  "id": int,
  "name": String,
});
```

### Session Recording & Export
Capture a full sequence of API calls to share with your team:

```dart
// Start recording
APIInspector.startSessionRecording();

// ... perform API calls ...

// Stop recording
APIInspector.stopSessionRecording();

// Export the session as a JSON string
final String jsonSession = APIInspector.exportSession();
```

---

## 📱 In-App Dashboard

The dashboard is divided into three functional tabs:

1.  **Logs:** A detailed list of all requests, responses, and warnings. Tapping an entry shows full diagnostics and the generated **CURL command**.
2.  **Performance:** Metrics showing the slowest endpoints and a chronological timeline of calls.
3.  **Session:** Controls for recording API sessions, viewing session summaries, and exporting logs to JSON.

---

## 🖼 Screenshots

| Debug Overlay | Log Dashboard | Performance Tab | Session Recorder |
| :---: | :---: | :---: | :---: |
| ![Overlay Placeholder] | ![Logs Placeholder] | ![Performance Placeholder] | ![Session Placeholder] |

---

## 💡 Use Cases

*   **API Integration:** Verify request/response payloads without using external proxy tools.
*   **Backend Monitoring:** Instantly detect when a backend deployment changes the API contract.
*   **Performance Tuning:** Identify which endpoints are slowing down your user experience.
*   **QA & Bug Reporting:** Export full API session logs to include in bug reports for 100% reproducible networking state.
*   **Production Development:** Debug issues in "staging" or "dev" builds directly on the device.

---

## 📄 License

This project is licensed under the MIT License.
