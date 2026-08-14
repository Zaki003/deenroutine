/// Capitalizes just the first character, leaving the rest untouched — used
/// for display of user-entered names, which are stored exactly as typed.
String capitalizeFirst(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
