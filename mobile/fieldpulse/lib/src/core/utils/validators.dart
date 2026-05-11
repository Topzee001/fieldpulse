class Validators {
  static String? validateField(String? value, {bool required = false, String? type}) {
    if (required && (value == null || value.isEmpty)) {
      return 'This field is required';
    }
    if (value == null || value.isEmpty) return null;

    switch (type) {
      case 'email':
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
        break;
      case 'phone':
        final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.length < 10) return 'Enter a valid phone number';
        break;
      case 'number':
        if (double.tryParse(value) == null) return 'Must be a number';
        break;
    }
    return null;
  }

  static String? validateNumber(num? value, {num? min, num? max}) {
    if (min != null && value != null && value < min) return 'Minimum value is $min';
    if (max != null && value != null && value > max) return 'Maximum value is $max';
    return null;
  }
}