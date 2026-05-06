String? validateEmail(String? v) {
  final val = v?.trim() ?? '';
  if (val.isEmpty) return 'Email is required';
  if (val.length > 254) return 'Email must be under 254 characters';
  final atIndex = val.indexOf('@');
  if (atIndex <= 0) return 'Enter a valid email address';
  final domain = val.substring(atIndex + 1);
  if (domain.isEmpty || !domain.contains('.') || domain.endsWith('.')) {
    return 'Enter a valid email address';
  }
  return null;
}
