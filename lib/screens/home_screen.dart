import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sender_screen.dart';
import 'traveler_screen.dart';
import 'receiver_screen.dart';
import 'my_trips_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'menu_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? username;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('uid');
    String? uid;

    if (savedUid != null) {
      uid = savedUid; // login via username/password
    } else {
      final user = FirebaseAuth.instance.currentUser;
      uid = user?.uid; // login via OTP
    }

    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          username = doc['username'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeContent(context),
      const MyTripsScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      drawer: MenuScreen(username: username),
      appBar: AppBar(
        backgroundColor: const Color(0xFF514ca1), // Primary Purple
        centerTitle: true,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Image.asset(
            'assets/images/text_logo.png',
            height: 35,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF514ca1), // Primary Purple
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6c5050).withOpacity(0.3), // Neutral/Dark Text Warm Brown
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFFf8af0b), // Highlight Yellow-Orange
          unselectedItemColor:
              const Color(0xFFf8af0b).withOpacity(0.7), // Highlight Yellow-Orange
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.luggage, size: 30),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history, size: 30),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 30),
              label: "",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF514ca1), // Primary Purple
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Text(
            "Welcome ${username ?? 'username'}",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        _buildActionPanel(
          context,
          "Sender",
          const Color(0xFF514ca1), // Primary Purple
          Icons.person,
          const SenderScreen(),
        ),
        _buildActionPanel(
          context,
          "Traveler",
           const Color(0xFFd79141), // Accent Olive Green
          Icons.directions_run,
          const TravelerScreen(),
        ),
        _buildActionPanel(
          context,
          "Receiver",
         const Color(0xFFa8ad5f), // Accent Orange
          Icons.home,
          const ReceiverScreen(),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildActionPanel(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Stack(
          children: [
            // Main background container with gradient and shadow
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.9), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              bottom: 10,
              child: Container(
                width: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
            ),
            Positioned(
              left: 85,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 25,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
