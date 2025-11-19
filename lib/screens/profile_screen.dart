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
  bool _isEditing = false;

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      return;
    }

    final profileDoc = await FirebaseFirestore.instance
        .collection("profiles")
        .doc(user.uid)
        .get();

    if (profileDoc.exists) {
      final data = profileDoc.data()!;
      setState(() {
        _usernameController.text = data["username"] ?? "";
        _phoneController.text = data["phone"] ?? "";
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
  Future<String?> _uploadImage(File file, String userId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child("$userId.jpg");

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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Upload new image if selected
    if (_imageFile != null) {
      final url = await _uploadImage(_imageFile!, user.uid);
      if (url != null) {
        setState(() {
          _profileImageUrl = url;
        });
      }
    }

    // Save profile into Firestore
    final data = {
      "username": _usernameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "name": _nameController.text.trim(),
      "age": _ageController.text.trim(),
      "gender": _genderController.text.trim(),
      "email": _emailController.text.trim(),
      "profileImage": _profileImageUrl ?? "",
      "updatedAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("profiles")
        .doc(user.uid)
        .set(data, SetOptions(merge: true));

    setState(() {
      _isEditing = false;
    });

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
              await FirebaseAuth.instance.signOut();
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
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection("profiles")
                    .doc(user.uid)
                    .delete();
                await user.delete();

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
                    Navigator.pop(
                        dialogContext); // Close dialog after selection
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
        child: _isEditing ? _buildEditForm() : _buildProfileView(),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        _buildProfileImage(),
        const SizedBox(height: 24),
        _buildRatingDisplay(),
        const SizedBox(height: 24),
        _buildProfileInfo("Username", _usernameController.text),
        _buildProfileInfo("Phone", _phoneController.text),
        _buildProfileInfo("Name", _nameController.text),
        _buildProfileInfo("Age", _ageController.text),
        _buildProfileInfo("Gender", _genderController.text),
        _buildProfileInfo("Email", _emailController.text),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF514ca1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 5,
            ),
            child: Text(
              "Edit Profile",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildProfileImage(),
          const SizedBox(height: 24),
          _buildTextFormField(_usernameController, "Username", "Enter username",
              readOnly: true),
          const SizedBox(height: 16),
          _buildTextFormField(
              _phoneController, "Phone Number", "Enter phone number",
              readOnly: true),
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
                backgroundColor: const Color(0xFFa8ad5f),
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
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFe0e0e0),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF514ca1), width: 3),
        ),
        child: ClipOval(
          child: _imageFile != null
              ? Image.file(_imageFile!, fit: BoxFit.cover)
              : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                  ? Image.network(_profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF6c5050)))
                  : Icon(
                      _isEditing ? Icons.camera_alt : Icons.person,
                      size: 40,
                      color: const Color(0xFF6c5050),
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

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6c5050),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller, String label, String validatorText,
      {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : const Color(0xFFf5f5f5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFa8ad5f), width: 2), // Accent Olive Green
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
