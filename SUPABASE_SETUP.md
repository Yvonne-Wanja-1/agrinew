# Supabase Production Setup for Agri Clinic Hub

**Architecture**: Hybrid local-first + cloud-sync
- **Local Storage**: Hive + SharedPreferences for offline access & instant UI
- **Cloud Storage**: Supabase for data persistence, backup, and multi-device sync
- **Synchronization**: Automatic sync when online, retry queue for offline changes

---

## Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign up
2. Create a new project:
   - **Project Name**: `agri-clinic-hub`
   - **Database Password**: Create a strong, unique password (store securely)
   - **Region**: Select closest to your users (e.g., `eu-west-1` for Europe, `us-east-1` for US)
3. Wait for project initialization (2-5 minutes)

---

## Step 2: Get and Secure API Credentials

1. Go to **Project Settings** → **API**
2. Copy the credentials:
   - **Project URL** (under "API URL")
   - **`anon` (public) key** (under "Project API keys" → first key labeled "anon")

3. Create `.env` at project root (NOT in `lib/`):
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

4. Add to `.gitignore` (prevent accidental commits):
```
.env
.env.local
.env.*.local
```

5. Install `flutter_dotenv`:
```bash
flutter pub add flutter_dotenv
```

6. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```

7. Update `lib/core/config/supabase_config.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Table names
  static const String farmersTable = 'farmers';
  static const String scansTable = 'scans';
  static const String cropCalendarTable = 'crop_calendar';
  static const String notificationHistoryTable = 'notification_history';
  static const String articlesTable = 'articles';

  // Storage buckets
  static const String scansStorageBucket = 'scans';
  static const String articlesStorageBucket = 'articles';
  static const String avatarsStorageBucket = 'user-avatars';
}
```

8. Update `lib/main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables FIRST
  await dotenv.load();
  
  // Initialize services
  await NotificationService.initialize();
  // ... rest of initialization
}
```

---

## Step 3: Create Database Tables with Proper Schema

**Important**: Use UUID for user ownership (direct links to `auth.users.id`), not TEXT hacks.

Go to **SQL Editor** in Supabase dashboard and run the following SQL scripts:

### 3.1 Farmers Table (User Profiles)
```sql
-- Create farmers table with UUID FK to auth.users
CREATE TABLE farmers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  phone TEXT,
  county TEXT,
  farm_size FLOAT DEFAULT 0,
  crop_types TEXT[] DEFAULT '{}',
  livestock_types TEXT[] DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE farmers ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own profile
CREATE POLICY "farmers_select_own"
  ON farmers FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can update their own profile
CREATE POLICY "farmers_update_own"
  ON farmers FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can insert their own profile (via trigger or app)
CREATE POLICY "farmers_insert_own"
  ON farmers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX idx_farmers_user_id ON farmers(user_id);
CREATE INDEX idx_farmers_email ON farmers(email);
```

### 3.2 Scans Table (Disease Detection Results)
```sql
-- Create scans table with UUID FK to auth.users
CREATE TABLE scans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scan_id TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT,
  crop_type TEXT,
  detected_diseases JSONB DEFAULT '[]',
  health_status TEXT DEFAULT 'unknown',
  confidence FLOAT DEFAULT 0,
  synced BOOLEAN DEFAULT false,
  scan_date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE scans ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own scans
CREATE POLICY "scans_select_own"
  ON scans FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own scans
CREATE POLICY "scans_insert_own"
  ON scans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own scans
CREATE POLICY "scans_update_own"
  ON scans FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own scans
CREATE POLICY "scans_delete_own"
  ON scans FOR DELETE
  USING (auth.uid() = user_id);

-- Indexes for faster queries
CREATE INDEX idx_scans_user_id ON scans(user_id);
CREATE INDEX idx_scans_scan_date ON scans(scan_date DESC);
CREATE INDEX idx_scans_scan_id ON scans(scan_id);
```

### 3.3 Crop Calendar Table (Read-Only Public Reference Data)
```sql
-- Create crop calendar table (shared reference data, not per-user)
CREATE TABLE crop_calendar (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  county TEXT NOT NULL,
  crop_name TEXT NOT NULL,
  season TEXT NOT NULL,
  planting_start DATE NOT NULL,
  planting_end DATE NOT NULL,
  harvest_start DATE NOT NULL,
  harvest_end DATE NOT NULL,
  seasonal
  _tips TEXT[] DEFAULT '{}',
  required_inputs TEXT[] DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(county, crop_name, season)
);

-- Enable RLS
ALTER TABLE crop_calendar ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Anyone can view crop calendar (public reference data)
CREATE POLICY "crop_calendar_select_public"
  ON crop_calendar FOR SELECT
  TO authenticated
  USING (true);

