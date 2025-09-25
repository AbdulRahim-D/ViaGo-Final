import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Added for typography
import 'package:packmate/screens/chat_screen.dart';
import 'package:packmate/services/firestore_service.dart';
import 'package:packmate/services/storage_service.dart';
import 'package:packmate/services/pricing.dart';
import 'package:packmate/services/wallet_service.dart';
import 'otp_confirm_screen.dart';
import 'otp_delivery_screen.dart';
import 'package:packmate/screens/receiver_payment_screen.dart';
import 'package:packmate/widgets/parcel_status_bar.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:packmate/models/report.dart';
import 'package:packmate/screens/leave_review_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_storage/firebase_storage.dart';

// 🎨 ViaGo Color Palette
const kPrimaryPurple = Color(0xFF514ca1);
const kAccentOliveGreen = Color(0xFFa8ad5f);
const kAccentOrange = Color(0xFFd79141);
const kHighlightYellowOrange = Color(0xFFf8af0b);
const kNeutralWarmBrown = Color(0xFF6c5050);

class PackageDetailScreen extends StatefulWidget {
  final String parcelId;
  final String role;

  const PackageDetailScreen({
    super.key,
    required this.parcelId,
    required this.role,
  });

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  late final WalletService _walletService;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initPlayer();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _walletService = WalletService(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    final tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/flutter_sound.aac';
    await _recorder.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _uploadVoiceNote();
  }

