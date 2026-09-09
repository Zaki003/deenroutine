/// Loosely checks the *shape* of an email address (something@something.tld) —
/// not full RFC 5322 validation, just enough to catch obvious nonsense (a
/// bare "@", a missing domain or TLD) before it ever reaches Firebase.
/// Firebase still validates server-side regardless (see 'invalid-email' in
/// auth_error_messages.dart) — this is purely for immediate inline feedback.
bool isValidEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
}
