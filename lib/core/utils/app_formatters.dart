import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String shortDate(DateTime date) =>
      DateFormat("dd/MM/yyyy").format(date);

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return "Chúc bạn thức khuya học bài vui vẻ!";
    if (hour < 11) return "Chào buổi sáng!";
    if (hour < 14) return "Chào buổi trưa!";
    if (hour < 18) return "Chào buổi chiều!";
    if (hour < 22) return "Chào buổi tối!";
    return "Khuya rồi, đừng học quá muộn nhé!";
  }

  static String pluralDays(int days) => days <= 1 ? "ngày" : "ngày";
}
