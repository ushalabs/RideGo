# RideGo Figma Visual Parity Checklist

Authoritative Reference: Figma Design `WS 101- group 11` & `Untitled`
Operating Area: Samar & Leyte, Philippines

## 1. Visual Token Parity

| Token | Figma Design Value | RideGo Implementation | Status |
|---|---|---|---|
| Background Color | Sky / Pastel Blue (`#8FB8DE`) | `AppColors.background` (`0xFF8FB8DE`) | Exact Match |
| Primary Header | Dark Navy (`#1E3A5F` / `#162E4D`) | `AppColors.headerNavy` (`0xFF1E3A5F`) | Exact Match |
| Bottom Navigation | Deep Navy (`#152A45`) | `AppColors.headerDarker` (`0xFF152A45`) | Exact Match |
| Primary Action CTA | Dark Teal (`#126E82` / `#0D6E6E`) | `AppColors.buttonTeal` (`0xFF126E82`) | Exact Match |
| Cyan Accent | Bright Cyan (`#48CAE4`) | `AppColors.accentCyan` (`0xFF48CAE4`) | Exact Match |
| Search Bar Pill | White rounded pill, radius 30 | `SearchField` widget with radius 30 & shadow | Exact Match |
| Card Containers | White rounded 16-20px | `VehicleCard` with radius 20 & soft elevation | Exact Match |
| RideGo Logo | Shield badge, car silhouette & water bubbles | Vector custom painter `RideGoLogo` | Exact Match |

---

## 2. Screen-by-Screen Implementation Checklist

### 1. Splash Screen
- [x] Light blue background
- [x] RideGo shield badge logo with water splash details
- [x] "Samar & Leyte Transit Booking" subtitle
- [x] Circular loading indicator matching dark navy theme
- [x] Automatic session navigation

### 2. Login Screen
- [x] RideGo logo banner
- [x] Rounded email input field with icon
- [x] Password input field with visibility toggle
- [x] Forgot password option
- [x] Dark teal "LOGIN" button
- [x] "Don't have an account? Sign Up" navigation
- [x] Portals for Operator & Admin

### 3. Customer Registration Screen
- [x] Full Name, Email, Password, Confirm Password fields
- [x] Terms & conditions agreement checkbox
- [x] Create account action button
- [x] Back to Login navigation

### 4. Customer Home Screen
- [x] Dark navy curved header with personalized user greeting ("Hello, Kiya")
- [x] Profile avatar
- [x] Rounded destination search bar ("Search for destination, city or veh...")
- [x] Category selector pills: Van, Bus, Motor, Car
- [x] "Book a Vehicle" banner with vehicle illustration and CTA
- [x] Available trips vehicle cards grid (Van-Vans, GrandTours, City Tours, Duptours)
- [x] 4-tab bottom navigation (Home, My Bookings, Notifications, Profile)

### 5. Vehicle Category Screens (Van, Bus, Motor, Car)
- [x] Dark navy header with category icon & contextual subtitle
- [x] Subtitles matching Figma:
  - Van: "Comfort for groups and family trips"
  - Bus: "Affordable and safe for long trips"
  - Motor: "Fast, flexible and affordable"
  - Car: "Private and personalized journey"
- [x] Tiers filter: "All", "Regular", "Premium"
- [x] Search filter field
- [x] Vehicle cards in 2-column responsive layout

### 6. Vehicle Listing and Details Screen
- [x] Hero vehicle illustration banner
- [x] 5.0 Star rating and seat capacity indicator
- [x] Operator information & corridor details (Catbalogan to Tacloban)
- [x] Amenities breakdown (Air conditioned, Luggage space, USB charging, Sanitized)
- [x] Direct booking CTA button

### 7. Booking Flow UI
- [x] Samar & Leyte pickup stop dropdown
- [x] Samar & Leyte drop-off stop dropdown
- [x] Interactive calendar date picker
- [x] Available departure time selector (06:00 AM, 08:30 AM, 01:00 PM, etc.)
- [x] Passenger counter stepper
- [x] Itemized Fare Breakdown in PHP (₱)
- [x] Cash / Pay-at-Terminal payment notice
- [x] Booking confirmation dialog with unique booking reference code

### 8. My Bookings Screen
- [x] Dark navy header with "My Bookings" & "Manage your trips"
- [x] 3 Status tabs: "Upcoming", "Completed", "Cancelled" (matching Figma styling)
- [x] Detailed booking cards with status chips, route, departure, seat count, and fare
- [x] Cancellation workflow for upcoming bookings

### 9. Notifications Screen
- [x] Dark navy header with "Notifications" & "Stay updated with your bookings"
- [x] In-app notification cards (Confirmed, Pending, Departure reminder, Completed)
- [x] Read/unread visual state styling
- [x] "Mark all read" action

### 10. Profile and Settings Screen
- [x] User avatar, name, email, and role badge
- [x] Menu list: Personal Information, Payment Methods, Change Password, Help & Support, App Settings
- [x] Operator Portal & Admin Console quick switchers
- [x] Log Out button

### 11. Operator Registration and Dashboard Shell
- [x] Application review state banner
- [x] Overview statistics cards (Fleet count, Scheduled trips, Today bookings, Revenue)
- [x] Fleet management tab with "Add Vehicle" modal
- [x] Trip departure creation modal
- [x] Incoming passenger reservations management (Confirm / Reject / Complete)

### 12. Admin Dashboard Shell
- [x] Responsive layout for Flutter Web & Mobile
- [x] Dark navy sidebar on desktop / Chip tabs on mobile
- [x] System metrics (Customers, Operators, Applications, Bookings)
- [x] Operator approval queue with Approve / Reject controls
- [x] Supported corridors inspector (Southbound & Northbound)
- [x] Authoritative Fare Configuration Matrix
