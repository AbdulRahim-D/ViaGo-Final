import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:packmate/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Blocked Users',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF514ca1), // Primary Purple
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBlockedUsersList(),
    );
  }

  Widget _buildBlockedUsersList() {
    if (currentUser == null)
      return Center(
        child: Text(
          'Please log in.',
          style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
        ),
      );

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('profiles')
          .doc(currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFf8af0b),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Could not load user profile.',
              style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final List<String> blockedUids =
            List<String>.from(data?['blockedUsers'] ?? []);

        if (blockedUids.isEmpty) {
          return Center(
            child: Text(
              'You have not blocked any users.',
              style: GoogleFonts.poppins(
                  fontSize: 16, color: const Color(0xFF6c5050)),
            ),
          );
        }

        return ListView.builder(
          itemCount: blockedUids.length,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemBuilder: (context, index) {
            final blockedUid = blockedUids[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(blockedUid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        'Loading...',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6c5050),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        blockedUid,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        'User not found.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFd79141),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        blockedUid,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final blockedUserData = AppUser.fromDoc(userSnapshot.data!);
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    title: Text(
                      blockedUserData.username ?? 'Unknown User',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6c5050),
                      ),
                    ),
                    subtitle: Text(
                      'UID: ${blockedUserData.uid}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6c5050),
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('profiles')
                            .doc(currentUser!.uid)
                            .update({
                          'blockedUsers': FieldValue.arrayRemove([blockedUid])
                        }).then((_) {
                          // We call setState here to trigger a rebuild of the outer FutureBuilder
                          setState(() {});
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFd79141), // Accent Orange
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Unblock',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
