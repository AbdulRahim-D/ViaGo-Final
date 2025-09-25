import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fs = FirestoreService();
  final _authService = FirebaseAuthService();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveLogin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', true);
    await prefs.setString('uid', uid);
  }

  Future<void> _login() async {
    if (mounted) setState(() => _loading = true);

    try {
      final username = _usernameCtrl.text.trim().toLowerCase();
      final user = await _fs.getUserByUsername(username);

      if (!mounted) return;

      if (user == null ||
          _authService.hashPassword(_passwordCtrl.text) != user.passwordHash) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password')),
          );
        }
        return;
      }

      await _saveLogin(user.uid);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void goSignup() => Navigator.of(context).pushNamed('/signup');
  void goForgot() => Navigator.of(context).pushNamed('/forgot');

  // Define brand colors
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
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo/App Title
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
                'Welcome Back',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: warmBrown,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sign in to continue to ViaGo',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: warmBrown.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 30),
              // Username
              TextField(
                controller: _usernameCtrl,
                style: GoogleFonts.poppins(color: warmBrown),
                decoration: InputDecoration(
                  // This is the correct way to add a person icon in Flutter.
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
              ),
              const SizedBox(height: 18),
              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: GoogleFonts.poppins(color: warmBrown),
                decoration: InputDecoration(
                  // This is the correct way to add a lock icon in Flutter.
                  prefixIcon: const Icon(Icons.lock, color: accentOrange),
                  labelText: 'Password',
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                      color: warmBrown.withOpacity(0.5),
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: goForgot,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryPurple.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      color: primaryPurple,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: primaryPurple.withOpacity(0.3),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              // Sign Up Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.poppins(
                      color: warmBrown,
                    ),
                  ),
                  GestureDetector(
                    onTap: goSignup,
                    child: Text(
                      'Sign Up',
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
    );
  }
}
