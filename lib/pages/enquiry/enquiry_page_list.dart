import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/pages/enquiry/add_enquiry.dart';
import 'package:leadassist/pages/salesman/salesman_list.dart';
import 'package:leadassist/widgets/enquiry_card.dart';

import '../../models/enquiry_model.dart';
import '../customer/customer_list_page.dart';
import '../auth.dart';
import '../my_profile.dart';

class EnquiryPageList extends StatefulWidget {
  final String role;
  const EnquiryPageList({super.key, required this.role});

  @override
  State<EnquiryPageList> createState() => _EnquiryPageListState();
}

class _EnquiryPageListState extends State<EnquiryPageList> {
  final CollectionReference enquiryCollection = FirebaseFirestore.instance
      .collection('enquiry');

  void onSelectDrawerItem(String item) {
    Navigator.pop(context); // Close drawer
    switch (item) {
      case "Home":
        // Already on Home, maybe refresh list
        break;
      case "My Profile":
        // Navigate to profile page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyProfilePage()),
        );
        break;
      case "Customers":
        // Navigate to customers page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomerListPage()),
        );
        break;
      case "Team":
        // Navigate to salesman/team page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SalesmanListPage()),
        );
        break;
      case "Logout":
        // Perform logout logic
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Auth()),
        );
        break;
    }
  }

  Stream<QuerySnapshot> _getEnquiryStream() {
    if (widget.role == "admin") {
      return enquiryCollection.orderBy("created_at", descending: true).snapshots();
    } else {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      return enquiryCollection
          .where("assignedTo", isEqualTo: uid)
          .orderBy("created_at", descending: true)
          .snapshots();
    }
  }

  Future<void> logoutAndGoToAuth(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Auth()),
            (Route<dynamic> route) => false, // remove all previous pages
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text("Enquiries"), actions: [
        IconButton(onPressed: () async{
          await logoutAndGoToAuth(context);
        }, icon: Icon(Icons.logout_outlined)),
      ],),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: const Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => onSelectDrawerItem("Home"),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("My Profile"),
              onTap: () => onSelectDrawerItem("My Profile"),
            ),
            if(widget.role == 'admin')...[
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Customers"),
                onTap: () => onSelectDrawerItem("Customers"),
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text("Team"),
                onTap: () => onSelectDrawerItem("Team"),
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => onSelectDrawerItem("Logout"),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: StreamBuilder(
            stream: _getEnquiryStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error"));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No Enquiries found."));
              }

              return Container(
                margin: EdgeInsets.all(8),
                child: Column(
                  children: docs.map((doc) {
                    final enquiry = Enquiry.fromJSON(
                      doc.data() as Map<String, dynamic>,
                    );
                    return EnquiryCard(enquiry: enquiry);
                  }).toList(),
                ),
              );
            },
          ),
          // child: Container(
          //   margin: EdgeInsets.all(16),
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.start,
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: mockEnquiries.map((enquiry) {
          //       final enquiryObj = Enquiry.fromJSON(enquiry);
          //       return EnquiryCard(
          //         enquiry: enquiryObj,
          //       );
          //     }).toList(),
          //   ),
          // ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEnquiryPage()),
          ),
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Enquiry"),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
