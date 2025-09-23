import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import '../../models/user_model.dart';

var uuid = Uuid();

class AddCustomerPage extends StatefulWidget {
  final UserModel? customer;
  const AddCustomerPage({super.key,this.customer});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');
  final _formKey = GlobalKey<FormState>();

  String? selectedAssignedTo;

  final List<Map<String, String>> assignedToList = [
    {"name": "Ankit Verma", "district": "Pune"},
    {"name": "Priya Singh", "district": "Mumbai"},
    {"name": "Rohit Kumar", "district": "Bangalore"},
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _mobileController.text =
          widget.customer!.mobileNumber.replaceFirst("+91", ""); // remove prefix
      _addressController.text = widget.customer!.address ?? "";
    }
  }

  void saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    String mobileNumber = "+91${_mobileController.text}";
    String customerId = widget.customer?.id ?? "C_${uuid.v4()}";

    final docRef = usersCollection.doc(customerId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Query for any user with the same mobile number
        final querySnapshot = await usersCollection
            .where('mobile_number', isEqualTo: mobileNumber)
            .get();

        // Check if any conflicting user exists
        if (querySnapshot.docs.isNotEmpty) {
          // Allow if editing the same customer
          if (widget.customer == null ||
              (widget.customer != null &&
                  querySnapshot.docs.first.id != widget.customer!.id)) {
            throw Exception("Mobile number already exists");
          }
        }

        // Prepare new customer data
        final newCustomer = {
          "id": customerId,
          "name": _nameController.text,
          "mobile_number": mobileNumber,
          "address": _addressController.text,
          "role": "customer",
        };

        // Set or update the customer document
        transaction.set(docRef, newCustomer, SetOptions(merge: true));
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer saved successfully")),
        );
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add New Customer"),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }

                          // Regex: allows letters (a-z, A-Z) and spaces only
                          final regex = RegExp(r'^[a-zA-Z ]+$');
                          if (!regex.hasMatch(value)) {
                            return 'Name can only contain letters and spaces';
                          }

                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }

                          return null; // valid
                        },
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter mobile number';
                          }

                          // Regex: starts with 6-9, followed by 9 digits
                          final regex = RegExp(r'^[6-9]\d{9}$');

                          if (!regex.hasMatch(value)) {
                            return 'Enter a valid 10-digit Indian mobile number';
                          }

                          return null; // valid
                        },
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Mobile Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please Enter Address";
                          }
                          return null;
                        },
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: "Address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save Customer",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
