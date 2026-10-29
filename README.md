# RideGo — Samar & Leyte Transportation Management System

RideGo is a multi-tenant transportation and vehicle booking management platform built for Samar and Leyte, Philippines. The system serves passengers commuting along the Pan-Philippine Highway (AH26) between **Catbalogan City**, **Tacloban City**, **Calbayog City**, and all intermediate municipalities.

---

## 1. Overview & Key Capabilities

RideGo provides specialized portals for three distinct user roles:

1. **Customers (Passengers)**:
   - Search inter-city routes with municipality-level pickup and dropoff points.
   - Filter by vehicle category (Vans, Buses, Motorcycles/Habal-habal).
   - Authoritative, real-time fare calculation (base rate + intermediate segment steps + terminal fee).
   - Real-time seat reservation with atomic concurrency locks.
   - Cash on Board reservation with digital boarding passes and QR codes.
   - Live booking updates via Supabase Realtime.

2. **Vehicle Operators & Fleet Managers**:
   - Operator registration, business permit submission, and identity verification.
   - Vehicle fleet management (specs, plate numbers, seating capacity, photo uploads).
   - Route scheduling, recurring departures, and bookable passenger slots.
   - Real-time boarding manifest with one-click cash payment confirmation.
   - Operational revenue metrics distinguishing total booked volume from collected cash.

3. **Platform Administrators**:
   - Web-optimized operations control center.
   - Verification and approval workflow for new operator applications.
   - Global transit corridor and municipality stop configuration.
   - Live fare rule editing (base fares, per-segment rates, terminal surcharges).
   - Real-time platform oversight, cash collection tracking, and audit logs.

---

## 2. Technology Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend Framework** | Flutter 3.47.8 / Dart 3.13.7 | Cross-platform (Android, iOS, Web) |
| **State Management** | Flutter Riverpod | Clean, testable, reactive state providers |
| **Navigation & Routing** | `go_router` | Declarative routing with deep linking & role-based route guards |
| **Backend & Database** | Supabase PostgreSQL | Stored procedures (RPC), triggers, and Row Level Security (RLS) |
| **Authentication** | Supabase Auth | JWT-based auth with backend role claims |
| **Real-Time Engine** | Supabase Realtime | WebSocket publications on bookings and notifications |
| **File Storage** | Supabase Storage | Public bucket for vehicle photos and operator credentials |
| **Maps & Transit** | `flutter_map` / OpenStreetMap | Regional coordinates for Samar and Leyte stops |
| **Testing** | Flutter Test / PostgreSQL | 30/30 unit, widget, and integration tests passing |

---

## 3. Architecture & Directory Structure

RideGo follows a **Feature-First Architecture** with strict layer separation:

```text
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp with theme & router
│   ├── router/router.dart         # go_router declarative route definitions & guards
│   └── theme/                     # AppTheme, Figma color tokens, typography
├── core/
│   ├── config/supabase_config.dart # Compile-time defines & Supabase client wrapper
│   ├── constants/app_colors.dart  # Figma design system colors
│   └── widgets/ridego_logo.dart   # Custom vector shield & bubble RideGo logo
├── features/
│   ├── admin/                     # Admin dashboard, operator approvals & metrics
│   ├── auth/                      # Authentication screens, models & Riverpod providers
│   ├── bookings/                  # Booking flow, real-time locking & passenger manifests
│   ├── customer/                  # Customer home, shell, and category views
│   ├── notifications/             # In-app notification center & real-time listeners
│   ├── operator/                  # Operator dashboard, fleet management & approvals
│   ├── pricing/                   # Pricing service, fare models & rate recalculation
│   ├── profile/                   # User profile & account settings
│   ├── routes/                    # Municipality stop sequencing & corridor definitions
│   ├── search/                    # Search repository, filter chips & search results
│   └── vehicles/                  # Vehicle models, repositories & details views
supabase/
├── migrations/                    # 5 production SQL migrations with RLS & RPCs
└── tests/                         # PostgreSQL security & constraint tests
test/                              # 30 automated Flutter unit & integration tests
docs/                              # Comprehensive technical documentation
```