-- Index for faster queries
CREATE INDEX idx_crop_calendar_county ON crop_calendar(county);
CREATE INDEX idx_crop_calendar_crop_name ON crop_calendar(crop_name);
```

### 3.4 Notification History Table
```sql
-- Create notification history table
CREATE TABLE notification_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own notifications
CREATE POLICY "notification_history_select_own"
  ON notification_history FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can update their own notifications (mark as read)
CREATE POLICY "notification_history_update_own"
  ON notification_history FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX idx_notification_history_user_id ON notification_history(user_id);
CREATE INDEX idx_notification_history_created_at ON notification_history(created_at DESC);
```

### 3.5 Articles Table (Educational Content)
```sql
-- Create articles table (shared reference data)
CREATE TABLE articles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  topic TEXT,
  author TEXT,
  featured_image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Anyone can view articles (public reference data)
CREATE POLICY "articles_select_public"
  ON articles FOR SELECT
  TO authenticated
  USING (true);

-- Index for faster queries
CREATE INDEX idx_articles_category ON articles(category);
CREATE INDEX idx_articles_topic ON articles(topic);
```

---

## Step 4: Setup Storage Buckets with Security Policies

**Important**: All buckets must be **PRIVATE** (not public) and enforce user-based access.

### 4.1 Create Storage Buckets

1. Go to **Storage** in Supabase dashboard
2. Click **Create Bucket** and repeat for each:

| Bucket Name | Access Level | Purpose |
|---|---|---|
| `scans` | Private | Disease detection scan images |
| `articles` | Private | Article images/thumbnails |
| `user-avatars` | Private | User profile pictures |

### 4.2 Add Storage Policies for Scans Bucket

Go to **Storage** → **scans** → **Policies** and add:

```sql
-- Policy: Users can INSERT (upload) their own scans
-- Files must be in path: {user_id}/{filename}
CREATE POLICY "scans_insert_own"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'scans' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy: Users can SELECT (view/download) their own scans
CREATE POLICY "scans_select_own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'scans' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy: Users can DELETE their own scans
CREATE POLICY "scans_delete_own"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'scans' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
```

### 4.3 Add Storage Policies for User Avatars Bucket

```sql
-- Policy: Users can INSERT their own avatar
-- Files must be in path: {user_id}/avatar.{ext}
CREATE POLICY "avatars_insert_own"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'user-avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy: Users can SELECT their own avatar
CREATE POLICY "avatars_select_own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'user-avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy: Users can UPDATE/DELETE their own avatar
CREATE POLICY "avatars_delete_own"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'user-avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
```

### 4.4 Add Storage Policies for Articles Bucket (Admin-Only)

```sql
-- Policy: Authenticated users can SELECT articles (read-only)
CREATE POLICY "articles_select_public"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'articles');

-- Note: INSERT/UPDATE/DELETE for articles is admin-only
-- Admins can manage via Supabase dashboard
```

---

## Step 5: Initialize Supabase in Flutter App

### 5.1 Update Main Entry Point

File: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize Supabase (before other services)
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('✅ [SUPABASE] Initialized successfully');
  } catch (e) {
    debugPrint('⚠️ [SUPABASE] Initialization failed (using local storage only): $e');
  }

  // Initialize other services
  await NotificationService.initialize();
  await LocalStorageService.initialize();
  await AuthService.initialize();
  await SupabaseService.initialize();

  runApp(const MyApp());
}
```

### 5.2 Update SupabaseService to Use UUID

File: `lib/core/services/supabase_service.dart`

Key changes:
- Replace all `uid: TEXT` references with `user_id: UUID` (the actual auth.users.id)
- Use `auth.uid()` directly in RLS policies (no more TEXT casts)
- Enforce user_id in all INSERT/UPDATE operations

Example:
```dart
static Future<void> saveFarmerProfile(FarmerProfile profile) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from(SupabaseConfig.farmersTable).upsert({
      'user_id': userId,  // Use UUID directly
      'email': profile.userId,
      'full_name': profile.fullName,
      'phone': profile.phone,
      'county': profile.county,
      'farm_size': profile.farmSize,
      'crop_types': profile.cropTypes,
      'livestock_types': profile.livestockTypes,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  } catch (e) {
    debugPrint('🔴 [SUPABASE] Error saving profile: $e');
    rethrow;
  }
}
```

### 5.3 Storage Path Convention

When uploading files, always use: `{user_id}/{filename}`

```dart
static Future<String> uploadScanImage({
  required String fileName,
  required List<int> fileBytes,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');

  final path = '$userId/$fileName';
  
  await _client.storage
      .from(SupabaseConfig.scansStorageBucket)
      .uploadBinary(path, Uint8List.fromList(fileBytes));

  return _client.storage
      .from(SupabaseConfig.scansStorageBucket)
      .getPublicUrl(path);
}
```

