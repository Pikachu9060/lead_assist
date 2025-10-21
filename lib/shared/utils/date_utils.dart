import 'package:cloud_firestore/cloud_firestore.dart';

class DateUtilHelper {
  static String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      // 1. Ensure it's treated as a String for parsing
      final String dateString = timestamp.toString();

      // 2. Parse the string into a DateTime object
      final date = DateTime.parse(dateString);

      // 3. Manually format the output (ensure two digits for day/month)
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;

      return '$day/$month/$year';

    } catch (e) {
      // This will catch the error if the string format is unexpected
      return 'Invalid date';
    }
  }

  static DateTime parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  static String formatDateTime(dynamic timestamp) {
    // If the input is null, handle it gracefully
    if (timestamp == null) {
      return 'Unknown Date';
    }

    try {
      // 1. SAFE CAST: Treat the dynamic variable as a standard Dart DateTime.
      // We already know from the error that it is an Instance of 'DateTime'.
      final DateTime date = timestamp as DateTime;

      // 2. Format the output string using direct access
      // Pad minute (and second, if needed) to ensure two digits
      final minute = date.minute.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final seconds = date.second.toString().padLeft(2, '0');

      return '$day/$month/${date.year} $hour:$minute:$seconds';

    } catch (e) {
      // This catch block will execute if:
      // a) The input is NOT a DateTime (e.g., it's a String that needs parsing)
      // b) The input is completely malformed (e.g., 55)
      print("Error formatting date: $e");
      return 'Invalid Date';
    }
  }

  static String formatDateWithTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = timestamp.toDate();
      return '${_formatTime(date)} • ${_formatDate(date)}';
    } catch (e) {
      return '';
    }
  }

  static String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}