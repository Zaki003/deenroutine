/// Capitalizes the first letter of every word, leaving the rest of each
/// word untouched — used for display of user-entered names, which are
/// stored exactly as typed.
String capitalizeWords(String value) => value.isEmpty
    ? value
    : value.replaceAllMapped(
        RegExp(r'(^|\s)(\S)'),
        (m) => '${m[1]}${m[2]!.toUpperCase()}',
      );
