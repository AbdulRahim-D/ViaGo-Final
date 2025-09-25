import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:packmate/screens/package_detail_screen.dart';
import 'package:packmate/models/parcel.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _selectedParcelType = 'All';

  final primaryPurple = const Color(0xFF514ca1);
  final accentOliveGreen = const Color(0xFFa8ad5f);
  final accentOrange = const Color(0xFFd79141);
  final warmBrown = const Color(0xFF6c5050);
  final highlightYellowOrange = const Color(0xFFf8af0b);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: warmBrown,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryPurple),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(
        child: Text(
          'Please log in to view your trips.',
          style: GoogleFonts.poppins(color: warmBrown),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: primaryPurple,
          elevation: 0,
          title: Text(
            'My Trips',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: accentOliveGreen,
                  boxShadow: [
                    BoxShadow(
                      color: accentOliveGreen.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Sender'),
                  Tab(text: 'Traveler'),
                  Tab(text: 'Receiver'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: warmBrown.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: GoogleFonts.poppins(color: warmBrown),
                      decoration: InputDecoration(
                        hintText: 'Search by City or Address',
                        hintStyle: GoogleFonts.poppins(color: warmBrown.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: warmBrown),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: warmBrown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 5,
                            shadowColor: warmBrown.withOpacity(0.1),
                          ),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : DateFormat('dd MMM yyyy').format(_selectedDate!),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedParcelType,
                          style: GoogleFonts.poppins(color: warmBrown, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                            prefixIcon: Icon(Icons.category_outlined, color: warmBrown),
                          ),
                          dropdownColor: Colors.white,
                          items: <String>['All', 'Fragile', 'Fast Delivery']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedParcelType = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildParcelList(role: 'sender'),
                  _buildParcelList(role: 'traveler'),
                  _buildParcelList(role: 'receiver'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelList({required String role}) {
    List<String> statuses;
    switch (role) {
      case 'sender':
        statuses = ['posted', 'selected', 'confirmed', 'in_transit', 'awaiting_receiver_payment'];
        break;
      case 'traveler':
        statuses = ['selected', 'confirmed', 'in_transit', 'awaiting_receiver_payment'];
        break;
      case 'receiver':
        statuses = ['selected', 'confirmed', 'in_transit', 'awaiting_receiver_payment'];
        break;
      default:
        statuses = [];
    }

    if (statuses.isEmpty) {
      return Center(
        child: Text(
          'Invalid role.',
          style: GoogleFonts.poppins(color: warmBrown.withOpacity(0.6)),
        ),
      );
    }

    Query query = FirebaseFirestore.instance.collection('parcels')
        .where('status', whereIn: statuses);
    final uid = currentUser!.uid;

    if (role == 'sender') {
      query = query.where('createdByUid', isEqualTo: uid);
    } else if (role == 'traveler') {
      query = query.where('assignedTravelerUid', isEqualTo: uid);
    } else if (role == 'receiver') {
      query = query.where('receiverUid', isEqualTo: uid);
    }

    if (_searchQuery.isNotEmpty) {
      query = query.where('pickupCity', isGreaterThanOrEqualTo: _searchQuery)
          .where('pickupCity', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
    }

    if (_selectedDate != null) {
      final startOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final endOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);
      query = query.where('pickupDate', isGreaterThanOrEqualTo: startOfDay)
          .where('pickupDate', isLessThanOrEqualTo: endOfDay);
    }

    if (_selectedParcelType == 'Fragile') {
      query = query.where('fragile', isEqualTo: true);
    } else if (_selectedParcelType == 'Fast Delivery') {
      query = query.where('fastDelivery', isEqualTo: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return Center(child: Text('Error: ${s.error}'));
        }
        if (!s.hasData || s.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No packages found.',
              style: GoogleFonts.poppins(color: warmBrown.withOpacity(0.6)),
            ),
          );
        }

        final docs = s.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (c, i) {
            final parcel = Parcel.fromDoc(docs[i]);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) => PackageDetailScreen(
                          parcelId: parcel.id,
                          role: role,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: warmBrown.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                parcel.contents,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryPurple,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentOrange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                parcel.status,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: accentOliveGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                parcel.pickupCity,
                                style: GoogleFonts.poppins(
                                  color: warmBrown.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_right_alt, color: warmBrown, size: 24),
                            Expanded(
                              child: Text(
                                parcel.destCity,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.poppins(
                                  color: warmBrown.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.pin_drop, color: primaryPurple, size: 20),
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