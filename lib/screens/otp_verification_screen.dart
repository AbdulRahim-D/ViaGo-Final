import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeCtrl = TextEditingController();
  final _authService = FirebaseAuthService();
  final _fs = FirestoreService();
  bool _verifying = false;
  bool _resending = false;

  final Color _primaryPurple = const Color(0xFF514ca1);
  final Color _accentOliveGreen = const Color(0xFFa8ad5f);
  final Color _accentOrange = const Color(0xFFd79141);
  final Color _highlightYellowOrange = const Color(0xFFf8af0b);
  final Color _neutralWarmBrown = const Color(0xFF6c5050);

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args == null) return;

    final flow = (args['flow'] as String?) ?? 'signup';

    if (mounted) setState(() => _verifying = true);
    try {
      UserCredential cred;

      if (args.containsKey('confirmationResult')) {
        // Web
        cred = await _authService.confirmOtpWeb(
          args['confirmationResult'],
          _codeCtrl.text.trim(),
        );
      } else {
        // Mobile: verificationId + smsCode
        final verificationId = args['verificationId'] as String;
        final smsCode = _codeCtrl.text.trim();
        final c = _authService.buildSmsCredential(verificationId, smsCode);
        cred = await _authService.signInWithCredential(c);
      }

      if (!mounted) return;

      final user = cred.user;
      if (user == null) {
        throw Exception('No user after verification');
      }

      if (flow == 'signup') {
        final username = (args['username'] as String).toLowerCase();
        final password = args['password'] as String;
        final phone = args['phone'] as String;

        // 1) Reserve username (transaction)
        final reserved = await _fs.tryReserveUsername(username, user.uid);
        if (!reserved) {
          await _authService.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username already taken. Please choose another one.'),
            ),
          );
          Navigator.popUntil(context, ModalRoute.withName('/signup'));
          return;
        }

        // 2) Create user document in Firestore
        final passwordHash = _authService.hashPassword(password);
        final appUser = AppUser(
          uid: user.uid,
          username: username,
          phone: phone,
          passwordHash: passwordHash,
          createdAt: DateTime.now(),
        );
        await _fs.createUser(appUser);

        if (!mounted) return;

        // ✅ Keep user signed in and go to Home
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else if (flow == 'reset') {
        final uid = (args['uid'] as String?) ?? FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          throw Exception('No user for reset');
        }

        if (!mounted) return;

        Navigator.of(context).pushReplacementNamed(
          '/forgot',
          arguments: {'stage': 'set_new', 'uid': uid},
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verify failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _resending = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent!')),
    );
  }

  Widget _buildCombinedIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _accentOrange,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            bottom: 10,
            child: Icon(
              Icons.phone_in_talk_rounded,
              size: 32,
              color: _primaryPurple.withOpacity(0.9),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Icon(
              Icons.sms_rounded,
              size: 24,
              color: _primaryPurple.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Via',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _primaryPurple,
                    ),
                  ),
                  Text(
                    'Go',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _accentOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildCombinedIcon(),
              const SizedBox(height: 24),
              Text(
                'OTP Verification',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to your mobile number.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: _neutralWarmBrown,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 52,
                  fieldWidth: 48,
                  activeColor: _accentOrange.withOpacity(0.8),
                  selectedColor: _primaryPurple,
                  inactiveColor: _neutralWarmBrown.withOpacity(0.3),
                ),
                onChanged: (value) {},
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: _primaryPurple.withOpacity(0.4),
                    animationDuration: const Duration(milliseconds: 300),
                    
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Verify OTP',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code?",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _neutralWarmBrown,
                    ),
                  ),
                  TextButton(
                    onPressed: _resending ? null : _resendOtp,
                    style: TextButton.styleFrom(
                      foregroundColor: _accentOrange,
                      animationDuration: const Duration(milliseconds: 200),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _resending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accentOliveGreen,
                            ),
                          )
                        : Text(
                            'Resend OTP',
                            style: GoogleFonts.poppins(
                              color: _accentOliveGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}