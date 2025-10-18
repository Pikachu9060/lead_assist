import 'package:cloud_firestore/cloud_firestore.dart';

class DateUtilHelper {
  static String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
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
    if (timestamp == null) return 'Unknown date';
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
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