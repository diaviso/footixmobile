import '../constants/api_constants.dart';

/// Utility functions for generating user avatars
/// Uses DiceBear API for fun, colorful cartoon avatars

class AvatarUtils {
  /// Generate a DiceBear avatar URL for a user
  /// Uses "lorelei" style for elegant, colorful avatars
  static String generateDiceBearUrl(String seed) {
    return 'https://api.dicebear.com/9.x/lorelei/svg?seed=${seed}&backgroundColor=ffcdd2,ffd54f,ef5350,ffb74d&backgroundType=gradientLinear';
  }

  /// Build full avatar URL from relative path
  /// Returns null if avatarPath is null or empty
  static String? buildAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }
    if (avatarPath.startsWith('http')) {
      return avatarPath;
    }
    // Relative path - prepend API base URL
    return '${ApiConstants.baseUrl}$avatarPath';
  }

  /// Get avatar URL - returns user's avatar if set, otherwise generates a DiceBear avatar
  /// This is the main method to use for displaying avatars
  static String getAvatarUrl(String? avatarPath, String userId) {
    final fullUrl = buildAvatarUrl(avatarPath);
    if (fullUrl != null) {
      return fullUrl;
    }
    // Generate DiceBear avatar as fallback
    return generateDiceBearUrl(userId);
  }

  /// Check if user has a real avatar (not DiceBear)
  static bool hasRealAvatar(String? avatarPath) {
    return avatarPath != null && avatarPath.isNotEmpty;
  }

  /// Legacy method name for compatibility
  static String generateAvatarUrl(String seed) => generateDiceBearUrl(seed);
}
