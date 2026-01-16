/// Supabase Configuration
///
/// To set up Supabase:
/// 1. Go to https://supabase.com and create a new project
/// 2. Copy your Supabase URL and Anon Key from project settings
/// 3. Replace the values below with your actual credentials
/// 4. For environment-specific configuration, use .env files with flutter_dotenv package

class SupabaseConfig {
  // TODO: Replace with your actual Supabase URL and anon key
  // Get these from your Supabase project settings
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';

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
