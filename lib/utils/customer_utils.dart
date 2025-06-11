// lib/utils/customer_utils.dart

String sanitizePhoneNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.startsWith('+')) {
    return '+${trimmed.substring(1).replaceAll(RegExp(r'\D'), '')}';
  } else {
    return trimmed.replaceAll(RegExp(r'\D'), '');
  }
}

bool isValidPhoneNumber(String input) {
  final regex = RegExp(r'^\+?[0-9]+$');
  return regex.hasMatch(input.trim());
}
