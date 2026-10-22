import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'main_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_session.dart';
import 'api_error.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  static const Color _bgColor = Color(0xFF0B0F19);
  static const Color _tealColor = Color(0xFF2DD9A8);
  static const Color _fieldColor = Color(0xFFE8EAF2);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    final emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://throb-trading.onrender.com/login'), // see note below about this URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password
        }),
      )

          .timeout(const Duration(seconds: 60));

      final data = tryDecode(response.body);

      if (response.statusCode == 200 && data != null) {
        UserSession.instance.username = data['username'];
        UserSession.instance.token = data['token'];

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainShell()),
        );
      } else {
        if (!mounted) return;
        setState(() => _error = messageForResponse(
            response.statusCode, data, 'Could not log you in.'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageForException(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: _fieldColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo row: waveform icon + "throb."
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.graphic_eq, color: _tealColor, size: 22),
                      SizedBox(width: 6),
                      Text(
                        'throb.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Log in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New here? ',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignupPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Create an account',
                          style: TextStyle(
                            color: _tealColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28),

                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildLabel('Email'),
                  ),
                  _buildField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'you@example.com',
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildLabel('Password'),
                  ),
                  _buildField(
                    controller: _passwordController,
                    hint: 'Your Password',
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tealColor,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 250),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Throb Trading Technologies Limited 2026',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
