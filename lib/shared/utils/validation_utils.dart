// utils/validation_utils.dart
class ValidationUtils {
  static String validateRequired(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return '';
  }

  static String validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }

    return '';
  }

  static String validateMobile(String mobile) {
    if (mobile.trim().isEmpty) {
      return 'Mobile number is required';
    }

    // Basic mobile validation - adjust based on your requirements
    final mobileRegex = RegExp(r'^[0-9]{10}$');
    if (!mobileRegex.hasMatch(mobile.trim().replaceAll(RegExp(r'[^0-9]'), ''))) {
      return 'Please enter a valid mobile number';
    }

    return '';
  }
}