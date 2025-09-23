import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leadassist/models/user_model.dart';
import 'package:leadassist/widgets/enquiry_update_timeline.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../models/enquiry_model.dart';

final uuid = Uuid();

String formatDate(DateTime date) => DateFormat("dd MMM yyyy, hh:mm a").format(date);

class EnquiryDetailsPage extends StatefulWidget {
  final Enquiry enquiry;

  const EnquiryDetailsPage({super.key, required this.enquiry});

  @override
  State<EnquiryDetailsPage> createState() => _EnquiryDetailsPageState();
}

class _EnquiryDetailsPageState extends State<EnquiryDetailsPage> {
  late final ValueNotifier<String> statusNotifier;
  late final ValueNotifier<List<Map<String, dynamic>>> updatesNotifier;
  final TextEditingController descController = TextEditingController();

  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference updatesCollection = FirebaseFirestore.instance.collection('updates');
  final CollectionReference enquiryCollection = FirebaseFirestore.instance.collection('enquiry');

  @override
  void initState() {
    super.initState();
    statusNotifier = ValueNotifier(widget.enquiry.status);
    updatesNotifier = ValueNotifier([]);
    _loadInitialUpdates();
  }

  Future<void> _loadInitialUpdates() async {
    final snapshot = await updatesCollection
        .where("enquiryId", isEqualTo: widget.enquiry.id)
        .orderBy("created_at", descending: true)
        .get();

    updatesNotifier.value = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Convert Firestore Timestamp to DateTime
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp).toDate();
      }
      return data;
    }).toList();
  }

  Future<UserModel?> fetchUser(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
    }
    return null;
  }

  Future<void> addUpdateToFirestore() async {
    final updateId = "U_${uuid.v4()}";
    final createAt = DateTime.now();
    final update = {
      "id": updateId,
      "description": descController.text.trim(),
      "created_at": createAt,
      "enquiryId": widget.enquiry.id,
    };

    if (update["description"] != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Description cannot be empty")));
      return;
    }

    try {
      await enquiryCollection.doc(widget.enquiry.id).update({"updated_at": createAt});
      await updatesCollection.doc(updateId).set(update);

      // Append new update locally
      updatesNotifier.value = [update, ...updatesNotifier.value];

      if(mounted){
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Update Added Successfully")));

        descController.clear();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to add update")));
      }
    }
  }

  void _addUpdate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Update"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton.icon(
            onPressed: addUpdateToFirestore,
            icon: const Icon(Icons.add),
            label: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _launchDialer(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final enquiry = widget.enquiry;

    return Scaffold(
      appBar: AppBar(title: const Text("Enquiry Details"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- Customer Info ---
            FutureBuilder<UserModel?>(
              future: fetchUser(enquiry.customerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Customer not found');
                }
                final user = snapshot.data!;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue[100],
                      child: Text(user.name[0],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _launchDialer(user.mobileNumber),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(user.mobileNumber,
                                    style: const TextStyle(
                                        color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),

            /// --- Enquiry Info ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        enquiry.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    // Status chip
                    ValueListenableBuilder<String>(
                      valueListenable: statusNotifier,
                      builder: (context, currentStatus, _) {
                        final statusList = [
                          "New",
                          "Pending",
                          "In Progress",
                          "Completed",
                          "Cancelled"
                        ];
                        // Fallback if currentStatus is invalid
                        if (!statusList.contains(currentStatus)) currentStatus = "New";

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              final newStatus = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  String tempStatus = currentStatus;
                                  return StatefulBuilder(
                                    builder: (context, setState) => AlertDialog(
                                      title: const Text("Update Status"),
                                      content: DropdownButtonFormField<String>(
                                        value: tempStatus,
                                        items: statusList
                                            .map((status) =>
                                            DropdownMenuItem(value: status, child: Text(status)))
                                            .toList(),
                                        onChanged: (val) => setState(() => tempStatus = val!),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text("Cancel")),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, tempStatus),
                                          child: const Text("Update"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );

                              if (newStatus != null && newStatus != currentStatus) {
                                await enquiryCollection
                                    .doc(enquiry.id)
                                    .update({"status": newStatus});
                                statusNotifier.value = newStatus;
                              }
                            },
                            child: Row(
                              children: [
                                Text(currentStatus,
                                    style: const TextStyle(
                                        color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 18, color: Colors.deepPurple),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(enquiry.description,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Type: ${enquiry.enquiryType}", style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 4),
                Text("Created: ${enquiry.createdAt!.toDate()}",
                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                if (enquiry.updatedAt != null) ...[
                  const SizedBox(height: 4),
                  Text("Updated: ${enquiry.updatedAt!.toDate()}",
                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            /// --- Updates Timeline ---
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: updatesNotifier,
              builder: (context, updates, _) {
                if (updates.isEmpty) {
                  return const Center(child: Text("No Updates found."));
                }
                return EnquiryUpdateTimeline(updates: updates);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addUpdate(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Update"),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
