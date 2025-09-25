// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/traveler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../services/location.dart';
import '../services/firestore_service.dart';

class TravelerScreen extends StatefulWidget {
  const TravelerScreen({super.key});

  @override
  State<TravelerScreen> createState() => _TravelerScreenState();
}

class _TravelerScreenState extends State<TravelerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromCity = TextEditingController();
  final _toCity = TextEditingController();
  final _capacity = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _date;
  String? _mode;

  // Define brand colors
  static const Color primaryPurple = Color(0xFF514ca1);
  static const Color accentOrange = Color(0xFFd79141);
  static const Color darkTextBrown = Color(0xFF6c5050);
  static const Color lightBackground = Color(0xFFF0F0F0); // A light, neutral background

  @override
  void dispose() {
    _fromCity.dispose();
    _toCity.dispose();
    _capacity.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: accentOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'My Trip',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildCard(
                        title: 'trip details:',
                        children: [
                          _buildTextField('From:', _fromCity,
                              hint: 'Starting point'),
                          _buildTextField('To:', _toCity,
                              hint: 'Destination point'),
                          _buildTextField('Phone:', _phone,
                              hint: 'Your phone number',
                              type: TextInputType.phone),
                          _buildDateField('Date of traveling:', _date,
                              () async {
                            final now = DateTime.now();
                            final d = await showDatePicker(
                              context: context,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 365)),
                              initialDate: now,
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: accentOrange,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (d != null) setState(() => _date = d);
                          }),
                          _buildDropdownField('Mode of travel:',
                              ['vehicle', 'bus', 'train', 'flight']),
                          _buildTextField('Capacity:', _capacity,
                              hint: 'Weight can Carry',
                              type: TextInputType.number),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildUpdateButton(),
                      const SizedBox(height: 20),
                      _PackagesList(
                          fromCityCtrl: _fromCity,
                          toCityCtrl: _toCity,
                          phoneCtrl: _phone),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
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
                color: accentOrange,
              ),
            ),
            const Divider(color: accentOrange, thickness: 2),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? hint, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, color: darkTextBrown)),
          ),
          TextFormField(
            controller: controller,
            keyboardType: type,
            style: GoogleFonts.poppins(color: darkTextBrown),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: accentOrange, width: 2.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onPick) {
    final formattedDate =
        date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, color: darkTextBrown)),
          ),
          GestureDetector(
            onTap: onPick,
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(text: formattedDate),
                style: GoogleFonts.poppins(color: darkTextBrown),
                decoration: InputDecoration(
                  hintText: 'DD/MM/YYYY',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  suffixIcon: const Icon(Icons.calendar_today,
                      color: accentOrange),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        const BorderSide(color: accentOrange, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, color: darkTextBrown)),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _mode,
            hint: Text('Select Mode',
                style: GoogleFonts.poppins(color: Colors.grey.shade400)),
            style: GoogleFonts.poppins(color: darkTextBrown),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: accentOrange, width: 2.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                    style: GoogleFonts.poppins(color: darkTextBrown)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _mode = newValue);
              }
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 5,
        ),
        onPressed: _saveTrip,
        child: Text(
          'Update MyTrip',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate() || _date == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final travelerName = user.data()?['username'] ?? 'Traveler';

    final traveler = Traveler(
      id: uid,
      travelerUid: uid,
      travelerName: travelerName,
      phone: _phone.text.trim(),
      fromCity: _fromCity.text.trim(),
      toCity: _toCity.text.trim(),
      travelDate: _date!,
      mode: _mode!,
      capacityKg: double.tryParse(_capacity.text) ?? 0,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('trips')
        .doc(uid)
        .set(traveler.toMap(), SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Trip updated.')));
    }
  }
}

class _PackagesList extends StatefulWidget {
  final TextEditingController fromCityCtrl;
  final TextEditingController toCityCtrl;
  final TextEditingController phoneCtrl;
  const _PackagesList(
      {required this.fromCityCtrl,
      required this.toCityCtrl,
      required this.phoneCtrl});

  @override
  State<_PackagesList> createState() => _PackagesListState();
}

