class PasswordValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return "Password wajib diisi";
    }

    if (value.length < 8) {
      return "Minimal 8 karakter";
    }

    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));

    if (!hasUppercase || !hasLowercase || !hasDigits) {
      return "Harus mengandung huruf besar, kecil, dan angka";
    }

    return null;
  }
}
