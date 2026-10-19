import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'user_session.dart';

class ApiExpcetion implements Exception {
  final String message;
  ApiExpcetion(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://10.133.145.107:8000';

  static Map<String, String> _headers({bool auth = false}) {
    final header = {'Content-Type': 'application/json'};
    if (auth) {
      final token = UserSession.instance.token;
      if (token == null) throw ApiExpcetion('you are not logged in.');
      header['Authorization'] = 'Bearer $token';
    }
    return header;
  }

  static String _detailOf(dynamic data, int status) {
    final detail = data is Map ? data ['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final first = detail.first as Map;
      return (detail.first['message'] ?? 'Invalid input').toString();
    }
    return 'Request failed ($status)';
  }

  static Future<dynamic> _request(String method,
      String path, {
        Map<String, dynamic>? body,
        bool auth = false,
      }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _headers(auth: auth);
    final encoded = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      final Future<http.Response> call;
      switch (method) {
        case 'POST':
          call = http.post(uri, headers: headers, body: encoded);
          break;
        case 'PUT':
          call = http.put(uri, headers: headers, body: encoded);
          break;
        default:
          call = http.get(uri, headers: headers);
      }
      response = await call.timeout(Duration(seconds: 60));
    } catch (e) {
      throw ApiExpcetion('Could not reach the server. Check your connection. ');
    }

    debugPrint('$method $uri -> ${response.statusCode} ${response.body}');

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw ApiExpcetion(
          'unexpected reply from server (status ${response.statusCode}). Check the server URL.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw ApiExpcetion(_detailOf(data, response.statusCode));
  }

  static void _saveSession(Map<String, dynamic> data) {
    UserSession.instance.username = data['username'];
    UserSession.instance.token = data['token'];
  }

  // ---------------- Auth -----------------

static Future<void> signup({
    required String email,
  required String username,
  required String password,
  String? invitationCode,
}) async {
    final data = await _request('POST', '/signup', body: {'email': email, 'username': username, 'password': password,
      if (invitationCode != null && invitationCode.isNotEmpty)
        'invitation_code': invitationCode,
    });
    _saveSession(data as Map<String, dynamic>);
}

static Future<void> login({
    required String email,
  required String password,
}) async {
    final data = await _request('POST', '/login', body: {'email': email, 'password': password});
    _saveSession(data as Map<String, dynamic>);
}

// ------------------ Profile ------------------

static Future<Map<String, dynamic>> getProfile() async {
    final data = await _request('GET', '/profile', auth: true);
    return data as Map<String, dynamic>;
}

static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
  String? phone,
  String? country,
}) async {
    final data = await _request('PUT', '/profile', auth: true, body: {
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (country != null) 'country': country,
    });
    return data as Map<String, dynamic>;
}

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _request('POST', '/profile/change-password', auth: true, body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

// ------------- Balance ---------------

static Future<double> getBalance() async {
    final data = await _request('GET', '/balance', auth: true);
    return ((data as Map<String, dynamic>)['balance'] as num).toDouble();
}

// ------------- Deposit / Withdrawal / History (NEW) ---------------

  /// Creates a pending deposit. The balance only changes once an admin approves it.
  static Future<Map<String, dynamic>> deposit(double amount) async {
    final data = await _request('POST', '/deposits',
        auth: true, body: {'amount': amount});
    return data as Map<String, dynamic>;
  }

  /// Holds the amount and creates a pending withdrawal for admin approval.
  /// Throws ApiExpcetion('Insufficient funds') if the balance is too low.
  static Future<Map<String, dynamic>> withdraw(double amount) async {
    final data = await _request('POST', '/withdrawals',
        auth: true, body: {'amount': amount});
    return data as Map<String, dynamic>;
  }

  /// Each item: id, type, amount, status, note, created_at
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final data = await _request('GET', '/transactions', auth: true);
    return (data as List).cast<Map<String, dynamic>>();
  }
}