  Future<void> _uploadVoiceNote() async {
    if (_filePath == null) return;
    final downloadUrl =
        await _storageService.uploadVoiceNote(_filePath!, widget.parcelId);
    await _firestoreService
        .updateParcel(widget.parcelId, {'voiceNoteUrl': downloadUrl});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice note uploaded!')),
      );
    }
  }

  Future<void> _playVoiceNote(Map<String, dynamic> parcel) async {
    if (parcel['voiceNoteUrl'] == null) return;
    await _player.startPlayer(
      fromURI: parcel['voiceNoteUrl'],
      whenFinished: () {
        setState(() {
          _isPlaying = false;
        });
      },
    );
    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _stopPlaying() async {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
        );
      }
    }
  }

  void _chatWith(String otherUserId, String otherUserName) {
    final currentUserId = _firestoreService.uid;
    final chatRoomId = _firestoreService.getChatRoomId(
        widget.parcelId, currentUserId, otherUserId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoomId: chatRoomId,
          recipientName: otherUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Package #${widget.parcelId.substring(0, 8)}...",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: kNeutralWarmBrown,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralWarmBrown),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parcels')
            .doc(widget.parcelId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final parcel = snapshot.data!.data() as Map<String, dynamic>;

          final isSender = widget.role == 'sender';
          final isTraveler = widget.role == 'traveler';
          final isReceiver = widget.role == 'receiver';

          final senderId = parcel['createdByUid'];
          final travelerId = parcel['assignedTravelerUid'];
          final receiverId = parcel['receiverUid'];

          final senderName = parcel['senderName'] ?? 'Sender';
          final travelerName = parcel['assignedTravelerName'] ?? 'Traveler';
          final receiverName = parcel['receiverName'] ?? 'Receiver';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contents: ${parcel['contents']}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kNeutralWarmBrown,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          'Sender:', '$senderName (${parcel['senderPhone']})',
                          () {
                        if (isTraveler || isReceiver) {
                          _makePhoneCall(parcel['senderPhone']);
                        }
                      }),
                      _buildInfoRow('Receiver:',
                          '$receiverName (${parcel['receiverPhone']})', () {
                        if (isSender || isTraveler) {
                          _makePhoneCall(parcel['receiverPhone']);
                        }
                      }),
                      if (travelerId != null)
                        _buildInfoRow(
                            'Traveler:',
                            '$travelerName (${parcel['assignedTravelerPhone'] ?? ''})',
                            () {
                          if ((isSender || isReceiver) &&
                              parcel['assignedTravelerPhone'] != null) {
                            _makePhoneCall(parcel['assignedTravelerPhone']);
                          }
                        }),
                      const SizedBox(height: 8),
                      Text(
                        'Pickup: ${parcel['pickupCity']}',
                        style: GoogleFonts.poppins(color: kNeutralWarmBrown),
                      ),
                      Text(
                        'Destination: ${parcel['destCity']}',
                        style: GoogleFonts.poppins(color: kNeutralWarmBrown),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: ₹${parcel['price']}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryPurple),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${parcel['status'].toString().replaceAll('_', ' ')}',
                        style: GoogleFonts.poppins(
                            fontStyle: FontStyle.italic,
                            color: kNeutralWarmBrown),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Parcel Status Bar
                _buildCard(
                  child: ParcelStatusBar(currentStatus: parcel['status']),
                ),
                const SizedBox(height: 24),

                // Map View
                if ((isSender || isReceiver) &&
                    parcel['latitude'] != null &&
                    parcel['longitude'] != null)
                  _buildCard(
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(
                            (parcel['latitude'] ?? 0).toDouble(),
                            (parcel['longitude'] ?? 0).toDouble(),
                          ),
                          zoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(
                                  (parcel['latitude'] ?? 0).toDouble(),
                                  (parcel['longitude'] ?? 0).toDouble(),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Communications
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Communications',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kNeutralWarmBrown),
                      ),
                      const SizedBox(height: 12),
                      if (isSender) _buildVoiceNoteRecorder(),
                      if (isTraveler && parcel['voiceNoteUrl'] != null)
                        _buildVoiceNotePlayer(parcel),
                      const SizedBox(height: 16),
                      if (isSender && travelerId != null)
                        _buildButton(
                          onPressed: () => _chatWith(travelerId, travelerName),
                          label: 'Chat with Traveler',
                          icon: Icons.chat,
                          color: kPrimaryPurple,
                        ),
                      if (isTraveler) ...[
                        _buildButton(
                          onPressed: () => _chatWith(senderId, senderName),
                          label: 'Chat with Sender',
                          icon: Icons.chat,
                          color: kPrimaryPurple,
                        ),
                        _buildButton(
                          onPressed: receiverId != null
                              ? () => _chatWith(receiverId, receiverName)
                              : null,
                          label: 'Chat with Receiver',
                          icon: Icons.chat,
                          color: kPrimaryPurple,
                        ),
                      ],
                      if (isReceiver && travelerId != null)
                        _buildButton(
                          onPressed: () => _chatWith(travelerId, travelerName),
                          label: 'Chat with Traveler',
                          icon: Icons.chat,
                          color: kPrimaryPurple,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Delivery Proof
                if (isTraveler && parcel['status'] == 'in_transit')
                  _buildButton(
                    onPressed: () => _uploadDeliveryProof(parcel),
                    label: 'Upload Delivery Proof',
                    icon: Icons.camera_alt,
                    color: kAccentOliveGreen,
                  ),
                if (parcel['deliveryProofUrl'] != null)
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Proof:',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kNeutralWarmBrown),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(parcel['deliveryProofUrl']),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Action Buttons
                _buildCard(
                  child: Column(
                    children: [
                      _buildReviewButton(context, parcel),
                      _buildReportButtons(context, parcel),
                      _buildBlockButtons(context, parcel),
                      _buildCancelButton(context, parcel),
                      if (widget.role == 'traveler') ...[
                        if (parcel['status'] == 'selected')
                          _buildButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OtpConfirmScreen(parcelId: widget.parcelId),
                                ),
                              );
                            },
                            label: "Confirm Order (OTP from Sender)",
                            icon: Icons.verified_user,
                            color: kAccentOliveGreen,
                          ),
                        if (parcel['status'] == 'in_transit' &&
                            parcel['paymentStatus'] == 'pending_on_delivery')
                          _buildButton(
                            onPressed: () async {
                              await _firestoreService.updateParcel(widget.parcelId, {
                                'status': 'awaiting_receiver_payment',
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Payment request sent to the receiver.')),
                                );
                              }
                            },
                            label: "Request Payment from Receiver",
                            icon: Icons.monetization_on,
                            color: kAccentOliveGreen,
                          ),
                        if (parcel['status'] == 'awaiting_receiver_payment')
                          _buildButton(
                            onPressed: null,
                            label: "Waiting for Receiver to Pay",
                            icon: Icons.hourglass_empty,
                          ),
                        if (parcel['status'] == 'in_transit' &&
                            parcel['paymentStatus'] == 'paid')
                          _buildButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OtpDeliveryScreen(parcelId: widget.parcelId),
                                ),
                              );
                            },
                            label: "Proceed to Delivery OTP",
                            icon: Icons.delivery_dining,
                            color: kAccentOliveGreen,
                          ),
                      ],
                      if (widget.role == 'receiver' &&
                          parcel['status'] == 'awaiting_receiver_payment')
                        _buildButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReceiverPaymentScreen(
                                  parcelId: widget.parcelId,
                                  receiverUid: parcel['receiverUid'],
                                  senderUid: parcel['createdByUid'],
                                  amount: (parcel['price'] ?? 0.0).toDouble(),
                                ),
                              ),
                            );
                          },
                          label: "Pending Payment: Pay Now",
                          icon: Icons.payments,
                          color: kHighlightYellowOrange,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    Color color = kAccentOliveGreen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, VoidCallback onCall) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: kNeutralWarmBrown,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: kNeutralWarmBrown),
            ),
          ),
          if (onCall != null)
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.phone, color: kPrimaryPurple),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceNoteRecorder() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          label: Text(_isRecording ? 'Stop Recording' : 'Record Voice Note'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.red : kPrimaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
        ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Recording...',
                style: GoogleFonts.poppins(color: kNeutralWarmBrown)),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildVoiceNotePlayer(Map<String, dynamic> parcel) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isPlaying ? _stopPlaying : () => _playVoiceNote(parcel),
          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
          label: Text(_isPlaying ? 'Stop' : 'Play Voice Note'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPlaying ? kAccentOrange : kPrimaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
        ),
        if (_isPlaying)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Playing...',
                style: GoogleFonts.poppins(color: kNeutralWarmBrown)),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _uploadDeliveryProof(Map<String, dynamic> parcel) async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (img != null) {
      final f = File(img.path);
      final ref =
          FirebaseStorage.instance.ref('delivery_proofs/${widget.parcelId}.jpg');
      await ref.putFile(f);
      final url = await ref.getDownloadURL();
      await _firestoreService
          .updateParcel(widget.parcelId, {'deliveryProofUrl': url});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery proof uploaded!')),
        );
      }
    }
  }

  Widget _buildDeliveryProofViewer(Map<String, dynamic> parcel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Proof:',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kNeutralWarmBrown)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(parcel['deliveryProofUrl']),
        ),
      ],
    );
  }

  Widget _buildReviewButton(BuildContext context, Map<String, dynamic> parcel) {
    final role = widget.role;
    final currentUserUid = _firestoreService.uid;
    final isDelivered = parcel['status'] == 'delivered';

    if (!isDelivered) {
      return const SizedBox.shrink();
    }

    final reviewsGiven = parcel['reviewsGiven'] as Map<String, dynamic>? ?? {};
    final hasUserReviewed = reviewsGiven[currentUserUid] == true;

    if (hasUserReviewed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('You have already reviewed this delivery.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontStyle: FontStyle.italic, color: kNeutralWarmBrown)),
      );
    }

    String? toUid;
    String toRole = '';
    if (role == 'sender') {
      toUid = parcel['assignedTravelerUid'];
      toRole = 'traveler';
    } else if (role == 'traveler') {
      toUid = parcel['createdByUid'];
      toRole = 'sender';
    }

    if (toUid == null) {
      return const SizedBox.shrink();
    }

    return _buildButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeaveReviewScreen(
              parcelId: widget.parcelId,
              fromUid: currentUserUid,
              toUid: toUid!,
              role: role,
            ),
          ),
        );
      },
      label: 'Rate and Review $toRole',
      icon: Icons.star,
      color: kHighlightYellowOrange,
    );
  }

  void _showReportDialog(String reportedUid) {
    final reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Report User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TextFormField(
            controller: reportController,
            decoration: const InputDecoration(hintText: 'Reason for reporting...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reportController.text.trim().isEmpty) {
                  return;
                }
                final reportRef =
                    FirebaseFirestore.instance.collection('reports').doc();
                final report = Report(
                  id: reportRef.id,
                  reason: reportController.text.trim(),
                  reportedByUid: _firestoreService.uid,
                  reportedUid: reportedUid,
                  parcelId: widget.parcelId,
                  createdAt: DateTime.now(),
                );
                await reportRef.set(report.toMap());
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted.')),
                  );
                }
              },
              child: Text('Submit', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportButtons(
      BuildContext context, Map<String, dynamic> parcel) {
    final role = widget.role;
    List<Widget> buttons = [];

    if (role == 'sender') {
      final travelerUid = parcel['assignedTravelerUid'];
      if (travelerUid != null) {
        buttons.add(
          _buildButton(
            onPressed: () => _showReportDialog(travelerUid),
            label: 'Report Traveler',
            icon: Icons.report,
            color: kAccentOrange,
          ),
        );
      }
    } else if (role == 'traveler') {
      final senderUid = parcel['createdByUid'];
      final receiverUid = parcel['receiverUid'];
      buttons.add(
        _buildButton(
          onPressed: () => _showReportDialog(senderUid),
          label: 'Report Sender',
          icon: Icons.report,
          color: kAccentOrange,
        ),
      );
      if (receiverUid != null) {
        buttons.add(
          _buildButton(
            onPressed: () => _showReportDialog(receiverUid),
            label: 'Report Receiver',
            icon: Icons.report,
            color: kAccentOrange,
          ),
        );
      }
    } else if (role == 'receiver') {
      final travelerUid = parcel['assignedTravelerUid'];
      if (travelerUid != null) {
        buttons.add(
          _buildButton(
            onPressed: () => _showReportDialog(travelerUid),
            label: 'Report Traveler',
            icon: Icons.report,
            color: kAccentOrange,
          ),
        );
      }
    }

    return Column(children: buttons);
  }

  void _showBlockDialog(String blockedUid, String blockedUserName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Block $blockedUserName?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
              'They will not be able to see your packages, and you will not see theirs.',
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentUserUid = _firestoreService.uid;
                final profileRef = FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(currentUserUid);
                await profileRef.update({
                  'blockedUsers': FieldValue.arrayUnion([blockedUid])
                });
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('$blockedUserName has been blocked.',
                            style: GoogleFonts.poppins())),
                  );
                }
              },
              child: Text('Block', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlockButtons(BuildContext context, Map<String, dynamic> parcel) {
    final role = widget.role;
    List<Widget> buttons = [];

    if (role == 'sender') {
      final travelerUid = parcel['assignedTravelerUid'];
      final travelerName = parcel['assignedTravelerName'] ?? 'Traveler';
      if (travelerUid != null) {
        buttons.add(
          _buildButton(
            onPressed: () => _showBlockDialog(travelerUid, travelerName),
            label: 'Block Traveler',
            icon: Icons.block,
            color: kAccentOrange,
          ),
        );
      }
    } else if (role == 'traveler') {
      final senderUid = parcel['createdByUid'];
      final senderName = parcel['senderName'] ?? 'Sender';
      buttons.add(
        _buildButton(
          onPressed: () => _showBlockDialog(senderUid, senderName),
          label: 'Block Sender',
          icon: Icons.block,
          color: kAccentOrange,
        ),
      );
    }

    return Column(children: buttons);
  }

  Widget _buildCancelButton(BuildContext context, Map<String, dynamic> parcel) {
    final isSender = widget.role == 'sender';
    final isCancellable =
        parcel['status'] != 'delivered' && parcel['status'] != 'canceled';

    if (!isSender || !isCancellable) {
      return const SizedBox.shrink();
    }

    return _buildButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cancel Parcel?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Text(
                'Are you sure you want to cancel this parcel? This action cannot be undone.', style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('No', style: GoogleFonts.poppins())),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Yes, Cancel', style: GoogleFonts.poppins())),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseFirestore.instance
              .collection('parcels')
              .doc(widget.parcelId)
              .update({
            'status': 'canceled',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          final packagePrice = (parcel['price'] ?? 0.0).toDouble();
          final senderUid = parcel['createdByUid'];

          if (parcel['status'] == 'confirmed' ||
              parcel['status'] == 'selected') {
            await _walletService.refundMoney(
                senderUid, packagePrice, widget.parcelId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Parcel canceled and ₹${packagePrice.toStringAsFixed(2)} refunded to your wallet.')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Parcel canceled.')),
              );
            }
          }
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      label: 'Cancel Parcel',
      icon: Icons.cancel,
      color: Colors.orange,
    );
  }
}
