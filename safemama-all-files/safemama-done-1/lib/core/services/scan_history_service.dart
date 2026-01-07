// lib/core/services/scan_history_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemama/core/models/scan_data.dart'; // ScanData.fromDbMap will be used for the return type, also assumed to provide RiskLevel enum and riskLevelToString
import 'package:path/path.dart' as p;

// Define the Free Tier History Limit
const int FREE_USER_SCAN_HISTORY_LIMIT = 3; // CORRECTED - Free users see last 3 scans

class ScanHistoryService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final String _historyTableName = 'scan_history';
  final String _storageBucketName = 'scanimages'; // Match Supabase exactly

  // MODIFIED: Return type changed to Future<ScanData?>
  Future<ScanData?> logScanToHistory({
    required Map<String, dynamic> rawParsedOpenAiResponse,
    required String userId,
    String? localImagePathToUpload,
    String? existingImageUrl,
    bool isBookmarkedInitially = false,
  }) async {
    print("[ScanHistoryService.logScanToHistory] Initiating scan log..."); // General entry log

    if (userId.isEmpty) {
      print("[ScanHistoryService.logScanToHistory] ERROR: User ID is empty. Cannot log scan. Returning null.");
      return null; // MODIFIED: Return null instead of throwing
    }

    final productNameForLog = rawParsedOpenAiResponse['productName'] as String? ?? "Unknown Product";
    print(
        "[ScanHistoryService.logScanToHistory] Logging for user: $userId, product: $productNameForLog");

    String? finalUploadedImageUrl = existingImageUrl;
    bool imageUploadAttemptedAndFailed = false; // Flag to track image upload failure

    if (localImagePathToUpload != null && localImagePathToUpload.isNotEmpty) {
      print("[ScanHistoryService.logScanToHistory] Local image path provided: $localImagePathToUpload");
      final imageFile = File(localImagePathToUpload);
      if (await imageFile.exists()) {
        final fileExtension = p.extension(imageFile.path).toLowerCase();
        final validExtension = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(fileExtension)
                                ? fileExtension
                                : (fileExtension.isNotEmpty ? fileExtension : '.jpg');
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, (userId.length < 8 ? userId.length : 8))}$validExtension';
        final filePathInBucket = '$userId/$fileName';

        print("[ScanHistoryService.logScanToHistory] === Image Upload Start ===");
        print("[ScanHistoryService.logScanToHistory] Local file source: ${imageFile.path}");
        print("[ScanHistoryService.logScanToHistory] Target bucket path in '$_storageBucketName': $filePathInBucket");
        try {
          await _supabaseClient.storage.from(_storageBucketName).upload(
              filePathInBucket, imageFile,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false));
          finalUploadedImageUrl = _supabaseClient.storage
              .from(_storageBucketName)
              .getPublicUrl(filePathInBucket);
          print(
              "[ScanHistoryService.logScanToHistory] Image uploaded successfully. Public URL: $finalUploadedImageUrl");
        } catch (e) {
          print("[ScanHistoryService.logScanToHistory] #ERROR# Uploading New Image: $e");
          if (e is StorageException) {
            print(
                "[ScanHistoryService.logScanToHistory] Storage Exception Details: ${e.message}, Status Code: ${e.statusCode}, Error: ${e.error}");
          }
          imageUploadAttemptedAndFailed = true; // Mark as failed
          // MODIFIED: According to instructions, if image upload fails, the method might return null.
          // We will return null here as this is a critical part of logging the scan.
          print("[ScanHistoryService.logScanToHistory] Image upload failed. Returning null.");
          return null;
        }
        print("[ScanHistoryService.logScanToHistory] === Image Upload End ===");
      } else {
        print(
            "[ScanHistoryService.logScanToHistory] WARNING: localImagePathToUpload ('$localImagePathToUpload') provided but file does not exist. Skipping upload.");
        // If the file doesn't exist, it's like no image was provided for upload.
        // We don't set imageUploadAttemptedAndFailed = true here unless this is considered a hard error.
        // For now, let's assume it's a warning and proceed without an image if it doesn't exist.
      }
    } else {
      print(
          "[ScanHistoryService.logScanToHistory] No new local image path provided. Using existing imageUrl if any: $existingImageUrl");
    }

    // If an image upload was attempted and failed, we would have returned null already.
    // This check is redundant if the above return null is active, but kept for clarity if that changes.
    if (imageUploadAttemptedAndFailed) {
        print("[ScanHistoryService.logScanToHistory] Aborting DB insert due to prior image upload failure. Returning null.");
        return null;
    }


    final String? productName = rawParsedOpenAiResponse['productName'] as String?;
    final String? safetyLevelStringFromAI = rawParsedOpenAiResponse['safetyLevel'] as String?;
    final RiskLevel parsedEnumForStorage = riskLevelFromString(safetyLevelStringFromAI); // Assumes riskLevelFromString handles null/empty safetyLevelStringFromAI gracefully
    final String riskLevelStringToStore = riskLevelToString(parsedEnumForStorage);

    final Map<String, dynamic> dataToInsert = {
      'user_id': userId,
      'product_name': productName,
      'risk_level': riskLevelStringToStore,
      'product_image_url': finalUploadedImageUrl,
      'analysis_result_json': rawParsedOpenAiResponse,
      'is_bookmarked': isBookmarkedInitially,
      'scanned_at': DateTime.now().toIso8601String(),
      // 'created_at' will be set by Supabase by default, 'updated_at' on updates
    };

    print(
        "[ScanHistoryService.logScanToHistory] Data prepared for '$_historyTableName' insertion: ${dataToInsert.toString()}"); // Log the full data
    print(
        "[ScanHistoryService.logScanToHistory] Specifically, risk_level to store: '$riskLevelStringToStore'");


    try {
      print("[ScanHistoryService.logScanToHistory] Attempting to insert record into '$_historyTableName'...");
      final response = await _supabaseClient
          .from(_historyTableName)
          .insert(dataToInsert)
          .select() // Ensure select() is still appropriate for your RLS and desired return.
          .single();

      print(
          "[ScanHistoryService.logScanToHistory] Scan history record inserted successfully. Raw DB response: $response");

      if (response == null) {
          print("[ScanHistoryService.logScanToHistory] #ERROR# DB insert operation returned null. Cannot create ScanData. Returning null.");
          return null;
      }

      print("[ScanHistoryService.logScanToHistory] About to call ScanData.fromDbMap with the response.");
      final ScanData scanData = ScanData.fromDbMap(response); // This can throw if 'response' is not as expected by fromDbMap
      print("[ScanHistoryService.logScanToHistory] ScanData.fromDbMap executed. Resulting ScanData ID: ${scanData.id}");
      print("[ScanHistoryService.logScanToHistory] Returning ScanData object: ${scanData.toJson()}"); // Log the created ScanData object
      return scanData;

    } on PostgrestException catch (e, s) {
      print(
          "[ScanHistoryService.logScanToHistory] #ERROR# PostgrestException during DB insert: ${e.message}");
      print("[ScanHistoryService.logScanToHistory] Details: ${e.details}, Hint: ${e.hint}, Code: ${e.code}");
      print("[ScanHistoryService.logScanToHistory] StackTrace: $s");
      print("[ScanHistoryService.logScanToHistory] Returning null due to PostgrestException.");
      return null; // MODIFIED: Return null
    } catch (e, s) {
      print("[ScanHistoryService.logScanToHistory] #ERROR# Unexpected error during scan logging: $e");
      print("[ScanHistoryService.logScanToHistory] Error Type: ${e.runtimeType}");
      print("[ScanHistoryService.logScanToHistory] StackTrace: $s");
      // This could be an error from ScanData.fromDbMap if 'response' is not what it expects
      // or if fromDbMap itself has an issue.
      if (e.toString().contains("is not a subtype of type")) {
        print("[ScanHistoryService.logScanToHistory] Potential type issue during ScanData.fromDbMap. Check map keys and expected types.");
      }
      print("[ScanHistoryService.logScanToHistory] Returning null due to unexpected error.");
      return null; // MODIFIED: Return null
    }
  }

  Future<ScanData?> fetchScanById(String scanId) async {
    if (scanId.isEmpty) {
      print("[ScanHistoryService.fetchScanById] Error: scanId is empty. Returning null.");
      return null;
    }
    print("[ScanHistoryService.fetchScanById] Attempting to fetch scan with ID: $scanId");
    try {
      final response = await _supabaseClient
          .from(_historyTableName)
          .select()
          .eq('id', scanId)
          .maybeSingle();

      if (response == null) {
        print("[ScanHistoryService.fetchScanById] No scan found with ID: $scanId");
        return null;
      }
      print("[ScanHistoryService.fetchScanById] Scan found for ID: $scanId. Data: $response");
      return ScanData.fromDbMap(response);
    } on PostgrestException catch (e) {
      print("[ScanHistoryService.fetchScanById] PostgrestException fetching scan by ID $scanId: ${e.message}");
      print("[ScanHistoryService.fetchScanById] Details: ${e.details}, Hint: ${e.hint}, Code: ${e.code}");
      return null;
    } catch (e, stacktrace) {
      print("[ScanHistoryService.fetchScanById] Unexpected error fetching scan by ID $scanId: $e");
      print("[ScanHistoryService.fetchScanById] Stacktrace: $stacktrace");
      return null;
    }
  }

  Future<void> markScanAsBookmarked(String scanId, String userId, bool isBookmarked) async {
    if (userId.isEmpty) {
      throw Exception("User not logged in. Cannot mark scan as bookmarked.");
    }
    if (scanId.isEmpty) {
      throw Exception("Scan ID is required to mark as bookmarked.");
    }

    print("[MARK_BOOKMARKED] Attempting to set scanId: $scanId as is_bookmarked: $isBookmarked for user: $userId");
    try {
      final List<Map<String, dynamic>> updatedRows = await _supabaseClient
          .from(_historyTableName)
          .update({
            'is_bookmarked': isBookmarked,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', scanId)
          .eq('user_id', userId)
          .select();

      if (updatedRows.isNotEmpty) {
        final updatedItem = updatedRows.first;
        print("[MARK_BOOKMARKED] ScanId: $scanId - Update successful. Returned row: $updatedItem");
        print("[MARK_BOOKMARKED] Value of 'is_bookmarked' in returned row: ${updatedItem['is_bookmarked']}");
        if (updatedItem['is_bookmarked'] != isBookmarked) {
            print("[MARK_BOOKMARKED] #CRITICAL_WARNING# 'is_bookmarked' is NOT $isBookmarked in the row returned by update.select()!");
        }
      } else {
        print("[MARK_BOOKMARKED] #WARN# ScanId: $scanId - Update query (matching on ID and UserID) executed but NO ROWS were returned/updated. This means the item was not found with id='$scanId' AND user_id='$userId', OR RLS prevented the update.");
        final testFindById = await _supabaseClient.from(_historyTableName).select().eq('id', scanId).maybeSingle();
        if (testFindById != null) {
          print("[MARK_BOOKMARKED_DEBUG] Item with id='$scanId' EXISTS. Data: $testFindById");
          print("[MARK_BOOKMARKED_DEBUG] Its user_id is '${testFindById['user_id']}'. Does it match '$userId'?");
          print("[MARK_BOOKMARKED_DEBUG] Its is_bookmarked is '${testFindById['is_bookmarked']}'.");
        } else {
          print("[MARK_BOOKMARKED_DEBUG] Item with id='$scanId' DOES NOT EXIST in the table.");
        }
      }
    } on PostgrestException catch (e) {
      print("[MARK_BOOKMARKED] #ERROR# Supabase DB Error marking scan as bookmarked: ${e.message}");
      print("[MARK_BOOKMARKED] Details: ${e.details}, Hint: ${e.hint}");
      throw Exception("Failed to update scan bookmark status: ${e.message}");
    } catch (e) {
      print("[MARK_BOOKMARKED] #ERROR# Unexpected error marking scan as bookmarked: $e");
      throw Exception("An unexpected error occurred while updating scan bookmark status.");
    }
  }

  Future<List<ScanData>> fetchScanHistory({
    required String userId,
    required String userMembershipTier,
    RiskLevel? filterByRiskLevel,
    bool? filterByBookmarked,
    int? clientRequestedLimit,
  }) async {
    if (userId.isEmpty) {
      print("[FETCH_HISTORY_FILTERED] Cannot fetch history: User ID is empty.");
      return [];
    }
    print("[FETCH_HISTORY_FILTERED] Fetching scan history for user: $userId, Tier: $userMembershipTier");
    if (filterByRiskLevel != null) {
      print("[FETCH_HISTORY_FILTERED] Applying RiskLevel filter: ${riskLevelToString(filterByRiskLevel)}");
    }
    if (filterByBookmarked != null && filterByBookmarked) {
      print("[FETCH_HISTORY_FILTERED] Applying Bookmarked filter: true");
    }

    try {
      var filterBuilder = _supabaseClient
          .from(_historyTableName)
          .select()
          .eq('user_id', userId);

      if (filterByRiskLevel != null) {
        filterBuilder = filterBuilder.eq('risk_level', riskLevelToString(filterByRiskLevel));
      }

      if (filterByBookmarked != null && filterByBookmarked) {
        filterBuilder = filterBuilder.eq('is_bookmarked', true);
      }
      
      // Default order by scanned_at (or created_at if scanned_at isn't consistently available for all records)
      // logScanToHistory uses 'scanned_at'. fetchRecentScanHistory orders by 'created_at'.
      // Let's use 'scanned_at' for consistency with the new search and log, assuming it's reliable.
      // If 'created_at' is more reliable or the primary sort key, adjust this.
      // For now, sticking to existing 'created_at' as per other fetch methods.
      PostgrestTransformBuilder transformBuilder = filterBuilder.order('created_at', ascending: false);

      if (userMembershipTier == 'free') {
        print("[FETCH_HISTORY_FILTERED] Free user detected. Applying limit of $FREE_USER_SCAN_HISTORY_LIMIT items to filtered results.");
        transformBuilder = transformBuilder.limit(FREE_USER_SCAN_HISTORY_LIMIT);
      } else if (clientRequestedLimit != null) {
        print("[FETCH_HISTORY_FILTERED] Premium user with client-requested limit: $clientRequestedLimit");
        transformBuilder = transformBuilder.limit(clientRequestedLimit);
      }

      final response = await transformBuilder;

      if (response is List) {
        final List<ScanData> history = response.map((item) {
          final mapItem = item as Map<String, dynamic>;
          return ScanData.fromDbMap(mapItem);
        }).toList();
        print("[FETCH_HISTORY_FILTERED] Fetched ${history.length} items with applied filters.");
        return history;
      }
      print("[FETCH_HISTORY_FILTERED] Response was not a List or was empty. Type: ${response.runtimeType}");
      return [];

    } catch (e, stacktrace) {
      print("[FETCH_HISTORY_FILTERED] #ERROR# Fetching filtered history: $e");
      print("[FETCH_HISTORY_FILTERED] Stacktrace: $stacktrace");
      throw Exception("Failed to fetch filtered scan history: $e");
    }
  }

  Future<List<ScanData>> fetchOnlyBookmarkedScans(
    String userId, {
    required String userMembershipTier,
    int? limit,
  }) async {
    if (userId.isEmpty) {
      print("[FETCH_BOOKMARKED] Cannot fetch: User ID is empty.");
      return [];
    }
    print("[FETCH_BOOKMARKED] Fetching BOOKMARKED scan history for user: $userId, Tier: $userMembershipTier, limit: $limit (using new filtered fetch)");
    try {
      return await fetchScanHistory(
        userId: userId,
        userMembershipTier: userMembershipTier,
        filterByBookmarked: true,
        clientRequestedLimit: limit,
      );
    } catch (e) {
      print("[FETCH_BOOKMARKED] #ERROR# (via fetchScanHistory) Fetching bookmarked scan history: $e");
      throw Exception("Failed to fetch bookmarked scan history (via new method): $e");
    }
  }


  Future<List<ScanData>> fetchRecentScanHistory(String userId, {int limit = 3}) async {
     if (userId.isEmpty) {
      print("[FETCH_RECENT_HISTORY] User ID empty. Cannot fetch recent scans.");
      return [];
     }
     print("[FETCH_RECENT_HISTORY] Fetching $limit recent scans for user: $userId");
     try {
       final response = await _supabaseClient
           .from(_historyTableName)
           .select()
           .eq('user_id', userId)
           .order('created_at', ascending: false) // Existing code uses created_at here
           .limit(limit);

       final List<ScanData> recentHistory = List<Map<String, dynamic>>.from(response)
           .map((item) => ScanData.fromDbMap(item))
           .toList();
       print("[FETCH_RECENT_HISTORY] Fetched ${recentHistory.length} recent items.");
       return recentHistory;
     } catch (e) {
      print("[FETCH_RECENT_HISTORY] #ERROR# Fetching recent history: $e");
      throw Exception("Failed to fetch recent scan history.");
     }
   }

  // Existing searchScanHistory method - kept for reference or other uses if any
  Future<List<ScanData>> searchScanHistory(String userId, String query) async {
    if (userId.isEmpty) return [];
    if (query.trim().isEmpty) return [];
    print("[SEARCH_HISTORY_OLD] Searching for '$query' for user: $userId (using product_name and created_at)");
    final searchPattern = '%${query.trim()}%';
    try {
      final response = await _supabaseClient
          .from(_historyTableName)
          .select()
          .eq('user_id', userId)
          .ilike('product_name', searchPattern)
          .order('created_at', ascending: false); // Orders by created_at
      final List<ScanData> results = List<Map<String, dynamic>>.from(response)
          .map((item) => ScanData.fromDbMap(item))
          .toList();
      print("[SEARCH_HISTORY_OLD] Found ${results.length} items for query '$query'.");
      return results;
    } catch (e) {
      print("[SEARCH_HISTORY_OLD] #ERROR# Searching history: $e");
      throw Exception("Failed to search scan history.");
    }
  }

  // Method to be added as per Step 2, Action 2
  // This method specifically searches the user's own scan history by product name
  // and orders by 'scanned_at'.
  Future<List<ScanData>> searchUserScanHistoryByName(String userId, String searchTerm, {int limit = 10}) async {
    if (searchTerm.isEmpty) return [];
    // Sanitize searchTerm to prevent SQL injection-like patterns if Supabase doesn't handle this inherently for ilike.
    // For Supabase `ilike`, direct user input for the pattern part (e.g. %term%) is generally safe.
    final String searchPattern = '%${searchTerm.trim()}%';

    print("[ScanHistoryService.searchUserScanHistoryByName] Searching USER scan history for '$searchTerm' (pattern: '$searchPattern') for user $userId");
    try {
      final response = await _supabaseClient // Use existing _supabaseClient
          .from(_historyTableName) // Use existing _historyTableName
          .select()
          .eq('user_id', userId) // Filter by current user
          .ilike('product_name', searchPattern) // Use sanitized searchPattern
          .order('scanned_at', ascending: false) // Order by scanned_at as specified
          .limit(limit);
      
      // Process the response (which is List<dynamic> or List<Map<String, dynamic>>)
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      return data.map((item) => ScanData.fromDbMap(item)).toList();
    } catch (e) {
      print("[ScanHistoryService.searchUserScanHistoryByName] Error searching user's scan history: $e");
      // It's often better to throw a more specific custom exception or the original Supabase exception
      // if callers need to distinguish error types. For now, adhering to prompt.
      throw Exception("Failed to search your history: $e");
    }
  }

  String _extractFilePathFromUrl(String publicUrl) {
    try {
        final uri = Uri.parse(publicUrl);
        int bucketNameIndex = -1;
        for (int i = 0; i < uri.pathSegments.length; i++) {
            if (uri.pathSegments[i] == _storageBucketName) {
                bucketNameIndex = i;
                break;
            }
        }
        if (bucketNameIndex != -1 && bucketNameIndex < uri.pathSegments.length - 1) {
            return uri.pathSegments.sublist(bucketNameIndex + 1).join('/');
        }
    } catch (e) {
        print("[SERVICE_IMG_PATH_UTIL] Error parsing URL '$publicUrl': $e");
    }
    print("[SERVICE_IMG_PATH_UTIL] Could not extract valid file path from URL: $publicUrl");
    return '';
  }


  Future<void> deleteAllUserHistory(String userId) async {
    if (userId.isEmpty) throw Exception("User ID required to delete all history.");
    print("[DELETE_ALL_HISTORY] Attempting for user: $userId");
    try {
      final List<dynamic> imageRecords = await _supabaseClient
          .from(_historyTableName)
          .select('product_image_url')
          .eq('user_id', userId);

      final List<String> filePathsInBucketToDelete = imageRecords
          .map((item) => item['product_image_url'] as String?)
          .where((url) => url != null && url.isNotEmpty)
          .map((url) => _extractFilePathFromUrl(url!))
          .where((path) => path.isNotEmpty)
          .toList();

      if (filePathsInBucketToDelete.isNotEmpty) {
        print("[DELETE_ALL_HISTORY] Deleting ${filePathsInBucketToDelete.length} images from Storage '$_storageBucketName'. Paths: $filePathsInBucketToDelete");
        final List<FileObject> deletedFiles = await _supabaseClient.storage
            .from(_storageBucketName)
            .remove(filePathsInBucketToDelete);
        print("[DELETE_ALL_HISTORY] ${deletedFiles.length} images confirmed deleted from storage.");
      } else {
        print("[DELETE_ALL_HISTORY] No images found in history to delete from Storage.");
      }
      print("[DELETE_ALL_HISTORY] Deleting records from '$_historyTableName' for user $userId.");
      await _supabaseClient.from(_historyTableName).delete().eq('user_id', userId);
      print("[DELETE_ALL_HISTORY] All history records deleted successfully for user: $userId");
    } catch (e) {
      print("[DELETE_ALL_HISTORY] #ERROR# Deleting all user history: $e");
      String errorMessage = "An unexpected error occurred while deleting history.";
      if (e is PostgrestException) errorMessage = "Failed to delete history records: ${e.message}";
      if (e is StorageException) errorMessage = "Failed to delete associated images: ${e.message}";
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteScanHistoryItem(String scanId, String? imageUrl, String userId) async {
    if (userId.isEmpty) throw Exception("User ID required.");
    if (scanId.isEmpty) throw Exception("Scan ID required.");
    print("[DELETE_ITEM] Attempting for scanId: $scanId, user: $userId");
    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final filePathInBucket = _extractFilePathFromUrl(imageUrl);
        if (filePathInBucket.isNotEmpty) {
          print("[DELETE_ITEM] Deleting image '$filePathInBucket' from Storage '$_storageBucketName'.");
          await _supabaseClient.storage.from(_storageBucketName).remove([filePathInBucket]);
          print("[DELETE_ITEM] Image deletion initiated for '$filePathInBucket'.");
        } else {
           print("[DELETE_ITEM] #WARN# Could not parse storage path from URL: $imageUrl. Image not deleted from storage.");
        }
      }
      await _supabaseClient
          .from(_historyTableName)
          .delete()
          .match({'id': scanId, 'user_id': userId});
      print("[DELETE_ITEM] Deleted record $scanId from '$_historyTableName'.");
    } catch (e) {
      print("[DELETE_ITEM] #ERROR# Deleting item $scanId: $e");
      String errorMessage = "An unexpected error occurred while deleting the item.";
      if (e is PostgrestException) errorMessage = "Failed to delete item from database: ${e.message}";
      if (e is StorageException) errorMessage = "Failed to delete associated image: ${e.message}";
      throw Exception(errorMessage);
    }
  }
}