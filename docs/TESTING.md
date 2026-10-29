# RideGo Quality Assurance & Testing Suite

This document outlines the testing architecture, automated test suites, execution commands, security validation, and concurrency stress testing for the RideGo transportation platform.

---

## 1. Test Suite Summary

RideGo enforces test coverage across all architectural layers: data models, business repositories, pricing engines, state providers, widget trees, integration flows, and PostgreSQL stored procedures.

### Summary of Executed Automated Tests

| Test File | Test Layer | Tests | Status |
|---|---|---|---|
| `test/widget_test.dart` | Flutter UI & Smoke Testing | 1 | Passed |
| `test/auth_test.dart` | Authentication, Profiles & Role Escalation | 5 | Passed |
| `test/vehicle_route_test.dart` | Fleet Management, Routes & Corridors | 4 | Passed |
| `test/pricing_search_test.dart` | Search Querying & Authoritative Pricing | 7 | Passed |
| `test/booking_engine_test.dart` | Real-Time Booking & Concurrency Locks | 5 | Passed |
| `test/dashboard_notification_test.dart` | Analytics, Cash Ledger & Notifications | 4 | Passed |
| `test/e2e_integration_test.dart` | End-to-End User Journeys & Concurrency | 4 | Passed |
| **Total Flutter Test Suite** | **All Layers** | **30** | **30 / 30 Passed (100%)** |
| `supabase/tests/auth_roles_test.sql` | PostgreSQL RLS & Schema Constraints | 7 | Verified |

---

## 2. Test Execution Commands

To execute the automated test suites locally:

```powershell
# 1. Run full Flutter automated test suite
$env:PATH = "C:\development\flutter\bin;$env:PATH"
flutter test

# 2. Run specific test suites with verbose output
flutter test test/e2e_integration_test.dart -v
flutter test test/booking_engine_test.dart -v
flutter test test/pricing_search_test.dart -v

# 3. Static analysis check
flutter analyze

# 4. Code formatting verification
dart format --output=none --set-exit-if-changed .
```

---

## 3. Detailed Test Breakdown

### 3.1 Authentication & Security (`test/auth_test.dart`)
- **Profile Serialization**: Validates JSON deserialization and serialization of `UserProfile` and `OperatorProfile` models.
- **Client Privilege Rejection**: Verifies that clients cannot escalate privileges to `administrator` or `operator` locally without backend trigger authorization.
- **Role Permissions**: Verifies strict permission matrices for `customer`, `operator`, and `administrator` roles.
- **Operator Verification Flow**: Validates transition logic from `pending_approval` to `approved` and `suspended`.

### 3.2 Vehicle & Route Management (`test/vehicle_route_test.dart`)
- **Fleet Modeling**: Tests vehicle registration, plate validation, and category categorization (`van`, `bus`, `motorcycle`, `car`).
- **Route Sequencing**: Verifies that intermediate municipality stops follow strict sequential ordering from Catbalogan to Tacloban and Catbalogan to Calbayog.
- **Schedule Conflict Prevention**: Verifies that a single vehicle cannot be booked for overlapping departure times.

### 3.3 Search & Authoritative Pricing (`test/pricing_search_test.dart`)
- **Authoritative Fare Formula**: Verifies formula $\text{Fare} = ((\text{Base} + (\text{Segments} \times \text{Rate})) \times \text{Passengers}) + \text{Terminal Fee}$.
- **Backward Segment Detection**: Rejects searches where destination stop index $\le$ origin stop index.
- **Private Vehicle Pricing**: Verifies flat-rate vehicle charter calculation without passenger multiplication.
- **Query Filter Logic**: Tests filtering by vehicle category, price bracket, and date range.

### 3.4 Booking Engine & Concurrency (`test/booking_engine_test.dart`)
- **Atomic Booking Creation**: Tests full booking payload generation, seat reservation, and QR code generation.
- **Pessimistic Locking (`SELECT FOR UPDATE`)**: Validates that concurrent attempts to book the last remaining seats on a schedule result in the second transaction failing gracefully with an `insufficient_capacity` error.
- **Idempotency Deduplication**: Confirms that submitting identical client booking requests with the same idempotency key prevents duplicate charges and double-booking.
- **Lifecycle Status State Machine**: Enforces valid status transitions:
  `pending` $\rightarrow$ `confirmed` $\rightarrow$ `completed`
  `pending` $\rightarrow$ `cancelled`

### 3.5 End-to-End User Journeys (`test/e2e_integration_test.dart`)
- **Customer Journey**: Registration $\rightarrow$ Route Discovery $\rightarrow$ Stop Selection $\rightarrow$ Real-Time Reservation $\rightarrow$ Cash on Board Confirmation $\rightarrow$ Review in Bookings List.
- **Operator Journey**: Registration $\rightarrow$ Document Submission $\rightarrow$ Pending Screen $\rightarrow$ Fleet & Schedule Management $\rightarrow$ Booking Acceptance $\rightarrow$ Passenger Roster.
- **Admin Journey**: Metric Dashboard Inspection $\rightarrow$ Operator Verification & Approval $\rightarrow$ System Audit Log Review $\rightarrow$ Route Configuration.
- **Race Condition Verification**: Validates race condition simulation for simultaneous multi-passenger checkout on shared vans.

---

## 4. PostgreSQL Security & RLS Validation

Row Level Security is configured across all tables (`profiles`, `operators`, `vehicles`, `schedules`, `bookings`, `notifications`, `audit_logs`).

The test file `supabase/tests/auth_roles_test.sql` verifies:
1. `anon` role cannot access private customer profiles or operator contact information.
2. `customer` can only view their own bookings and public schedule listings.
3. `operator` can only edit vehicles and schedules assigned to their operator ID.
4. `administrator` has read/write oversight across all tables via the `is_admin()` security definer function.
5. Direct `UPDATE` or `INSERT` on `profiles.is_admin` by regular users is blocked by RLS policies and table constraints.
