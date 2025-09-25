import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParcelStatusBar extends StatelessWidget {
  final String currentStatus;

  const ParcelStatusBar({super.key, required this.currentStatus});

  // Define brand colors
  static const Color primaryPurple = Color(0xFF514ca1);
  static const Color accentOliveGreen = Color(0xFFa8ad5f);
  static const Color accentOrange = Color(0xFFd79141);
  static const Color highlightYellowOrange = Color(0xFFf8af0b);
  static const Color neutralWarmBrown = Color(0xFF6c5050);

  @override
  Widget build(BuildContext context) {
    final List<String> statuses = [
      'posted',
      'accepted',
      'in transit',
      'delivered',
    ];

    int currentStatusIndex = statuses.indexOf(currentStatus);
    if (currentStatusIndex == -1) {
      currentStatusIndex = 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Progress',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: neutralWarmBrown,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(statuses.length, (index) {
              final status = statuses[index];
              final bool isActive = index <= currentStatusIndex;
              final bool isCurrent = index == currentStatusIndex;
              final bool isLast = index == statuses.length - 1;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Status Circle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive ? primaryPurple : neutralWarmBrown.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(
                                    color: accentOrange,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Icon(
                            index == 0
                                ? Icons.create_new_folder_rounded
                                : index == 1
                                    ? Icons.check_circle_outline_rounded
                                    : index == 2
                                        ? Icons.local_shipping_rounded
                                        : Icons.archive_rounded,
                            color: isActive ? Colors.white : neutralWarmBrown,
                            size: 16,
                          ),
                        ),
                        // Connecting Line
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isActive ? primaryPurple : neutralWarmBrown.withOpacity(0.2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status Text
                    Text(
                      status.replaceAll('_', ' ').toCapitalized(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isActive ? primaryPurple : neutralWarmBrown.withOpacity(0.7),
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
