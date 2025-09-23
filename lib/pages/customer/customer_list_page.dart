import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/models/user_model.dart';
import 'package:leadassist/pages/customer/add_customer.dart';
import 'package:leadassist/widgets/user_card.dart';
import 'package:leadassist/widgets/floating_action_button.dart';

import '../../mock_data.dart';

class CustomerListPage extends StatefulWidget{
  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {

  @override
  Widget build(BuildContext context) {
    final customerCollection = FirebaseFirestore.instance.collection("users").where('role',isEqualTo: "customer");

    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Customers"),
      ),
      body: SafeArea(
        child: StreamBuilder(stream: customerCollection.snapshots(), builder: (context, snapshot){
          if(snapshot.hasError){
            print(snapshot.error);
            return Center(child: Text("Error"),);
          }

          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator(),);
          }
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No customers found."));
          }

          return Column(
            children: docs.map((doc){
              final data = doc.data();
              final customerObj = UserModel.fromJson(data);
              return UserCard(customer: customerObj);
            }).toList(),
          );
        })
      ),
      floatingActionButton: CustomFloatingActionButton(navigationPage: AddCustomerPage(), buttonName: "Add Customer",),
    );
  }
}