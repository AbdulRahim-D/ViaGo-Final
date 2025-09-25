import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:packmate/models/parcel.dart';
import 'package:packmate/services/firestore_service.dart';
import 'package:packmate/services/wallet_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CancellationRefundScreen extends StatefulWidget {
  const CancellationRefundScreen({super.key});

  @override
  State<CancellationRefundScreen> createState() =>
      _CancellationRefundScreenState();
}

class _CancellationRefundScreenState extends State<CancellationRefundScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final FirestoreService _firestoreService;
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _firestoreService = FirestoreService();
      _walletService = WalletService(currentUser!.uid);
    }
  }

  Future<void> _processRefund(Parcel parcel) async {
    if (currentUser == null) return;

    // Show a confirmation dialog before proceeding
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Confirm Refund',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to refund ₹${parcel.price.toStringAsFixed(2)} to your wallet?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd79141),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Refund',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    // Show a loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(
          color: Color(0xFFf8af0b),
        )),
      );
    }

    try {
      // Use the wallet service to process the refund
      await _walletService.refundMoney(
          currentUser!.uid, parcel.price, parcel.id);

      // Update the parcel to mark as refunded
      await _firestoreService
          .updateParcel(parcel.id, {'refundStatus': 'refunded'});

      // Close the loading indicator
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                'Refund processed successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFFa8ad5f)),
        );
      }
    } catch (e) {
      // Close the loading indicator
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                'Error processing refund: $e',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFFd79141)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Cancellation & Refund",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF514ca1),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'Please log in to view this page.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF6c5050),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Cancellation & Refund",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF514ca1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Parcel>>(
        stream: _firestoreService.streamMyCancelledParcelsAsSender(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFf8af0b)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(),
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'You have no cancelled packages.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6c5050),
                ),
              ),
            );
          }

          final cancelledParcels = snapshot.data!;

          return ListView.builder(
            itemCount: cancelledParcels.length,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            itemBuilder: (context, index) {
              final parcel = cancelledParcels[index];
              final bool wasPaid = parcel.paymentStatus == 'paid';
              final bool isRefunded = parcel.refundStatus == 'refunded';

              return Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parcel: ${parcel.contents}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6c5050)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To: ${parcel.receiverName}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6c5050)),
                            ),
                            Text(
                              'Price: ₹${parcel.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6c5050)),
                            ),
                            Text(
                              'Status: ${parcel.status}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6c5050)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (wasPaid)
                            Chip(
                              label: Text(
                                'Paid',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFFa8ad5f), // Accent Olive Green
                            )
                          else
                            Chip(
                              label: Text(
                                'Not Paid',
                                style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
                              ),
                              backgroundColor: const Color(0xFFf8af0b), // Highlight Yellow-Orange
                            ),
                          const SizedBox(height: 8),
                          if (wasPaid && !isRefunded)
                            ElevatedButton(
                              onPressed: () => _processRefund(parcel),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFd79141), // Accent Orange
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Refund',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (wasPaid && isRefunded)
                            Chip(
                              label: Text(
                                'Refunded',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFFa8ad5f), // Accent Olive Green
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
