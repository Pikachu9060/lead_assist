import 'package:flutter/material.dart';
import '../models/enquiry_model.dart';
import '../pages/enquiry/enquiry_details_page.dart';

class EnquiryCard extends StatelessWidget {
  final Enquiry enquiry;

  const EnquiryCard({super.key, required this.enquiry});

  bool get isNew {
    // Optional: implement logic for new enquiries based on status or createdAt
    return enquiry.status == "pending";
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Navigate to enquiry details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnquiryDetailsPage(enquiry: enquiry),
          ),
        );
      },
      child: Stack(
        children: [
          /// Full-width Card
          SizedBox(
            width: double.infinity,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              shadowColor: Colors.deepPurple.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enquiry Title
                    Text(
                      enquiry.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 8),

                    // Assigned To
                    // Text(
                    //   "Assigned: ${enquiry.assignedTo}",
                    //   style: TextStyle(
                    //     color: Colors.grey.shade600,
                    //     fontSize: 14,
                    //   ),
                    // ),
                    // const SizedBox(height: 4),

                    // Customer ID
                    // Text(
                    //   "Customer ID: ${enquiry.customerId}",
                    //   style: TextStyle(
                    //     color: Colors.grey.shade600,
                    //     fontSize: 14,
                    //   ),
                    // ),
                    // const SizedBox(height: 4),

                    // Enquiry Type
                    Text(
                      "Type: ${enquiry.enquiryType}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status & Date
                    Text(
                      "Status: ${enquiry.status} | Created: ${enquiry.createdAt!.toDate()}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// NEW flag banner
          if (isNew)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  "NEW",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
