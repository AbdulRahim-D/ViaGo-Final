import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpConfirmScreen extends StatefulWidget {
  final String parcelId;
  const OtpConfirmScreen({super.key, required this.parcelId});

  @override
  State<OtpConfirmScreen> createState() => _OtpConfirmScreenState();
}

class _OtpConfirmScreenState extends State<OtpConfirmScreen> {
  final _otpCtrl = TextEditingController();
  final _svc = FirebaseFirestore.instance;

  Future<void> _sendOtp() async {
    final snap = await _svc.collection('parcels').doc(widget.parcelId).get();
    final parcel = snap.data()!;
    final senderUid = parcel['createdByUid'];

    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString()
        .substring(0, 6);

    await _svc.collection('parcels').doc(widget.parcelId).update({
      'pendingOtp': {'type': 'confirm', 'code': otp, 'toUid': senderUid},
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // notify sender
    final notif = _svc
        .collection('users')
        .doc(senderUid)
        .collection('notifications')
        .doc();
    await notif.set({
      'id': notif.id,
      'parcelId': widget.parcelId,
      'type': 'confirm',
      'code': otp,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("OTP sent to sender")));
  }

  Future<void> _verifyOtp() async {
    final entered = _otpCtrl.text.trim();
    final snap = await _svc.collection('parcels').doc(widget.parcelId).get();
    final data = snap.data()!;
    final pending = data['pendingOtp'];

    if (pending != null &&
        pending['type'] == 'confirm' &&
        pending['code'] == entered) {
      await _svc.collection('parcels').doc(widget.parcelId).update({
        'pendingOtp': FieldValue.delete(),
        'status': 'in_transit',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Order confirmed")));
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Confirm Order OTP",
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
              // Send OTP Button
              ElevatedButton(
                onPressed: _sendOtp,
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
                child: Text(
                  "Send OTP to Sender",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // OTP Input Field
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
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
              // Verify OTP Button
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
                  "Verify OTP",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}