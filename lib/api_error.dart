import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Decodes JSON safely; returns null if the body isn't valid JSON.
Map<String, dynamic>? tryDecode(String body) {
  try {
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// Turns a failed response into a message that says what went wrong.
String messageForResponse(int status, Map<String, dynamic>? data, String fallback) {
  final detail = data?['detail'];
  if (detail is String && detail.isNotEmpty) return detail;

  switch (status) {
    case 400:
      return fallback;
    case 401:
      return 'Incorrect email or password.';
    case 404:
      return 'Service not found (404). The server is reachable but this endpoint doesn\'t exist.';
    case 409:
      return 'An account with these details already exists.';
    case 422:
      return 'Some of the details you entered are invalid.';
    case 429:
      return 'Too many attempts. Please wait a moment and try again.';
    case 500:
    case 502:
    case 503:
      return 'The server is having problems or still waking up. Try again in a minute.';
    default:
      return '$fallback (error $status)';
  }
}

/// Turns a thrown exception into a readable message.
String messageForException(Object e) {
  if (e is TimeoutException) {
    return 'The server took too long to respond. It may be waking up, so try again.';
  }
  if (e is SocketException) {
    return 'No internet connection, or the server can\'t be reached.';
  }
  if (e is http.ClientException) {
    return 'Couldn\'t connect to the server. Check your connection.';
  }
  if (e is FormatException) {
    return 'The server sent an unexpected response. Please try again later.';
  }
  return 'Something went wrong. Please try again.';
}