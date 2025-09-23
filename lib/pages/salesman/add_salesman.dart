import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/user_model.dart';

var uuid = Uuid();

class AddSalesmanPage extends StatefulWidget {
  final UserModel? salesman;
  const AddSalesmanPage({super.key, this.salesman});

  @override
  State<AddSalesmanPage> createState() => _AddSalesmanPageState();
}

class _AddSalesmanPageState extends State<AddSalesmanPage> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  final _formKey = GlobalKey<FormState>();
  String? selectedDistrict;

  final List<String> districtList = [
    "Pune",
    "Mumbai",
    "Bangalore",
    "Delhi",
    "Chennai",
    "Kolkata",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.salesman != null) {
      _nameController.text = widget.salesman!.name;
      _mobileController.text =
          widget.salesman!.mobileNumber.replaceFirst("+91", "");
      selectedDistrict = widget.salesman!.assignedDistrict;
    }
  }

  void saveSalesman() async {
    if (!_formKey.currentState!.validate()) return;

    String mobileNumber = "+91${_mobileController.text}";
    String salesmanId = widget.salesman?.id ?? "S_${uuid.v4()}";
    final docRef = usersCollection.doc(salesmanId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Query for any user with the same mobile number
        final querySnapshot = await usersCollection
            .where('mobile_number', isEqualTo: mobileNumber)
            .get();

        // Check if any conflicting user exists
        if (querySnapshot.docs.isNotEmpty) {
          // Allow if editing the same salesman
          if (widget.salesman == null ||
              (widget.salesman != null &&
                  querySnapshot.docs.first.id != widget.salesman!.id)) {
            throw Exception("Mobile number already exists");
          }
        }

        // Prepare salesman data
        final newSalesman = {
          "id": salesmanId,
          "name": _nameController.text,
          "mobile_number": mobileNumber,
          "assigned_district": selectedDistrict,
          "role": "salesman",
        };

        // Set or update the document atomically
        transaction.set(docRef, newSalesman, SetOptions(merge: true));
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Salesman saved successfully")),
        );
      }
    } catch (e) {
      print("Transaction failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple;
    final lightPurple = Colors.deepPurple[50];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.salesman == null ? "Add New Salesman" : "Edit Salesman"),
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
                      // Mobile Number
                      TextFormField(
                        controller: _mobileController,
                        validator: (value) {
                          if (widget.salesman == null) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter mobile number';
                            }
                            final regex = RegExp(r'^[6-9]\d{9}$');
                            if (!regex.hasMatch(value)) {
                              return 'Enter a valid 10-digit Indian mobile number';
                            }
                          }
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Mobile Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter name';
                          }
                          final regex = RegExp(r'^[a-zA-Z ]+$');
                          if (!regex.hasMatch(value)) {
                            return 'Name can only contain letters and spaces';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // District Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedDistrict,
                        items: districtList.map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedDistrict = val),
                        validator: (value) {
                          if (value == null) return 'Please select a district';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "District",
                          filled: true,
                          fillColor: lightPurple,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveSalesman,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.salesman == null ? "Save Salesman" : "Update Salesman",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
