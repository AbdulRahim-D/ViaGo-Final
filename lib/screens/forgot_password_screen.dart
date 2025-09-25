import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// NOTE: These are placeholder services. You will need to implement
// your own logic for Firebase authentication and Firestore interactions.
// For this example, we assume they have methods like `sendOtp`, `hashPassword`,
// and `updatePasswordHash`.
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

/// A screen that handles the forgotten password flow.
/// It has two main stages:
/// 1. Entering a phone number to receive an OTP.
/// 2. Entering and confirming a new password after successful OTP verification.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controllers for the input fields
  final _phoneCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // A key to uniquely identify the Form widget for validation
  final _formKey = GlobalKey<FormState>();

  // Placeholder service instances for Firebase and Firestore
  final _authService = FirebaseAuthService();
  final _fs = FirestoreService();

  // State variables for UI feedback
  bool _sending = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  /// Sends an OTP to the user's provided phone number.
  /// It prepends the country code and handles navigation to the OTP screen
  /// upon success.
  Future<void> _sendOtpForReset() async {
    // Ensure the phone number is not empty before proceeding.
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter phone number')));
      return;
    }

    // Correctly prepend the static +91 to the user's input.
    final fullPhoneNumber = '+91${_phoneCtrl.text.trim()}';

    // Show a loading indicator while the OTP is being sent.
    if (mounted) setState(() => _sending = true);

    try {
      // Calls the authentication service to send the OTP.
      final result = await _authService.sendOtp(
        fullPhoneNumber,
        // The `codeSent` callback is used for web platforms.
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          // Navigate to the OTP screen with necessary arguments.
          Navigator.of(context).pushNamed(
            '/otp',
            arguments: {
              'flow': 'reset',
              'verificationId': verificationId,
            },
          );
        },
      );

      if (!mounted) return;

      // The `result` is used for non-web platforms.
      if (result != null) {
        // Navigate to the OTP screen with the confirmation result.
        Navigator.of(context).pushNamed(
          '/otp',
          arguments: {
            'flow': 'reset',
            'confirmationResult': result,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Display an error message if OTP sending fails.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
    } finally {
      // Hide the loading indicator.
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Sets the new password after the user has successfully verified the OTP.
  /// It validates the form and updates the password hash in Firestore.
  Future<void> _setNewPassword(String uid) async {
    // Validate the form fields.
    if (!_formKey.currentState!.validate()) return;

    try {
      // Hash the new password and update it in Firestore.
      final hash = _authService.hashPassword(_newPassCtrl.text);
      await _fs.updatePasswordHash(uid, hash);

      if (!mounted) return;

      // Show a success message and navigate back to the login screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please login.')),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      // Display an error message if the update fails.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve arguments passed via navigation.
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final stage = args != null ? args['stage'] as String? : null;
    final uid = args != null ? args['uid'] as String? : null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image positioned to the center-right.
          if (stage != 'set_new')
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 0),
                child: Image.asset(
                  'assets/images/lock_symbol.png',
                  width: 260,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Application logo
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            letterSpacing: 1,
                            color: Color(0xFF22215B),
                          ),
                          children: [
                            TextSpan(text: 'Via'),
                            TextSpan(
                              text: 'Go',
                              style: TextStyle(color: Color(0xFFFBA13C)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (stage == 'set_new')
                      // UI for setting the new password.
                      _buildSetNewPasswordForm(uid)
                    else
                      // UI for entering the phone number to send OTP.
                      _buildSendOtpForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the form for setting a new password.
  Widget _buildSetNewPasswordForm(String? uid) {
    return Column(
      children: [
        const Icon(Icons.vpn_key_rounded, color: Color(0xFFFBA13C), size: 36),
        const SizedBox(height: 8),
        const Text(
          'Reset Your Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFFFBA13C),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'password must be different than before',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF8D8D8D),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPassCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Required';
                  }
                  if (v.length < 8) {
                    return 'Minimum 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Required';
                  }
                  if (v != _newPassCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B4BC6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: uid == null ? null : () => _setNewPassword(uid),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the form for sending the OTP.
  Widget _buildSendOtpForm() {
    return Column(
      children: [
        const Icon(Icons.lock_reset_rounded, color: Color(0xFFFBA13C), size: 36),
        const SizedBox(height: 8),
        const Text(
          'Forgot Password?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFFFBA13C),
          ),
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Enter your Mobile Number:',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8D8D8D),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF4B4BC6)),
            // Use prefixText to make +91 static.
            prefixText: '+91 ',
            labelText: 'Phone Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B4BC6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _sending ? null : _sendOtpForReset,
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// NOTE: Add these placeholder classes to make the example runnable.
// In a real application, you would have these services implemented.

class FirestoreService {
  Future<void> updatePasswordHash(String uid, String hash) async {
    // Implement Firestore logic to update the user's password hash
    await Future.delayed(const Duration(seconds: 1)); // Simulate a network call
    print('Updating password hash for user $uid');
  }
}

class FirebaseAuthService {
  Future<dynamic> sendOtp(String phoneNumber, {required Function(String, int?) codeSent}) async {
    // Implement Firebase OTP sending logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate a network call
    print('Sending OTP to $phoneNumber');
    // Simulate success on web
    codeSent('dummy_verification_id', null);
    // Simulate success on other platforms
    return 'dummy_confirmation_result';
  }
  
  String hashPassword(String password) {
    // Implement password hashing logic (e.g., using a library like crypto)
    return 'hashed_password_$password';
  }
}
