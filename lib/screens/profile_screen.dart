import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:packmate/main.dart'; // Import main.dart to access _MyAppState

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  String? _profileImageUrl;
  double _averageRating = 0.0;
  int _ratingCount = 0;

  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Load profile data from Firestore
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString("username");
    String? phone = prefs.getString("phone");

    if (username == null || phone == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final query = await FirebaseFirestore.instance
            .collection("users")
            .where("uid", isEqualTo: user.uid)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final userData = query.docs.first.data();
          username = userData["username"];
          phone = userData["phone"];

          await prefs.setString("username", username!);
          await prefs.setString("phone", phone!);
        }
      }
    }

    if (username != null) {
      final profileDoc = await FirebaseFirestore.instance
          .collection("profiles")
          .doc(username)
          .get();

      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        setState(() {
          _usernameController.text = username!;
          _phoneController.text = phone ?? "";
          _nameController.text = data["name"] ?? "";
          _ageController.text = data["age"] ?? "";
          _genderController.text = data["gender"] ?? "";
          _emailController.text = data["email"] ?? "";
          _profileImageUrl = data["profileImage"];
          _averageRating = (data['averageRating'] ?? 0.0).toDouble();
          _ratingCount = data['ratingCount'] ?? 0;
        });
      }
    }
  }

  /// ✅ Pick Image from gallery
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// ✅ Upload image to Firebase Storage
  Future<String?> _uploadImage(File file, String username) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child("$username.jpg");

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }

  /// ✅ Save Profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate user exists
    final query = await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .where("phone", isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Invalid username or phone number. Try again.",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFd79141),
        ),
      );
      return;
    }

    // Upload new image if selected
    if (_imageFile != null) {
      final url = await _uploadImage(_imageFile!, username);
      if (url != null) {
        setState(() {
          _profileImageUrl = url;
        });
      }
    }

    // Save profile into Firestore
    final data = {
      "username": username,
      "phone": phone,
      "name": _nameController.text.trim(),
      "age": _ageController.text.trim(),
      "gender": _genderController.text.trim(),
      "email": _emailController.text.trim(),
      "profileImage": _profileImageUrl ?? "",
      "updatedAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("profiles")
        .doc(username)
        .set(data, SetOptions(merge: true));

    // ✅ Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
    await prefs.setString("phone", phone);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Profile updated successfully",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFa8ad5f),
      ),
    );
  }

  /// ✅ Settings Modal
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 40,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6, color: Color(0xFF6c5050)),
            title: Text(
              "Theme Mode",
              style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
            ),
            onTap: () {
              Navigator.pop(ctx); // Close current bottom sheet
              _showThemeModeSelectionDialog(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFd79141)),
            title: Text(
              "Logout",
              style: GoogleFonts.poppins(color: const Color(0xFFd79141)),
            ),
            onTap: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, "/login");
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Color(0xFFd79141)),
            title: Text(
              "Delete Account",
              style: GoogleFonts.poppins(color: const Color(0xFFd79141)),
            ),
            onTap: () async {
              Navigator.pop(ctx);
              final username = _usernameController.text.trim();
              if (username.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .where("username", isEqualTo: username)
                    .get()
                    .then((snapshot) async {
                  for (var doc in snapshot.docs) {
                    await doc.reference.delete();
                  }
                });

                await FirebaseFirestore.instance
                    .collection("profiles")
                    .doc(username)
                    .delete();

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!mounted) return;
                Navigator.pushReplacementNamed(context, "/login");
              }
            },
          ),
        ],
      ),
    );
  }

  void _showThemeModeSelectionDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogContext) {
        // Get current theme mode from MyAppState
        final MyAppState? myAppState = MyApp.of(dialogContext);
        ThemeMode currentThemeMode = myAppState?.themeMode ?? ThemeMode.system;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Select Theme Mode",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6c5050),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(
                  mode.toString().split('.').last.toCapitalized(),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6c5050),
                  ),
                ),
                activeColor: const Color(0xFF514ca1), // Primary Purple
                value: mode,
                groupValue: currentThemeMode,
                onChanged: (ThemeMode? newMode) {
                  if (newMode != null) {
                    myAppState?.setThemeMode(newMode);
                    Navigator.pop(dialogContext); // Close dialog after selection
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFd79141),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF514ca1), // Primary Purple
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFe0e0e0),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF514ca1), width: 3),
                  ),
                  child: ClipOval(
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : (_profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty)
                            ? Image.network(_profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 60, color: Color(0xFF6c5050)))
                            : const Icon(Icons.camera_alt,
                                size: 40, color: Color(0xFF6c5050)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildRatingDisplay(),
              const SizedBox(height: 24),
              _buildTextFormField(
                  _usernameController, "Username", "Enter username"),
              const SizedBox(height: 16),
              _buildTextFormField(
                  _phoneController, "Phone Number", "Enter phone number"),
              const SizedBox(height: 16),
              _buildTextFormField(_nameController, "Name", "Enter name"),
              const SizedBox(height: 16),
              _buildTextFormField(_ageController, "Age", "Enter age"),
              const SizedBox(height: 16),
              _buildTextFormField(_genderController, "Gender", "Enter gender"),
              const SizedBox(height: 16),
              _buildTextFormField(_emailController, "Email", "Enter email"),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF514ca1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                  ),
                  child: Text(
                    "Save",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingDisplay() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Icon(
              index < _averageRating ? Icons.star : Icons.star_border,
              color: const Color(0xFFf8af0b), // Highlight Yellow-Orange
              size: 30,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '$_ratingCount reviews',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF6c5050), // Neutral/Dark Text Warm Brown
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller, String label, String validatorText) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
        filled: true,
        fillColor: const Color(0xFFf5f5f5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFa8ad5f), width: 2), // Accent Olive Green
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? validatorText : null,
    );
  }
}

extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
