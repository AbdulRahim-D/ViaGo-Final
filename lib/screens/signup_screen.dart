import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _sendingOtp = false;
  bool _obscurePassword = true;

  final _authService = FirebaseAuthService();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+91${_phoneCtrl.text.trim()}'; // Prepend +91 to the entered number
    final username = _usernameCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    setState(() => _sendingOtp = true);
    try {
      final result = await _authService.sendOtp(
        phone,
        codeSent: (verificationId, resendToken) async {
          if (!mounted) return;
          Navigator.of(context).pushNamed(
            '/otp',
            arguments: {
              'flow': 'signup',
              'verificationId': verificationId,
              'username': username,
              'password': password,
              'phone': phone,
            },
          );
        },
      );

      if (!mounted) return;
      if (result != null) {
        Navigator.of(context).pushNamed(
          '/otp',
          arguments: {
            'flow': 'signup',
            'confirmationResult': result,
            'username': username,
            'password': password,
            'phone': phone,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number required';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) {
      return 'Enter a valid 10-digit number';
    }
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username required';
    if (!RegExp(r'^[a-zA-Z0-9._]{3,}$').hasMatch(v)) {
      return 'Min 3 chars, letters/digits/_/.';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 8) return 'Minimum 8 characters';
    return null;
  }

  static const Color primaryPurple = Color(0xFF514ca1);
  static const Color accentOrange = Color(0xd79141);
  static const Color highlightYellowOrange = Color(0xfff8af0b);
  static const Color warmBrown = Color(0xFF6c5050);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Via',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.normal,
                          color: primaryPurple,
                        ),
                      ),
                      TextSpan(
                        text: 'Go',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: highlightYellowOrange,
                          shadows: [
                            Shadow(
                              color: accentOrange.withOpacity(0.5),
                              offset: const Offset(3, 3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: warmBrown,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign up to get started with ViaGo',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: warmBrown.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameCtrl,
                  style: GoogleFonts.poppins(color: warmBrown),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person, color: accentOrange),
                    labelText: 'Username',
                    labelStyle: GoogleFonts.poppins(color: warmBrown),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryPurple.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryPurple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: _validateUsername,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.poppins(color: warmBrown),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: accentOrange),
                    labelText: 'Password',
                    labelStyle: GoogleFonts.poppins(color: warmBrown),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: warmBrown.withOpacity(0.5),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryPurple.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryPurple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    // Static +91 Text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryPurple.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                        color: warmBrown.withOpacity(0.1)
                      ),
                      height: 54, // Match TextFormField height
                      alignment: Alignment.center,
                      child: Text(
                        '+91',
                        style: GoogleFonts.poppins(
                          color: warmBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Phone Number Input
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(color: warmBrown),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: GoogleFonts.poppins(color: warmBrown),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryPurple.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryPurple, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: _validatePhone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: primaryPurple.withOpacity(0.3),
                    ),
                    onPressed: _sendingOtp ? null : _startSignup,
                    child: _sendingOtp
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.poppins(
                        color: warmBrown,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(
                        'Login In',
                        style: GoogleFonts.poppins(
                          color: highlightYellowOrange,
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
      ),
    );
  }
}
