import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cancellation_refund_screen.dart';
import 'support_screen.dart';
import 'help_screen.dart';
import 'wallet_screen.dart';
import 'blocked_users_screen.dart';
import 'my_reports_screen.dart';

class MenuScreen extends StatelessWidget {
  final String? username;
  const MenuScreen({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 150,
              padding: const EdgeInsets.only(left: 24.0, bottom: 24.0),
              decoration: const BoxDecoration(
                color: Color(0xFF514ca1), // Primary Purple
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.bottomLeft,
              child: Text(
                "Hello, ${username ?? 'User'}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            _buildMenuItem(
              context,
              icon: Icons.cancel_outlined,
              title: "Cancellation & Refund",
              destination: const CancellationRefundScreen(),
            ),
            _buildMenuItem(
              context,
              icon: Icons.support_agent_outlined,
              title: "Support",
              destination: const SupportScreen(),
            ),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: "Help",
              destination: const HelpScreen(),
            ),
            _buildMenuItem(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: "Wallet",
              destination: const WalletScreen(),
            ),
            _buildMenuItem(
              context,
              icon: Icons.block_outlined,
              title: "Blocked Users",
              destination: const BlockedUsersScreen(),
            ),
            _buildMenuItem(
              context,
              icon: Icons.report_outlined,
              title: "My Reports",
              destination: const MyReportsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String title, required Widget destination}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination),
            );
          },
          splashColor: const Color(0xFFa8ad5f).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF6c5050), // Neutral/Dark Text Warm Brown
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF6c5050),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
