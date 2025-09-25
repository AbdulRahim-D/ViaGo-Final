import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:packmate/models/report.dart';
import 'package:packmate/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Reports',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF514ca1), // Primary Purple
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildReportsList(),
    );
  }

  Widget _buildReportsList() {
    if (currentUser == null)
      return Center(
        child: Text(
          'Please log in.',
          style: GoogleFonts.poppins(color: const Color(0xFF6c5050)),
        ),
      );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('reportedByUid', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFf8af0b), // Highlight Yellow-Orange
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'You have not filed any reports.',
              style: GoogleFonts.poppins(
                  fontSize: 16, color: const Color(0xFF6c5050)),
            ),
          );
        }

        final reports = snapshot.data!.docs
            .map((doc) => Report.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return ListView.builder(
          itemCount: reports.length,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemBuilder: (context, index) {
            final report = reports[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(report.reportedUid)
                  .get(),
              builder: (context, userSnapshot) {
                String username = 'Unknown User';

                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  username = 'Loading...';
                } else if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = AppUser.fromDoc(userSnapshot.data!);
                  username = userData.username ?? 'Unknown User';
                }

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      'Report against: $username',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6c5050),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Parcel ID: ${report.parcelId ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF6c5050),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reason: ${report.reason ?? 'No reason provided'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF6c5050),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
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