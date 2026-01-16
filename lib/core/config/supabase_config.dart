/// Supabase Configuration
/// Production credentials for Agri Clinic Hub

class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://kefaczvopjostwlyzfcm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlZmFjenZvcGpvc3R3bHl6ZmNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NDk1NDUsImV4cCI6MjA4NDEyNTU0NX0.cZIBmMwgLrVnSHCzP07xBKXcuU5bHqPXE7wkQ6jFO5A';

  /// Supabase Database Tables
  /// Create these tables in your Supabase project:
  ///
  /// 1. farmers table:
  /// - id (uuid, primary key)
  /// - uid (text, unique)
  /// - email (text, unique)
  /// - full_name (text)
  /// - phone (text)
  /// - county (text)
  /// - farm_size (float)
  /// - crop_types (text array)
  /// - livestock_types (text array)
  /// - created_at (timestamp)
  /// - updated_at (timestamp)
  ///
  /// 2. scans table:
  /// - id (uuid, primary key)
  /// - scan_id (text, unique)
  /// - uid (text, foreign key to farmers)
  /// - image_url (text)
  /// - crop_type (text)
  /// - detected_diseases (jsonb)
  /// - health_status (text)
  /// - confidence (float)
  /// - synced (boolean)
  /// - scan_date (timestamp)
  /// - created_at (timestamp)

  static const String farmersTable = 'farmers';
  static const String scansTable = 'scans';
  static const String storageFolder = 'scans';
}
