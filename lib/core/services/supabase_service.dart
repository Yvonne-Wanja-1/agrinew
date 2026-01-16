import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agriclinichub_new/core/models/farmer_profile.dart';
import 'package:agriclinichub_new/core/models/scan_result.dart';
import 'package:agriclinichub_new/core/config/supabase_config.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Supabase Service
/// Handles all database operations and cloud storage for:
/// - Farmer profiles
/// - Disease scan results
/// - Image uploads
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      debugPrint('✅ [SUPABASE] Supabase initialized successfully');
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Failed to initialize: $e');
      rethrow;
    }
  }

  // === Farmer Profile Operations ===

  /// Create or update farmer profile
  static Future<void> saveFarmerProfile(
    String uid,
    FarmerProfile profile,
  ) async {
    try {
      await _client.from(SupabaseConfig.farmersTable).upsert({
        'uid': uid,
        'email': profile.userId, // Using userId as email reference
        'full_name': profile.fullName,
        'phone': profile.phone,
        'county': profile.county,
        'farm_size': profile.farmSize,
        'crop_types': profile.cropTypes,
        'livestock_types': profile.livestockTypes,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'uid');
      debugPrint('✅ [SUPABASE] Farmer profile saved: ${profile.fullName}');
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Error saving farmer profile: $e');
      rethrow;
    }
  }

  /// Get farmer profile
  static Future<FarmerProfile?> getFarmerProfile(String uid) async {
    try {
      final response = await _client
          .from(SupabaseConfig.farmersTable)
          .select()
          .eq('uid', uid)
          .single();

      debugPrint('✅ [SUPABASE] Farmer profile retrieved: $uid');

      return FarmerProfile(
        userId: response['email'] ?? '',
        fullName: response['full_name'] ?? '',
        phone: response['phone'] ?? '',
        county: response['county'] ?? '',
        farmSize: (response['farm_size'] ?? 0).toDouble(),
        cropTypes: List<String>.from(response['crop_types'] ?? []),
        livestockTypes: List<String>.from(response['livestock_types'] ?? []),
        createdAt: DateTime.parse(
          response['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          response['updated_at'] ?? DateTime.now().toIso8601String(),
        ),
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows found
        debugPrint('🟡 [SUPABASE] No profile found for uid: $uid');
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Error retrieving farmer profile: $e');
      rethrow;
    }
  }

  // === Scan Results Operations ===

  /// Save scan result to database
  static Future<void> saveScanResult(String uid, ScanResult scan) async {
    try {
      await _client.from(SupabaseConfig.scansTable).insert({
        'scan_id': scan.scanId,
        'uid': uid,
        'image_url': scan.imagePath,
        'crop_type': scan.cropType,
        'detected_diseases': jsonEncode(
          scan.detectedDiseases.map((d) => d.toMap()).toList(),
        ),
        'health_status': scan.healthStatus,
        'confidence': scan.confidence,
        'synced': true,
        'scan_date': scan.scanDate.toIso8601String(),
      });
      debugPrint('✅ [SUPABASE] Scan result saved: ${scan.scanId}');
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Error saving scan result: $e');
      rethrow;
    }
  }

  /// Get all scan results for a user
  static Future<List<ScanResult>> getScanHistory(String uid) async {
    try {
      final response = await _client
          .from(SupabaseConfig.scansTable)
          .select()
          .eq('uid', uid)
          .order('scan_date', ascending: false);

      final scans = <ScanResult>[];
      for (var scan in response) {
        try {
          final detectedDiseases =
              (jsonDecode(scan['detected_diseases'] ?? '[]') as List)
                  .map((d) => Disease.fromMap(d))
                  .toList();

          scans.add(
            ScanResult(
              scanId: scan['scan_id'] ?? '',
              userId: scan['uid'] ?? '',
              imagePath: scan['image_url'] ?? '',
              cropType: scan['crop_type'] ?? '',
              detectedDiseases: detectedDiseases,
              healthStatus: scan['health_status'] ?? 'unknown',
              scanDate: DateTime.parse(
                scan['scan_date'] ?? DateTime.now().toIso8601String(),
              ),
              confidence: (scan['confidence'] ?? 0).toDouble(),
              synced: scan['synced'] ?? true,
            ),
          );
        } catch (e) {
          debugPrint('🟡 [SUPABASE] Error parsing scan: $e');
        }
      }

      debugPrint(
        '✅ [SUPABASE] Retrieved ${scans.length} scan results for $uid',
      );
      return scans;
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Error retrieving scan history: $e');
      rethrow;
    }
  }

  /// Get single scan result
  static Future<ScanResult?> getScanById(String scanId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.scansTable)
          .select()
          .eq('scan_id', scanId)
          .single();

      final detectedDiseases =
          (jsonDecode(response['detected_diseases'] ?? '[]') as List)
              .map((d) => Disease.fromMap(d))
              .toList();

      return ScanResult(
        scanId: response['scan_id'] ?? '',
        userId: response['uid'] ?? '',
        imagePath: response['image_url'] ?? '',
        cropType: response['crop_type'] ?? '',
        detectedDiseases: detectedDiseases,
        healthStatus: response['health_status'] ?? 'unknown',
        scanDate: DateTime.parse(
          response['scan_date'] ?? DateTime.now().toIso8601String(),
        ),
        confidence: (response['confidence'] ?? 0).toDouble(),
        synced: response['synced'] ?? true,
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        debugPrint('🟡 [SUPABASE] No scan found with id: $scanId');
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Error retrieving scan: $e');
      rethrow;
    }
  }

  /// Update scan synced status
  static Future<void> updateScanSyncStatus(String scanId, bool synced) async {
    try {
      await _client
          .from(SupabaseConfig.scansTable)
          .update({'synced': synced})
          .eq('scan_id', scanId);

      debugPrint('✅ [SUPABASE] Scan sync status updated: $scanId -> $synced');
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Error updating scan sync status: $e');
      rethrow;
    }
  }

  // === File Storage Operations ===

  /// Upload scan image to storage
  static Future<String> uploadScanImage({
    required String userId,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _client.storage
          .from(SupabaseConfig.storageFolder)
          .uploadBinary(path, Uint8List.fromList(fileBytes));

      final publicUrl = _client.storage
          .from(SupabaseConfig.storageFolder)
          .getPublicUrl(path);

      debugPrint('✅ [SUPABASE] Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Error uploading image: $e');
      rethrow;
    }
  }

  /// Delete scan image from storage
  static Future<void> deleteScanImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.last;

      await _client.storage.from(SupabaseConfig.storageFolder).remove([path]);

      debugPrint('✅ [SUPABASE] Image deleted: $path');
    } catch (e) {
      debugPrint('🔴 [SUPABASE] Error deleting image: $e');
      rethrow;
    }
  }

  // === Health Check ===

  /// Check if Supabase is available
  static Future<bool> isAvailable() async {
    try {
      await _client.from(SupabaseConfig.farmersTable).select().limit(1);
      return true;
    } catch (e) {
      debugPrint('🟡 [SUPABASE] Supabase not available: $e');
      return false;
    }
  }
}
