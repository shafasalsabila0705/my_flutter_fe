import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    initializeDateFormatting('id_ID', null);
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
  }

  static String formatTime(DateTime date) {
    initializeDateFormatting('id_ID', null);
    return DateFormat('HH.mm').format(date);
  }
}
