# RideGo — Supabase Manual Setup & Deployment Guide

This guide provides instructions for the project owner to set up the Supabase backend, apply database migrations, bootstrap administrator access, configure storage buckets, and run the Flutter application.

---

## 1. Supabase Project Initialization

If you have an existing Supabase project, log in to the [Supabase Dashboard](https://supabase.com/dashboard) and select your project.

### Required Credentials
Locate the following in **Project Settings > API**:
- **Project URL**: e.g., `https://xyzcompany.supabase.co`
- **Anon / Publishable Key**: e.g., `eyJhbGciOi...`
- *(Keep the Service Role secret key private — do not embed it in client applications)*

---

## 2. Applying Database Migrations via SQL Editor

If you do not have the Supabase CLI configured locally, you can apply the migrations directly via the Supabase Web Dashboard:

1. Navigate to **SQL Editor** in the left sidebar.
2. Click **New Query**.
3. Open and copy the SQL code from each file in the `supabase/migrations/` directory in the following sequential order:

### Migration Execution Order:
| Step | Migration File | Description |
|---|---|---|
| 1 | `supabase/migrations/20261030000001_auth_and_roles.sql` | User profiles, roles, operators, applications, and admin functions |
| 2 | `supabase/migrations/20261030000002_vehicles_and_routes.sql` | Samar/Leyte corridors, 18 stops, routes, vehicles, and schedules |
| 3 | `supabase/migrations/20261030000003_search_and_pricing.sql` | Authoritative pricing RPC and route search stored procedures |
| 4 | `supabase/migrations/20261030000004_realtime_booking_engine.sql` | Atomic bookings, pessimistic locking, and cash payments |
| 5 | `supabase/migrations/20261030000005_dashboards_and_notifications.sql` | Real-time notifications, event triggers, and admin dashboard metrics |

4. After pasting each migration, click **Run** (or press `Ctrl + Enter`). Verify that the console displays `Success. No rows returned` or the expected confirmation output.

---

## 3. Bootstrapping the First Administrator Account

1. Create a user account in your app or directly via **Authentication > Users > Add User** (e.g., `admin@ridego.ph`).
2. Copy the user's UUID or email address.
3. Open the **SQL Editor** and run:
   ```sql
   SELECT bootstrap_admin('admin@ridego.ph');
   ```
4. This stored procedure will automatically update the profile record and grant full administrative privileges (`role = 'admin'`).

---

## 4. Configuring Supabase Storage

RideGo uses Supabase Storage for vehicle photos, operator business permits, and identification documents:

1. In the Supabase Dashboard, click on **Storage** in the left menu.
2. Click **New Bucket**.
3. Bucket Details:
   - **Bucket Name**: `vehicle-images`
   - **Public Bucket**: **Toggle to ON** (allows public read access for vehicle listing images).
4. Storage Policies:
   - The migration `20261030000002_vehicles_and_routes.sql` automatically includes storage RLS policies granting authenticated operators upload permissions and public read permissions.

---

## 5. Enabling Supabase Realtime

RideGo uses real-time event broadcasting for live seat decrementing, booking confirmations, and status updates:

1. In the Dashboard, navigate to **Database > Publications**.
2. Select the `supabase_realtime` publication.
3. Ensure the following tables are toggled **ON**:
   - `bookings`
   - `notifications`
   - `schedules`
4. Alternatively, execute this SQL in the SQL Editor:
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE bookings, notifications, schedules;
   ```

---

## 6. Configuring the Local Environment

Create or update `config.dev.json` in the root of your project:

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_ANON_KEY"
}
```

> **Security Note**: `config.dev.json` and any secret keys are included in `.gitignore` and must never be committed to source control.

---

## 7. Running the Application

### Running on Mobile (Android / iOS):
```powershell
$env:PATH = "C:\development\flutter\bin;$env:PATH"
flutter run --dart-define-from-file=config.dev.json
```

### Running on Flutter Web (Administrator / Customer portal):
```powershell
$env:PATH = "C:\development\flutter\bin;$env:PATH"
flutter run -d chrome --dart-define-from-file=config.dev.json
```

### Testing Without Network Credentials (Offline Demo Fallback):
If `config.dev.json` contains placeholder credentials, RideGo automatically activates high-fidelity demo fallback mode. You can log in using:
- **Customer**: Click the `Customer Demo` shortcut button.
- **Operator**: Click the `Operator Demo` shortcut button.
- **Admin**: Click the `Admin Demo` shortcut button.
