/// Simple mobile number helper — digits only, max 11.
class PhMobileNumber {
  static String normalize(String input) {
    return input.trim().replaceAll(RegExp(r'\D'), '');
  }

  static bool isValid(String input) {
    final digits = normalize(input);
    return digits.length == 11;
  }

  /// Returns an error message, or `null` if valid.
  /// When [required] is false, empty input is allowed.
  static String? validate(String? input, {bool required = false}) {
    final value = input?.trim() ?? '';

    if (value.isEmpty) {
      return required ? 'Mobile number is required.' : null;
    }

    final digits = normalize(value);
    if (digits.length > 11) {
      return 'Mobile number must be at most 11 digits.';
    }
    if (digits.length != 11) {
      return 'Enter an 11-digit mobile number.';
    }

    return null;
  }
}
