# UniRide - University Bus Reservation & Smart Transport System

UniRide is an intelligent university bus seat reservation and transport planning application built with Flutter, integrated with Gemini AI for AI-powered trip recommendations, smart scheduling, demand prediction, and role-based assistance.

---

## 🌟 Key Features

### 🎓 1. Student Experience
- **AI-Powered Trip Planning**: Recommends bus lines tailored to university, destination, current timetable, and seat availability.
- **Seat & Standing Spot Reservations**: Real-time visual seat map supporting seated reservations and authorized standing spot reservations.
- **QR Code Boarding Pass**: Instant QR code generation with seat assignment, real-time status tracking, and boarding validation.
- **Cancellation Policy**: Transparent cancellation rules with smart warning system for repeated cancellations.
- **Demand-Based Extra Bus Allocation**: When scheduled buses are fully booked, students can request an extra bus. When requests reach ≥ 15 passengers for shared stops, university dispatchers receive an instant alert to deploy an additional bus.
- **AI Transport Chatbot**: Real-time conversational agent capable of answering schedules, route tips, bus policies, and peak hours.

### 🚍 2. Driver Portal
- **Trip Operations & Live Status**: Update trip phase (scheduled, boarding, in transit, completed).
- **In-App QR Ticket Scanner**: Validates boarding passes with instant seat check and audio/visual confirmation.
- **Real-Time Passenger Manifest**: View boarded vs. pending seated and standing students.
- **Emergency / Delay Reporting**: Broadcast delay or route obstruction notifications to affected riders.

### 🛡️ 3. Administration & Dispatcher Dashboard
- **Live Fleet Overview**: Track active buses, occupancies, and operational statuses across campus routes.
- **Demand Surge Alerts**: Triggered when ≥ 15 students request a bus on the same route, enabling 1-tap bus deployment.
- **Penalty & Compliance Management**: Review repeated cancellations and enforce reservation policy.
- **AI Schedule & Demand Predictor**: Predict peak demand hours and optimize future route allocations.

---

## 🏗️ Architecture & Tech Stack

- **Frontend**: Flutter 3.x (Dart), Provider (State Management), Google Fonts, Lucide & Material Icons, QR Flutter, Mobile Scanner.
- **AI Engine**: Google Gemini API (`@google/genai` on Node.js proxy server & client-side integration).
- **Backend Proxy**: Express.js server (`unibus-backend`) with role-based system prompts (Student, Driver, Admin).
- **Local Storage**: SharedPreferences for offline persistence, preferences, mock session caches.

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.16+)
- [Node.js](https://nodejs.org/) (v18+)

### 2. Start the AI Backend
```bash
cd unibus-backend
npm install
# Set your GEMINI_API_KEY in unibus-backend/.env
npm start
```
The AI backend runs on `http://localhost:3000`.

### 3. Run the Flutter App
```bash
flutter pub get
flutter run
```

---

## 🧪 Testing & Validation
Run automated widget and unit tests:
```bash
flutter test
```
Run Dart code analysis:
```bash
flutter analyze
```
