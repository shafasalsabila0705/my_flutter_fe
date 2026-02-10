class PasswordValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return "Password wajib diisi";
    }

    List<String> errors = [];
    if (value.length < 8) errors.add("- Minimal 8 karakter");
    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add("- Harus ada huruf besar");
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      errors.add("- Harus ada huruf kecil");
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add("- Harus ada angka");
    }

    if (errors.isNotEmpty) {
      return "Password tidak memenuhi syarat:\n${errors.join('\n')}";
    }

    return null;
  }
}
