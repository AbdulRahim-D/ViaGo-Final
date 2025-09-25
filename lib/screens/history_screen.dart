import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packmate/screens/package_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final asSender = FirebaseFirestore.instance
        .collection('parcels')
        .where('createdByUid', isEqualTo: uid)
        .where('status', whereIn: ['delivered', 'canceled']);

    final asTraveler = FirebaseFirestore.instance
        .collection('parcels')
        .where('assignedTravelerUid', isEqualTo: uid)
        .where('status', whereIn: ['delivered', 'canceled']);

    final asReceiver = FirebaseFirestore.instance
        .collection('parcels')
        .where('receiverUid', isEqualTo: uid)
        .where('status', whereIn: ['delivered', 'canceled']);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // Softer background color
        appBar: AppBar(
          backgroundColor: const Color(0xFF514ca1),
          elevation: 0,
          centerTitle: false,
          title: Text(
            'History',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0x33ffffff),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: const Color(0xFFa8ad5f), // Solid color, no gradient
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'Sender'),
                  Tab(text: 'Traveler'),
                  Tab(text: 'Receiver'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _list(asSender, role: 'sender'),
            _list(asTraveler, role: 'traveler'),
            _list(asReceiver, role: 'receiver'),
          ],
        ),
      ),
    );
  }

  Widget _list(Query q, {required String role}) {
    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!s.hasData || s.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No delivered packages yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500, // Adjusted font weight
                color: const Color(0xFF6c5050), // Using brand color
              ),
            ),
          );
        }
        final docs = s.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Increased padding for better spacing
          itemCount: docs.length,
          itemBuilder: (c, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final String status = d['status'] ?? '';
            Color statusColor;
            switch (status) {
              case 'delivered':
                statusColor = const Color(0xFFa8ad5f);
                break;
              case 'canceled':
                statusColor = const Color(0xFFd79141);
                break;
              default:
                statusColor = Colors.grey;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 8, // Increased elevation for a subtle lift
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) => PackageDetailScreen(
                          parcelId: docs[i].id,
                          role: role,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18, // Increased vertical padding
                      horizontal: 24, // Increased horizontal padding
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${d['id'] ?? '-'} – ${d['contents'] ?? ''}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6c5050),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Price: ₹${d['price']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'View Details',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFd79141),
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
          },
        );
      },
    );
  }
}
