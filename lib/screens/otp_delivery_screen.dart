// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packmate/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpDeliveryScreen extends StatefulWidget {
  final String parcelId;
  const OtpDeliveryScreen({super.key, required this.parcelId});

  @override
  State<OtpDeliveryScreen> createState() => _OtpDeliveryScreenState();
}

class _OtpDeliveryScreenState extends State<OtpDeliveryScreen> {
  final _otpCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isOtpSent = false;
  bool _isSendingOtp = false;

  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('parcels')
          .doc(widget.parcelId)
          .get();
      final parcel = snap.data();

      if (parcel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Parcel not found.")),
        );
        return;
      }

      final who = parcel['confirmationWho'] ?? 'receiver';
      final targetUid = who == 'sender'
          ? parcel['createdByUid']
          : (parcel['trackedReceiverUid'] ?? parcel['receiverUid']);

      if (targetUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error: The designated receiver has not registered or started tracking this parcel yet.')),
        );
        return;
      }

      await _firestoreService.createAndSendOtp(
        parcelId: widget.parcelId,
        type: 'delivery',
        targetUid: targetUid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent successfully.")));
      setState(() {
        _isOtpSent = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP: $e")),
      );
    } finally {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final entered = _otpCtrl.text.trim();
    if (entered.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter the OTP.")));
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('parcels')
        .doc(widget.parcelId)
        .get();
    final data = snap.data();
    final pending = data?['pendingOtp'];

    if (pending != null &&
        pending['type'] == 'delivery' &&
        pending['code'] == entered) {
      await FirebaseFirestore.instance
          .collection('parcels')
          .doc(widget.parcelId)
          .update({
        'pendingOtp': FieldValue.delete(),
        'status': 'delivered',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Delivery confirmed!")));
      Navigator.pop(context); // Go back from OTP screen
      Navigator.pop(context); // Go back from package detail screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP. Please try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Confirm Delivery",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF514ca1),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isOtpSent)
                ElevatedButton(
                  onPressed: _isSendingOtp ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF514ca1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: const Color(0xFF514ca1).withOpacity(0.5),
                  ),
                  child: _isSendingOtp
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Send OTP to Recipient",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              if (_isOtpSent) ...[
                Text(
                  "An OTP has been sent. Please enter it below to confirm the delivery.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF6c5050),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6c5050),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: "Enter OTP",
                    labelStyle: GoogleFonts.poppins(
                      color: const Color(0xFF6c5050).withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFd79141),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFd79141),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: const Color(0xFFd79141).withOpacity(0.5),
                  ),
                  child: Text(
                    "Verify OTP & Complete Delivery",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}