---

## Step 6: Verify Setup

1. **Check Supabase Connection**:
   ```bash
   flutter run
   ```
   Look for logs:
   ```
   ✅ [SUPABASE] Initialized successfully
   ```

2. **Test Database Access**:
   - Create a test user via AuthService
   - In Supabase dashboard → **SQL Editor**, run:
   ```sql
   SELECT * FROM farmers;
   SELECT * FROM scans;
   ```
   You should see your test user's data

3. **Test Storage Access**:
   - Upload a test image
   - Check **Storage** → **scans** → your user folder for the file

4. **Verify RLS is Working**:
   - Login as User A
   - Try to access User B's data (should fail)
   - RLS policies should prevent cross-user access

---

## Step 7: Data Synchronization Strategy

### On App Startup
```
1. Load local Hive/SharedPreferences data (instant)
2. If online: Fetch latest from Supabase in background
3. If difference found: Update local cache (transparent to UI)
4. Show local data to user (always fast)
```

### On Scan Upload
```
1. Run disease detection locally
2. Save to local Hive + mark synced: false
3. If online: Upload image to Storage + save scan to database
4. Mark synced: true in Hive
5. If offline: Show "pending sync" badge
6. ConnectivityListener triggers retry when online
```

### On Data Mutation (Profile Update)
```
1. Update local Hive immediately
2. Show updated data in UI (optimistic update)
3. If online: Send to Supabase
4. If Supabase fails: Keep local version, mark for retry
5. If offline: Mark for retry, sync when online
```

---

## Step 8: Security Checklist

- [ ] Environment variables in `.env` at project root
- [ ] `.env` added to `.gitignore` (prevent accidental commits)
- [ ] Only using `anon` (public) key in Flutter app
- [ ] Service role key stored securely (never in app code)
- [ ] RLS enabled on all tables
- [ ] Storage buckets set to PRIVATE (not public)
- [ ] Storage policies enforce user_id path restriction
- [ ] No sensitive data in logs (remove debugPrint in production)
- [ ] HTTPS only for all Supabase communications (built-in)
- [ ] Password hashing in AuthService upgraded to bcrypt (not base64)

---

## Step 9: Troubleshooting

| Issue | Cause | Solution |
|---|---|---|
| "Supabase not initialized" | `.env` file not loaded or credentials missing | Check `.env` exists at project root, run `flutter pub get`, verify `dotenv.load()` called in main() |
| "Permission denied" on DB operations | RLS policy mismatch or user_id mismatch | Verify `auth.uid() = user_id` in policy, check user is authenticated |
| "File not found" in Storage | File path doesn't match policy (not in `{user_id}/` folder) | Always upload to `$userId/$filename`, verify path in policy |
| "CORS errors" | Cross-origin request blocked | Not applicable if using official Supabase package (handles automatically) |
| "UUID mismatch" | Mixing TEXT uid with UUID user_id | Use UUID everywhere, never cast `auth.uid()` to text in FK constraints |
| "Cascading deletes not working" | FK missing `ON DELETE CASCADE` | Verify all FOREIGN KEY constraints include `ON DELETE CASCADE` |

---

## Step 10: Production Deployment Checklist

- [ ] All SQL scripts run successfully
- [ ] All tables have RLS enabled
- [ ] All storage buckets have policies
- [ ] `.env` file NOT committed to git
- [ ] `flutter_dotenv` properly initialized
- [ ] SupabaseService error handling in place
- [ ] Local storage (Hive) cache populated on login
- [ ] Sync logic tested offline and online
- [ ] Image uploads tested with real files
- [ ] User deletion tested (cascades work)
- [ ] Load testing on database (monitor Supabase dashboard)
- [ ] Backup strategy in place (Supabase auto-backups available)

---

## Reference: Complete Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                              │
│  ┌─────────────────┐         ┌─────────────────┐            │
│  │ Auth Service    │         │ Supabase Service│            │
│  │ (local auth +   │         │ (cloud sync)    │            │
│  │ SharedPrefs)    │         │                 │            │
│  └────────┬────────┘         └────────┬────────┘            │
└───────────┼───────────────────────────┼────────────────────┘
            │                           │
            ▼                           ▼
    ┌─────────────────┐      ┌─────────────────┐
    │  Hive DB        │      │  Supabase       │
    │  (offline)      │◄────►│  (cloud)        │
    └─────────────────┘      └─────────────────┘
    
Local-First: Always read from Hive/SharedPrefs (instant)
Cloud-Sync: Background sync to Supabase when online
Offline Resilient: Full app functionality without internet
```
