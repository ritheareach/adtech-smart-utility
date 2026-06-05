# ADTech Smart Utility Management

A Flutter mobile app for managing smart utility accounts — view usage, track bills, make payments, and receive notifications. Built with MVVM architecture and backed by a Node.js REST API.

---

## Features

- **Dashboard** — real-time usage summary, bill breakdown, and month-over-month change
- **Bills** — itemized bill history with status (paid / unpaid / overdue)
- **Usage** — data, voice, and SMS consumption charts by billing period
- **Payments** — pay outstanding bills via PayWay integration
- **Notifications** — payment due alerts and account activity feed

---

## Tech Stack

| Layer    | Technology                                      |
|----------|-------------------------------------------------|
| Mobile   | Flutter 3, Dart, Provider (MVVM)                |
| Charts   | fl_chart                                        |
| HTTP     | http package + JWT bearer tokens                |
| Backend  | Node.js, Express, PostgreSQL                    |
| Auth     | OTP login → JWT access + refresh tokens         |

---

## Project Structure

```
lib/
├── core/
│   ├── config/        # colors, constants
│   └── services/      # ApiService (HTTP client)
├── models/            # data classes (Bill, UsageData, Notification…)
├── viewmodels/        # ChangeNotifier VMs per feature
├── views/             # screens & tabs
└── widgets/           # shared UI components
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- A running instance of the adtech-api backend (see API setup below)

### Install & run

```bash
flutter pub get
flutter run
```

### Point to your API

In `lib/core/services/api_service.dart`, update `baseUrl` to match your backend host:

```dart
static const String baseUrl = 'http://localhost:3000';
```

---

## Backend API

The REST API is a Node.js/Express/PostgreSQL server. Quick setup:

```bash
cd adtech-api
cp .env.example .env        # fill in DB credentials and JWT_SECRET
npm install
npm run db:migrate
npm run db:seed
npm run dev                 # starts on port 3000
```

### Key endpoints

| Method | Path                    | Description              |
|--------|-------------------------|--------------------------|
| POST   | `/auth/request-otp`     | Send OTP to phone/email  |
| POST   | `/auth/verify-otp`      | Verify OTP, get JWT      |
| GET    | `/bills`                | List bills               |
| GET    | `/usage`                | Usage by period          |
| POST   | `/payments`             | Submit payment           |
| GET    | `/notifications`        | Notification feed        |

All protected routes require `Authorization: Bearer <token>`.

---

## License

Private — all rights reserved.
