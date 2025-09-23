import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/pages/salesman/add_salesman.dart';
import 'package:leadassist/widgets/floating_action_button.dart';

import '../../models/user_model.dart';
import '../../widgets/user_card.dart';

class SalesmanListPage extends StatefulWidget {
  @override
  State<SalesmanListPage> createState() => _SalesmanListPageState();
}

class _SalesmanListPageState extends State<SalesmanListPage> {
  @override
  Widget build(BuildContext context) {
    final customerCollection = FirebaseFirestore.instance
        .collection("users")
        .where('role', isEqualTo: "salesman");
    return Scaffold(
      appBar: AppBar(
        title: Text("Team"),
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(10),
        child: StreamBuilder(
          stream: customerCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print(snapshot.error);
              return Center(child: Text("Error"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("No Team Member found."));
            }

            return SingleChildScrollView(
              child: Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final customerObj = UserModel.fromJson(data);
                  return UserCard(customer: customerObj);
                }).toList(),
              ),
            );
          },
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        navigationPage: AddSalesmanPage(),
        buttonName: "Add Member",
      ),
    );
  }
}
