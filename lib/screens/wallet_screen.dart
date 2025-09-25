import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:packmate/models/wallet.dart';
import 'package:packmate/models/wallet_transaction.dart';
import 'package:packmate/services/wallet_service.dart';
import 'package:packmate/screens/add_money_screen.dart';
import 'package:packmate/screens/withdraw_money_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletService _walletService;

  // Define the brand colors as constants
  static const Color primaryPurple = Color(0xFF514ca1);
  static const Color accentOliveGreen = Color(0xFFa8ad5f);
  static const Color accentOrange = Color(0xFFd79141);
  static const Color highlightYellowOrange = Color(0xFFf8af0b);
  static const Color neutralWarmBrown = Color(0xFF6c5050);

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      return;
    }
    _walletService = WalletService(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Wallet",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: neutralWarmBrown,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFf5f5f5), // A very light gray background
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: neutralWarmBrown,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildTransactionList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<Wallet>(
        stream: _walletService.walletStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final wallet = snapshot.data!;
          return Column(
            children: [
              const Text(
                'Current Balance',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500, // Medium font weight
                  color: neutralWarmBrown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${wallet.balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: highlightYellowOrange,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddMoneyScreen(walletService: _walletService)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Add Money'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => WithdrawMoneyScreen(walletService: _walletService)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentOliveGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Withdraw'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<List<WalletTransaction>>(
      stream: _walletService.transactionsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data!;
        if (transactions.isEmpty) {
          return const Center(
            child: Text(
              'No transactions yet.',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: neutralWarmBrown,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isDeposit = transaction.type == TransactionType.deposit || transaction.type == TransactionType.refund;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isDeposit ? accentOliveGreen.withOpacity(0.1) : accentOrange.withOpacity(0.1),
                    child: Icon(
                      isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isDeposit ? accentOliveGreen : accentOrange,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction.type.toString().split('.').last,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: neutralWarmBrown,
                    ),
                  ),
                  subtitle: Text(
                    'Parcel ID: ${transaction.parcelId ?? 'N/A'}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: neutralWarmBrown.withOpacity(0.7),
                    ),
                  ),
                  trailing: Text(
                    '${isDeposit ? '+' : ''}₹${transaction.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: isDeposit ? accentOliveGreen : accentOrange,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}