/// Result of a registration attempt.
enum RegisterStatus {
  /// API/network failure — see [AuthProvider.error]
  failed,

  /// Account created and Sanctum session established
  signedIn,

  /// Account created; user must enter the 6-digit email code
  needsEmailVerification,
}
