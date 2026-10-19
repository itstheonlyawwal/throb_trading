import 'package:flutter/material.dart';
import 'api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _bgColor = Color(0xFF0B0F19);
  static const Color _cardColor = Color(0xFF141924);
  static const Color _tealColor = Color(0xFF2DD9A8);
  static const Color _borderColor = Color(0xFF232938);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  String _username = '';
  String _email = '';
  String _memberSince = '';
  bool _loading = true;
  bool _saving = false;
  bool _changingPassword = false;
  String? _loadError;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  void _fail(String message) => setState(() {
    _error = message;
    _success = null;
  });

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final p = await ApiService.getProfile();
      if (!mounted) return;
      final created = p['created_at'] as String?;
      setState(() {
        _username = p['username'] ?? '';
        _email = p['email'] ?? '';
        _nameController.text = p['full_name'] ?? '';
        _phoneController.text = p['phone'] ?? '';
        _countryController.text = p['country'] ?? '';
        _memberSince =
        created != null && created.length >= 10 ? created.substring(0, 10) : '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e is ApiExpcetion ? e.message : 'Could not load your profile.';
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ApiService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        country: _countryController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _success = 'Profile updated.');
    } on ApiExpcetion catch (e) {
      if (mounted) _fail(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPwController.text;
    final next = _newPwController.text;
    if (current.isEmpty || next.isEmpty) return _fail('Fill in both password fields.');
    if (next.length < 6) return _fail('New password must be at least 6 characters.');
    if (next != _confirmPwController.text) return _fail('New passwords do not match.');

    setState(() {
      _changingPassword = true;
      _error = null;
      _success = null;
    });
    try {
      await ApiService.changePassword(currentPassword: current, newPassword: next);
      if (!mounted) return;
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
      setState(() => _success = 'Password updated.');
    } on ApiExpcetion catch (e) {
      if (mounted) _fail(e.message);
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 1)),
          SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _readOnly(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {TextInputType? keyboard, bool obscure = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            obscureText: obscure,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: _bgColor,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, bool busy, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _tealColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: busy
            ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _banner(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: _cardColor,
            child: Text(
              _username.isEmpty ? '?' : _username[0].toUpperCase(),
              style: const TextStyle(
                  color: _tealColor, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(_username,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_error != null) _banner(_error!, Colors.red.shade900),
          if (_success != null) _banner(_success!, const Color(0xFF1B6B55)),
          _section('Account', [
            _readOnly('Username', _username),
            _readOnly('Email', _email),
            if (_memberSince.isNotEmpty) _readOnly('Member since', _memberSince),
          ]),
          _section('Personal details', [
            _field('Full name', _nameController),
            _field('Phone', _phoneController, keyboard: TextInputType.phone),
            _field('Country', _countryController),
            _button('Save changes', _saving, _saveProfile),
          ]),
          _section('Change password', [
            _field('Current password', _currentPwController, obscure: true),
            _field('New password', _newPwController, obscure: true),
            _field('Confirm new password', _confirmPwController, obscure: true),
            _button('Update password', _changingPassword, _changePassword),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _tealColor))
            : _loadError != null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        )
            : _content(),
      ),
    );
  }
}