class _PackagesListState extends State<_PackagesList> {
  List<String> _blockedUsers = [];
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _locationSubscription;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBlockedUsers() async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final profileDoc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(currentUserUid)
        .get();
    if (profileDoc.exists) {
      setState(() {
        _blockedUsers =
            List<String>.from(profileDoc.data()!['blockedUsers'] ?? []);
      });
    }
  }

  Future<void> _startTracking(String parcelId) async {
    try {
      Position position = await _locationService.getCurrentLocation();
      await FirebaseFirestore.instance
          .collection('parcels')
          .doc(parcelId)
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      _locationSubscription =
          _locationService.getLocationStream().listen((Position position) {
        FirebaseFirestore.instance.collection('parcels').doc(parcelId).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to start tracking: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.fromCityCtrl.text.trim();
    final to = widget.toCityCtrl.text.trim();

    if (from.isEmpty || to.isEmpty) {
      return const SizedBox();
    }

    Query q = FirebaseFirestore.instance
        .collection('parcels')
        .where('pickupCity', isEqualTo: from)
        .where('destCity', isEqualTo: to)
        .where('status', isEqualTo: 'posted');

    if (_blockedUsers.isNotEmpty) {
      q = q.where('createdByUid', whereNotIn: _blockedUsers);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'No packages available for this route.',
                style: GoogleFonts.poppins(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Available Packages:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _TravelerScreenState.darkTextBrown,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              itemCount: docs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (c, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final packageCreatorUid = d['createdByUid'] as String?;
                          if (packageCreatorUid != null) {
                            final senderProfileDoc = await FirebaseFirestore
                                .instance
                                .collection('profiles')
                                .doc(packageCreatorUid)
                                .get();
                            if (senderProfileDoc.exists) {
                              final blockedUsers = List<String>.from(
                                  senderProfileDoc.data()?['blockedUsers'] ??
                                      []);
                              if (blockedUsers.contains(
                                  FirebaseAuth.instance.currentUser!.uid)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'You cannot select this package as the sender has blocked you.'),
                                      backgroundColor: Colors.red,
                                    ));
                                return;
                              }
                            }
                          }

                          final uid = FirebaseAuth.instance.currentUser!.uid;
                          final user = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get();
                          final travelerName =
                              user.data()?['username'] ?? 'Traveler';
                          final travelerPhone = widget.phoneCtrl.text.trim();

                          if (travelerPhone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please enter your phone number before selecting a package.'),
                                  backgroundColor: Colors.red,
                                ));
                            return;
                          }

                          await FirebaseFirestore.instance
                              .collection('parcels')
                              .doc(docs[i].id)
                              .update({
                            'assignedTravelerUid': uid,
                            'assignedTravelerName': travelerName,
                            'assignedTravelerPhone': travelerPhone,
                            'status': 'selected',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          final parcelDoc = await FirebaseFirestore.instance
                              .collection('parcels')
                              .doc(docs[i].id)
                              .get();
                          final parcelData =
                              parcelDoc.data() as Map<String, dynamic>? ?? {};
                          final senderUid =
                              parcelData['createdByUid'] as String?;
                          final receiverUid =
                              parcelData['receiverUid'] as String?;
                          final parcelContents =
                              parcelData['contents'] as String? ?? 'your package';

                          if (senderUid != null) {
                            await _firestoreService.sendNotification(
                              recipientUid: senderUid,
                              message:
                                  'Your package "$parcelContents" has been selected by a traveler!',
                              type: 'traveler_selected',
                              parcelId: docs[i].id,
                            );
                          }
                          if (receiverUid != null) {
                            await _firestoreService.sendNotification(
                              recipientUid: receiverUid,
                              message:
                                  'Your package "$parcelContents" has been selected by a traveler!',
                              type: 'traveler_selected',
                              parcelId: docs[i].id,
                            );
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Package added to MyTrips (Traveler)')));

                          _startTracking(docs[i].id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${d['id'] ?? docs[i].id} – ${d['contents']}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: _TravelerScreenState.darkTextBrown),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Sender: ${d['senderName']} • Category: ${d['category']}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                    Text(
                                        'Price: ₹${(d['price'] ?? 0).toString()}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _TravelerScreenState.accentOrange)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.call, color: _TravelerScreenState.primaryPurple),
                                    onPressed: () {
                                      final phone = d['senderPhone'] as String?;
                                      if (phone != null && phone.isNotEmpty) {
                                        launchUrl(Uri.parse('tel:$phone'));
                                      }
                                    },
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final packageCreatorUid =
                                          d['createdByUid'] as String?;
                                      if (packageCreatorUid != null) {
                                        final senderProfileDoc = await FirebaseFirestore
                                            .instance
                                            .collection('profiles')
                                            .doc(packageCreatorUid)
                                            .get();
                                        if (senderProfileDoc.exists) {
                                          final blockedUsers = List<String>.from(
                                              senderProfileDoc.data()?['blockedUsers'] ?? []);
                                          if (blockedUsers.contains(
                                              FirebaseAuth.instance.currentUser!.uid)) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'You cannot select this package as the sender has blocked you.'),
                                                  backgroundColor: Colors.red,
                                                ));
                                            return;
                                          }
                                        }
                                      }

                                      final uid = FirebaseAuth.instance.currentUser!.uid;
                                      final user = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .get();
                                      final travelerName =
                                          user.data()?['username'] ?? 'Traveler';
                                      final travelerPhone = widget.phoneCtrl.text.trim();

                                      if (travelerPhone.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Please enter your phone number before selecting a package.'),
                                              backgroundColor: Colors.red,
                                            ));
                                        return;
                                      }

                                      await FirebaseFirestore.instance
                                          .collection('parcels')
                                          .doc(docs[i].id)
                                          .update({
                                        'assignedTravelerUid': uid,
                                        'assignedTravelerName': travelerName,
                                        'assignedTravelerPhone': travelerPhone,
                                        'status': 'selected',
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      });

                                      final parcelDoc = await FirebaseFirestore.instance
                                          .collection('parcels')
                                          .doc(docs[i].id)
                                          .get();
                                      final parcelData =
                                          parcelDoc.data() as Map<String, dynamic>? ?? {};
                                      final senderUid =
                                          parcelData['createdByUid'] as String?;
                                      final receiverUid =
                                          parcelData['receiverUid'] as String?;
                                      final parcelContents =
                                          parcelData['contents'] as String? ?? 'your package';

                                      if (senderUid != null) {
                                        await _firestoreService.sendNotification(
                                          recipientUid: senderUid,
                                          message:
                                              'Your package "$parcelContents" has been selected by a traveler!',
                                          type: 'traveler_selected',
                                          parcelId: docs[i].id,
                                        );
                                      }
                                      if (receiverUid != null) {
                                        await _firestoreService.sendNotification(
                                          recipientUid: receiverUid,
                                          message:
                                              'Your package "$parcelContents" has been selected by a traveler!',
                                          type: 'traveler_selected',
                                          parcelId: docs[i].id,
                                        );
                                      }

                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Package added to MyTrips (Traveler)')));

                                      _startTracking(docs[i].id);
                                    },
                                    child: Text(
                                      'Select',
                                      style: GoogleFonts.poppins(
                                        color: _TravelerScreenState.primaryPurple,
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
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