---

## 4. Setup & Installation

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.24.0 or higher recommended)
- Android Studio / Android SDK (for Android builds) or Chrome (for Web)
- A Supabase project (cloud or self-hosted)

### Clone & Install Dependencies
```bash
git clone https://github.com/ushalabs/RideGo.git
cd RideGo
flutter pub get
```

### Configuration
Create a `config.dev.json` file in the project root:
```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_ID.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_ANON_KEY"
}
```
*(Note: If placeholder credentials are used, RideGo automatically boots in high-fidelity demo fallback mode for offline testing.)*

---

## 5. Database Setup (Supabase)

To apply the database schema, run the migrations in sequential order via the Supabase SQL Editor:

1. `supabase/migrations/20261030000001_auth_and_roles.sql` (Profiles, roles, operators)
2. `supabase/migrations/20261030000002_vehicles_and_routes.sql` (18 stops, corridors, vehicles, schedules)
3. `supabase/migrations/20261030000003_search_and_pricing.sql` (Fare calculation RPC & search)
4. `supabase/migrations/20261030000004_realtime_booking_engine.sql` (Atomic bookings & pessimistic locks)
5. `supabase/migrations/20261030000005_dashboards_and_notifications.sql` (Notifications & metrics)

To bootstrap your administrator account:
```sql
SELECT bootstrap_admin('your-admin-email@example.com');
```

For detailed manual setup instructions, see [docs/MANUAL_SETUP.md](docs/MANUAL_SETUP.md).

---

## 6. Running the Application

### Launching on Mobile (Android / iOS):
```bash
flutter run --dart-define-from-file=config.dev.json
```

### Launching on Web (Chrome):
```bash
flutter run -d chrome --dart-define-from-file=config.dev.json
```

---

## 7. Quality Assurance & Testing

Run all automated unit, widget, and integration test suites:
```bash
flutter test
```

Run static code analysis:
```bash
flutter analyze
```

Check code formatting:
```bash
dart format --output=none --set-exit-if-changed .
```

---

## 8. Security & Concurrency Design

- **Zero Privileged Secrets**: Only the publishable Supabase anon key is exposed to client binaries.
- **Row Level Security (RLS)**: Enforced across all tables. Administrative actions are validated strictly via backend functions (`is_admin()`).
- **Pessimistic Concurrency Locking**: The `create_booking_atomic` RPC uses PostgreSQL `SELECT ... FOR UPDATE` row locks to prevent overselling on the last available seats.
- **Idempotency Protection**: Every client checkout request includes a unique client-generated UUID idempotency key to prevent double-charges on network retries.

---

## 9. Technical Documentation Index

- [Figma Parity Guide](docs/FIGMA_PARITY.md): Verification of Figma visual design tokens, screens, and components.
- [System Architecture](docs/ARCHITECTURE.md): Multi-role architecture, state management, and real-time event pipeline.
- [Database Schema & Stored Procedures](docs/DATABASE.md): Tables, relationships, RLS policies, and RPC definitions.
- [Route Catalog & Corridors](docs/ROUTES.md): Samar and Leyte municipality sequence, distances, and pricing formulas.
- [Testing & Concurrency Verification](docs/TESTING.md): Test suite matrix, coverage, and race condition benchmarks.
- [Supabase Manual Setup](docs/MANUAL_SETUP.md): Step-by-step SQL Editor setup, storage buckets, and realtime configuration.
- [Deployment Guide](docs/DEPLOYMENT.md): Android APK release builds, Play Store signing, and Flutter Web hosting.
- [Final Acceptance Matrix](docs/FINAL_ACCEPTANCE.md): 23-step end-to-end user journey verification matrix.

---

## 10. License & Author

Developed for **RideGo Transportation System** (Samar and Leyte, Philippines). All rights reserved.
