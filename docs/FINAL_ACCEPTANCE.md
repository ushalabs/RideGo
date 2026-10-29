# RideGo — Final Acceptance & Verification Matrix

This document provides the complete end-to-end verification matrix testing the platform against the 23-step acceptance scenario specified in Section 7 of the RideGo master specification.

---

## Acceptance Test Matrix

| Step | Acceptance Scenario Description | Functional Component & Code Location | Verification Method | Status |
|---|---|---|---|---|
| **1** | Customer registers account with valid name, email, and password. | `RegisterScreen` (`lib/features/auth/presentation/register_screen.dart`), `AuthRepository.signUp` | `test/auth_test.dart`, `test/e2e_integration_test.dart` | **PASS** |
| **2** | Customer signs in securely with Supabase Auth credentials. | `LoginScreen` (`lib/features/auth/presentation/login_screen.dart`), `AuthRepository.signIn` | `test/auth_test.dart` | **PASS** |
| **3** | Customer sees personalized greeting ("Hello, Kiya" / profile name) on Home. | `CustomerHomeScreen` (`lib/features/customer/presentation/customer_home_screen.dart`), `currentUserProfileProvider` | `test/widget_test.dart`, `test/e2e_integration_test.dart` | **PASS** |
| **4** | Customer searches routes from Catbalogan to Tacloban along Southbound corridor. | `SearchRepository.searchTrips`, `search_available_trips` RPC | `test/pricing_search_test.dart` | **PASS** |
| **5** | Customer filters available trips by category ("Van", "Bus", "Motorcycle"). | `SearchResultsScreen` category chips (`lib/features/search/presentation/search_results_screen.dart`) | `test/pricing_search_test.dart` | **PASS** |
| **6** | Trip displays authoritative fare calculated via PostgreSQL RPC. | `calculate_authoritative_fare` RPC, `PricingService.calculateFare` | `test/pricing_search_test.dart` | **PASS** |
| **7** | Customer selects desired trip and proceeds to vehicle details. | `VehicleDetailsScreen` (`lib/features/vehicles/presentation/vehicle_details_screen.dart`) | `test/widget_test.dart` | **PASS** |
| **8** | Customer enters passenger count and contact details. | `BookingFlowScreen` (`lib/features/bookings/presentation/booking_flow_screen.dart`) | `test/booking_engine_test.dart` | **PASS** |
| **9** | Seat count decrements in real-time with pessimistic locks preventing overselling. | `create_booking_atomic` RPC (`SELECT ... FOR UPDATE`), `BookingRepository` | `test/booking_engine_test.dart`, `test/e2e_integration_test.dart` | **PASS** |
| **10** | Customer chooses "Cash on Board" payment method. | `BookingFlowScreen` payment radio selection (`PaymentMethod.cashOnBoard`) | `test/booking_engine_test.dart` | **PASS** |
| **11** | Booking created with `confirmed` status and `payment_status = pending`. | `BookingModel`, `create_booking_atomic` transaction | `test/booking_engine_test.dart` | **PASS** |
| **12** | Customer receives real-time booking confirmation in notifications. | `trg_notify_booking_created` trigger, `NotificationsScreen` | `test/dashboard_notification_test.dart` | **PASS** |
| **13** | Operator signs in to dedicated Operator Portal. | `OperatorDashboardScreen` (`lib/features/operator/presentation/operator_dashboard_screen.dart`) | `test/auth_test.dart`, `test/e2e_integration_test.dart` | **PASS** |
| **14** | Operator views incoming booking in live operations manifest. | `OperatorDashboardScreen` bookings manifest tab | `test/dashboard_notification_test.dart` | **PASS** |
| **15** | Operator marks passenger as boarded and confirms cash collection. | `confirm_cash_payment_atomic` RPC, `BookingRepository.confirmPayment` | `test/booking_engine_test.dart`, `test/e2e_integration_test.dart` | **PASS** |
| **16** | Booking updates to `payment_status = paid` with immutable cash ledger event. | `booking_events` audit table, `PaymentStatus.paid` | `test/booking_engine_test.dart` | **PASS** |
| **17** | Customer sees updated paid/completed status in "My Bookings" tab. | `MyBookingsScreen` (`lib/features/bookings/presentation/my_bookings_screen.dart`), Supabase Realtime channel | `test/booking_engine_test.dart` | **PASS** |
| **18** | Administrator signs in via Flutter Web interface. | `AdminDashboardScreen` (`lib/features/admin/presentation/admin_dashboard_screen.dart`) | `test/auth_test.dart`, `test/e2e_integration_test.dart` | **PASS** |
| **19** | Admin views system metrics: total volume, collected cash, fleets, operators. | `get_admin_dashboard_metrics` RPC, `AdminDashboardScreen` metrics cards | `test/dashboard_notification_test.dart` | **PASS** |
| **20** | Admin reviews and approves pending operator application. | `AdminDashboardScreen` applications modal, `AuthRepository.updateOperatorStatus` | `test/auth_test.dart`, `test/e2e_integration_test.dart` | **PASS** |
| **21** | Newly approved operator gains access to fleet and schedule management. | RLS policy on `vehicles` and `schedules` for `approved` status | `supabase/tests/auth_roles_test.sql` | **PASS** |
| **22** | Admin configures new route stops and updates fare rules. | `fare_rules` table, `PricingService.updateFareRule` | `test/pricing_search_test.dart` | **PASS** |
| **23** | Updated fare rules immediately reflect in customer search queries. | `calculate_authoritative_fare` RPC queries live `fare_rules` table | `test/pricing_search_test.dart` | **PASS** |

---

## 2. Verification Conclusion

All 23 steps of the authoritative acceptance scenario have been implemented with end-to-end coverage across PostgreSQL stored procedures, Flutter Riverpod state repositories, and UI screens. Zero manual workarounds or mock paths exist in production logic.
