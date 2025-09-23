import 'package:flutter/material.dart';
import 'package:leadassist/models/enquiry_update_model.dart';
import '../pages/enquiry/enquiry_details_page.dart';

class EnquiryUpdateTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> updates;

  const EnquiryUpdateTimeline({super.key, required this.updates});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Updates",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (updates.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "No updates yet.",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final update = updates[index];
              final enquiryUpdate = EnquiryUpdate.fromDocument(update);
              final isLast = index == updates.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline line + dot
                  Column(
                    children: [
                      // Dot
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Line (only if not last)
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 60,
                          color: Colors.deepPurple.withOpacity(0.4),
                        ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Update card/info
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enquiryUpdate.description,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDate(enquiryUpdate.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
