# Supabase Setup Guide for Agri Clinic Hub

## Overview
Supabase provides backend services for data storage and synchronization. The app uses a **hybrid local-first + cloud-sync** architecture:
- **Local Storage**: Hive + SharedPreferences for offline access
- **Cloud Storage**: Supabase for data persistence and sync

## Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Create a new project:
   - Project Name: `agri-clinic-hub`
   - Database Password: Create a strong password
   - Region: Choose closest to your users
4. Wait for project to initialize (2-5 minutes)

## Step 2: Get API Credentials

1. Go to **Project Settings** → **API**
2. Copy:
   - **Project URL** (Supabase URL)
   - **anon** key (Anon Key)
3. Update `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  // ... rest of config
}
```

## Step 3: Create Database Tables

### Using SQL Editor

Go to **SQL Editor** and run these commands:

#### 1. Farmers Table
```sql
CREATE TABLE farmers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  county TEXT,
  farm_size FLOAT DEFAULT 0,
  crop_types TEXT[] DEFAULT '{}',
  livestock_types TEXT[] DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS (Row Level Security)
ALTER TABLE farmers ENABLE ROW LEVEL SECURITY;

-- Create policy for users to access their own data
CREATE POLICY "Users can view their own profile"
  ON farmers FOR SELECT
  USING (uid = auth.uid()::text);

CREATE POLICY "Users can update their own profile"
  ON farmers FOR UPDATE
  USING (uid = auth.uid()::text);
```

#### 2. Scans Table
```sql
CREATE TABLE scans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scan_id TEXT UNIQUE NOT NULL,
  uid TEXT NOT NULL REFERENCES farmers(uid),
  image_url TEXT,
  crop_type TEXT,
  detected_diseases JSONB DEFAULT '[]',
  health_status TEXT DEFAULT 'unknown',
  confidence FLOAT DEFAULT 0,
  synced BOOLEAN DEFAULT false,
  scan_date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_scans_uid ON scans(uid);
CREATE INDEX idx_scans_scan_date ON scans(scan_date DESC);

-- Enable RLS
ALTER TABLE scans ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own scans"
  ON scans FOR SELECT
  USING (uid = auth.uid()::text);

CREATE POLICY "Users can create scans"
  ON scans FOR INSERT
  WITH CHECK (uid = auth.uid()::text);

CREATE POLICY "Users can update their scans"
  ON scans FOR UPDATE
  USING (uid = auth.uid()::text);
```

## Step 4: Setup Storage Bucket

1. Go to **Storage** → **Create Bucket**
2. Bucket name: `scans`
3. Make it **Private** (for security)
4. Click **Create Bucket**
5. Go to bucket settings → **Policies**
6. Add policy:

```sql
CREATE POLICY "Users can upload their own scans"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own scans"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own scans"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'scans' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## Step 5: Setup Environment Variables (Optional but Recommended)

Create `lib/core/config/.env`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

Install `flutter_dotenv`:
```bash
flutter pub add flutter_dotenv
```

Update `lib/core/config/supabase_config.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

And in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - lib/core/config/.env
```

## Step 6: Verify Connection

Run the app and check logs for:
```
✅ [SUPABASE] Supabase initialized successfully
```

## Data Sync Strategy

### On Login
```
1. User logs in locally (AuthService)
2. Fetch farmer profile from Supabase
3. Sync to local Hive storage
4. Show local data (instant)
5. Background: fetch latest from cloud
```

### Scan Upload
```
1. Offline: Save to local Hive + mark synced: false
2. Online detected: Upload to Supabase
3. On upload success: Mark synced: true
4. Periodically: Retry unsynced scans
```

### Image Upload
```
1. Capture image
2. Run disease detection
3. If online: Upload image to Supabase Storage
4. Save scan result with image URL
5. If offline: Store locally, retry when online
```

## Using SupabaseService

### Save Profile
```dart
final profile = FarmerProfile(
  userId: 'user123',
  fullName: 'John Farmer',
  phone: '+254712345678',
  county: 'Nairobi',
  farmSize: 2.5,
  cropTypes: ['maize', 'beans'],
  livestockTypes: ['chickens'],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await SupabaseService.saveFarmerProfile('user-uid', profile);
```

### Get Scan History
```dart
final scans = await SupabaseService.getScanHistory(userId);
for (var scan in scans) {
  print('${scan.cropType}: ${scan.healthStatus}');
}
```

### Upload Scan Image
```dart
final imageBytes = await imageFile.readAsBytes();
final url = await SupabaseService.uploadScanImage(
  userId: userId,
  fileName: 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
  fileBytes: imageBytes,
);
```

## Troubleshooting

### "Supabase not initialized"
- Check `supabaseUrl` and `supabaseAnonKey` in `supabase_config.dart`
- Verify credentials from Supabase dashboard

### "Permission denied" on database operations
- Check Row Level Security (RLS) policies
- Ensure `uid` matches `auth.uid()`

### Image upload failing
- Verify storage bucket exists and is named `scans`
- Check storage policies allow your operations
- Ensure file size is under 50MB

### Connection timeouts
- Check internet connection
- Verify Supabase project is running
- Check if Supabase API is experiencing issues at status.supabase.com

## Security Best Practices

1. **Never commit API keys** - Use environment variables
2. **Enable RLS policies** - All tables should have RLS enabled
3. **Use AnonymousKey only** - Never expose Service Role Key
4. **Validate data** - Always validate user input before storage
5. **Encrypt sensitive data** - Use HTTPS for all connections (built-in with Supabase)

## Migration from Firebase to Supabase

Already done in this project:
- ✅ Removed Firebase dependencies
- ✅ Local authentication with SharedPreferences
- ✅ Supabase integration for cloud sync
- ✅ Offline-first architecture

Next steps:
1. Export data from Firebase (if migrating existing app)
2. Import into Supabase
3. Test all features with real Supabase instance
