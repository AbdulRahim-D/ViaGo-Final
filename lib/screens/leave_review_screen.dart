import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:packmate/models/review.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String parcelId;
  final String fromUid;
  final String toUid;
  final String role;

  const LeaveReviewScreen({
    super.key,
    required this.parcelId,
    required this.fromUid,
    required this.toUid,
    required this.role,
  });

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  double _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  final Color _primaryPurple = const Color(0xFF514ca1);
  final Color _accentOliveGreen = const Color(0xFFa8ad5f);
  final Color _accentOrange = const Color(0xFFd79141);
  final Color _highlightYellowOrange = const Color(0xFFf8af0b);
  final Color _neutralWarmBrown = const Color(0xFF6c5050);

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
      final review = Review(
        id: reviewRef.id,
        rating: _rating,
        text: _reviewController.text.trim(),
        fromUid: widget.fromUid,
        toUid: widget.toUid,
        parcelId: widget.parcelId,
        role: widget.role,
        createdAt: DateTime.now(),
      );

      final profileRef =
          FirebaseFirestore.instance.collection('profiles').doc(widget.toUid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final profileSnapshot = await transaction.get(profileRef);

        if (!profileSnapshot.exists) {
          // Create profile if it doesn't exist
          transaction.set(profileRef, {
            'ratingCount': 1,
            'totalRating': _rating,
            'averageRating': _rating,
          });
        } else {
          final currentRatingCount = profileSnapshot.data()!['ratingCount'] ?? 0;
          final currentTotalRating =
              profileSnapshot.data()!['totalRating'] ?? 0.0;

          final newRatingCount = currentRatingCount + 1;
          final newTotalRating = currentTotalRating + _rating;
          final newAverageRating = newTotalRating / newRatingCount;

          transaction.update(profileRef, {
            'ratingCount': newRatingCount,
            'totalRating': newTotalRating,
            'averageRating': newAverageRating,
          });
        }

        transaction.set(reviewRef, review.toMap());
      });

      // Mark this user as having reviewed this parcel interaction
      final parcelRef =
          FirebaseFirestore.instance.collection('parcels').doc(widget.parcelId);
      await parcelRef.update({
        'reviewsGiven.${widget.fromUid}': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Leave a Review',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rating section
            Text(
              'Your Rating',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _neutralWarmBrown,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _highlightYellowOrange,
                      size: 48,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),

            // Review text field
            Text(
              'Your Review',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _neutralWarmBrown,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reviewController,
              maxLines: 5,
              style: GoogleFonts.poppins(
                color: _neutralWarmBrown,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                hintText: 'Share your experience...',
                hintStyle: GoogleFonts.poppins(
                  color: _neutralWarmBrown.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _accentOrange,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 40),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _accentOliveGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: _accentOliveGreen.withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Review',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}