import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Help & FAQs", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF514ca1),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            "Welcome to Packmate Help!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            "Find answers to common questions below. If you still need help, please visit the Support screen.",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 24),
          ExpansionTile(
            title: Text("For Senders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            children: [
              ListTile(
                title: Text("How do I send a package?"),
                subtitle: Text("Navigate to the 'Sender' screen from the home page. Fill in all the required details about your parcel, including pickup and destination, and receiver information. Once you submit, your parcel will be listed for travelers to see."),
              ),
              ListTile(
                title: Text("How is the price calculated?"),
                subtitle: Text("The estimated price is calculated based on the weight and dimensions of your parcel, the distance of the delivery, and whether you opt for fast delivery or fragile handling."),
              ),
              ListTile(
                title: Text("What are the payment options?"),
                subtitle: Text("You can choose to 'Pay Now' using your wallet or other simulated payment methods, or you can opt for 'Pay on Delivery' where the payment is handled upon successful delivery confirmation."),
              ),
            ],
          ),
          ExpansionTile(
            title: Text("For Travelers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            children: [
              ListTile(
                title: Text("How do I become a traveler?"),
                subtitle: Text("Go to the 'Traveler' screen and enter your trip details, including your route, travel date, and carrying capacity. Once you update your trip, you can see available packages on your route."),
              ),
              ListTile(
                title: Text("How do I find packages to deliver?"),
                subtitle: Text("After setting up your trip on the 'Traveler' screen, a list of available packages matching your route will be displayed. You can then select a package to deliver."),
              ),
            ],
          ),
          ExpansionTile(
            title: Text("For Receivers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            children: [
              ListTile(
                title: Text("How do I track my package?"),
                subtitle: Text("On the 'Receiver' screen, enter your name, phone number, and the Receiver ID provided by the sender to find and track your package."),
              ),
              ListTile(
                title: Text("What is a Receiver ID?"),
                subtitle: Text("The Receiver ID is a unique identifier for your delivery, set by the sender. You need this ID to track your parcel."),
              ),
              ListTile(
                title: Text("What is the delivery OTP?"),
                subtitle: Text("For some deliveries, a One-Time Password (OTP) is required to confirm receipt of the package. This ensures a secure handover."),
              ),
            ],
          ),
        ],
      ),
    );
  }
}