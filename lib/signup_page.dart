import 'package:flutter/material.dart';
import 'login_page.dart';
import 'main_shell.dart';
import 'user_session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_error.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _invitationController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  static const Color _bgColor = Color(0xFF0B0F19);
  static const Color _tealColor = Color(0xFF2DD9A8);
  static const Color _borderColor = Color(0xFF2A3040);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _invitationController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
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
        Uri.parse('https://throb-backend.onrender.com/signup'), // same URL rule as login
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
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
    response.statusCode, data, 'Could not create your account.'));
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
          style: TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _tealColor),
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
                      // Logo row
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
                        'Create your account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have one? ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Log in',
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
                            style: TextStyle(
                              color: Colors.white, fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildLabel('Username'),
                      ),
                      _buildField(
                        controller: _usernameController,
                        hint: 'Enter your username',
                      ),
                      // TODO: add username validation in lowercase and letters only
                      SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildLabel('Email'),
                      ),
                      _buildField(
                        controller: _emailController,
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildLabel('Password'),
                      ),
                      _buildField(
                        controller: _passwordController,
                        hint: 'Enter your password',
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons
                                .visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() =>
                            _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildLabel('Invitation Code (Optional)'),
                      ),
                      _buildField(
                        controller: _invitationController,
                        hint: 'Enter invitation code',
                      ),
                      SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createAccount,
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'By creating an account you agree to our terms of service and privacy policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
