import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _rid = TextEditingController();

  // Define brand colors
  static const Color primaryPurple = Color(0xFF514ca1);
  static const Color accentOliveGreen = Color(0xFFA8AD5F);
  static const Color accentOrange = Color(0xFFd79141);
  static const Color highlightYellowOrange = Color(0xFFf8af0b);
  static const Color neutralWarmBrown = Color(0xFF6c5050);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _rid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: accentOliveGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Track Parcel',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              title: 'Parcel Details',
              children: [
                _buildInput('Full Name', _name, hint: 'e.g., Jane Doe'),
                _buildInput('Phone Number', _phone, hint: 'e.g., +91 9876543210', type: TextInputType.phone),
                _buildInput('Receiver ID', _rid, hint: 'e.g., VIA-12345'),
                const SizedBox(height: 12),
                Text(
                  '(Enter the receiver details set by the sender to find your parcel.)',
                  style: GoogleFonts.poppins(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: neutralWarmBrown.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentOliveGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 6,
                shadowColor: neutralWarmBrown.withOpacity(0.2),
              ),
              onPressed: () => setState(() {}),
              child: Text(
                'Find My Parcel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _results(_name.text.trim(), _phone.text.trim(), _rid.text.trim()),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(
          color: accentOliveGreen,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: accentOliveGreen,
              ),
            ),
            const Divider(color: accentOliveGreen, height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController c, {TextInputType? type, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: neutralWarmBrown),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: c,
              keyboardType: type,
              style: GoogleFonts.poppins(color: neutralWarmBrown),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(color: neutralWarmBrown.withOpacity(0.4)),
                isDense: true,
                filled: true,
                fillColor: neutralWarmBrown.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentOliveGreen, width: 2.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(String name, String phone, String rid) {
    if (name.isEmpty && phone.isEmpty && rid.isEmpty) return const SizedBox();
    Query q = FirebaseFirestore.instance.collection('parcels');
    if (name.isNotEmpty) q = q.where('receiverName', isEqualTo: name);
    if (phone.isNotEmpty) q = q.where('receiverPhone', isEqualTo: phone);
    if (rid.isNotEmpty) q = q.where('receiverId', isEqualTo: rid);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (c, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = s.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No matching parcel found.',
                style: GoogleFonts.poppins(
                  fontStyle: FontStyle.italic,
                  color: neutralWarmBrown.withOpacity(0.7),
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (c, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(
                  '#${d['id']} – ${d['contents']}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: primaryPurple),
                ),
                subtitle: Text(
                  'Sender: ${d['senderName']} • Traveler: ${d['assignedTravelerName'] ?? '—'} • Cost: ₹${d['price']}',
                  style: GoogleFonts.poppins(fontSize: 12, color: neutralWarmBrown.withOpacity(0.8)),
                ),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: primaryPurple,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'View',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showDetails(context, docs[i].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetails(BuildContext context, String parcelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final ref = FirebaseFirestore.instance.collection('parcels').doc(parcelId);
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: ref.snapshots(),
            builder: (c, s) {
              if (!s.hasData) {
                return const SizedBox(
                    height: 200, child: Center(child: CircularProgressIndicator()));
              }
              final p = s.data!.data() as Map<String, dynamic>;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Package #${p['id']} – ${p['contents']}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: neutralWarmBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pickup: ${p['pickupCity']} • Destination: ${p['destCity']}',
                    style: GoogleFonts.poppins(fontSize: 14, color: neutralWarmBrown.withOpacity(0.8)),
                  ),
                  Text(
                    'Traveler: ${p['assignedTravelerName'] ?? 'Not selected'}',
                    style: GoogleFonts.poppins(fontSize: 14, color: neutralWarmBrown.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('You must be signed in to track')));
                        return;
                      }
                      await FirebaseFirestore.instance
                          .collection('parcels')
                          .doc(parcelId)
                          .update({
                        'trackedReceiverUid': uid,
                        'updatedAt': FieldValue.serverTimestamp()
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Parcel added to your Receiver MyTrip')));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentOliveGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shadowColor: neutralWarmBrown.withOpacity(0.2),
                    ),
                    child: Text(
                      'Start Tracking (Add to MyTrip)',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final snap = await FirebaseFirestore.instance
                          .collection('parcels')
                          .doc(parcelId)
                          .get();
                      final data = snap.data() as Map<String, dynamic>;
                      if (data['confirmationWho'] == 'receiver') {
                        final uid = FirebaseAuth.instance.currentUser?.uid ?? data['createdByUid'];
                        final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
                            .toString()
                            .substring(0, 6);
                        await FirebaseFirestore.instance
                            .collection('parcels')
                            .doc(parcelId)
                            .update({
                          'pendingOtp': {
                            'type': 'delivery',
                            'code': otp,
                            'toUid': uid
                          },
                          'updatedAt': FieldValue.serverTimestamp()
                        });
                        final notif = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('notifications')
                            .doc();
                        await notif.set({
                          'id': notif.id,
                          'parcelId': parcelId,
                          'type': 'delivery',
                          'code': otp,
                          'status': 'sent',
                          'createdAt': FieldValue.serverTimestamp()
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Delivery OTP sent to your notifications. Share with traveler')));
                          Navigator.pop(context);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'This parcel requires sender confirmation for delivery.')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shadowColor: neutralWarmBrown.withOpacity(0.2),
                    ),
                    child: Text(
                      'Get Delivery OTP',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
