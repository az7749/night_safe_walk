import 'package:flutter/services.dart';

String phoneNumberDigits(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

String formatPhoneNumber(String value) {
  final digits = phoneNumberDigits(value);
  final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

  if (limited.length <= 3) return limited;
  if (limited.length <= 7) {
    return '${limited.substring(0, 3)}-${limited.substring(3)}';
  }
  if (limited.length == 10) {
    return '${limited.substring(0, 3)}-${limited.substring(3, 6)}-${limited.substring(6)}';
  }
  return '${limited.substring(0, 3)}-${limited.substring(3, 7)}-${limited.substring(7)}';
}

class PhoneNumberInputFormatter extends TextInputFormatter {
  const PhoneNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatPhoneNumber(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
