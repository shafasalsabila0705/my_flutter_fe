import 'package:intl/intl.dart';

class DateHelper {
  /// Formats a DateTime object to `dd-MM-yyyy`.
  static String formatDateTime(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  /// Parses a String (assumed yyyy-MM-dd) and formats it to `dd-MM-yyyy`.
  /// Returns the original string or "-" if parsing fails.
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == '-') {
      return '-';
    }
    
    try {
      // Handle "yyyy-MM-dd" or "yyyy-MM-dd HH:mm:ss"
      DateTime parsedDate = DateTime.parse(dateString);
      return formatDateTime(parsedDate);
    } catch (e) {
      // If parsing fails, return original string or error indicator
      return dateString; 
    }
  }
}
