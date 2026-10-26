import 'package:intl/intl.dart';

final DateFormat _cardDate = DateFormat('MMM d, yyyy');
final DateFormat _eventDate = DateFormat('EEE, MMM d');
final DateFormat _eventTime = DateFormat('h:mm a');

String formatDate(DateTime date) => _cardDate.format(date);

String formatEventWhen(DateTime dateTime) => '${_eventDate.format(dateTime)} · ${_eventTime.format(dateTime)}';
