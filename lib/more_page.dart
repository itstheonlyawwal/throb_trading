import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'signals_page.dart';
import 'refer_page.dart';
import 'login_page.dart';
import 'withdraw_page.dart';

class MorePage extends StatelessWidget {
  final double balance;

  const MorePage({super.key, this.balance = 0.0});


  static const Color _bgColor = Color(0xFF0B0F19);
  static const Color _cardColor = Color(0xFF141924);
  static const Color _tealColor = Color(0xFF2DD9A8);
  static const Color _borderColor = Color(0xFF232938);

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _cardColor,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: _tealColor, size: 22),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label — coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                _buildSectionTitle('Trading'),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildTile(
                      context,
                      Icons.graphic_eq,
                      'Signals',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignalsPage()),
                      ),
                    ),
                    _buildTile(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'Withdraw',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WithdrawPage(balance: balance),
                        ),
                      ),
                    ),
                    _buildTile(
                      context,
                      Icons.refresh,
                      'Refer a Friend',
                      () => Navigator.push(
                        context,
                          MaterialPageRoute(builder: (context) => ReferPage()),
                    ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildSectionTitle('Account'),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildTile(
                      context,
                      Icons.person_outline,
                      'Profile',
                      () => Navigator.push(
                        context,
                          MaterialPageRoute(builder: (context) => ProfilePage()),
                      ),
                    ),
                    _buildTile(context, Icons.logout, 'Log Out', () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false,
                      ); // TODO: clear session/auth state, then send back to login
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
