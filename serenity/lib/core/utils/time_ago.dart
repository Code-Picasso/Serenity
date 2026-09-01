import 'package:intl/intl.dart';

/// Compact relative timestamp for feed/chat/list UIs.
String timeAgo(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(local);
}
