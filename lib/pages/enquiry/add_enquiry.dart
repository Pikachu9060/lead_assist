import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../customer/add_customer.dart';

final uuid = Uuid();

class AddEnquiryPage extends StatefulWidget {
  const AddEnquiryPage({super.key});

  @override
  State<AddEnquiryPage> createState() => _AddEnquiryPageState();
}

class _AddEnquiryPageState extends State<AddEnquiryPage> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? selectedCustomer;
  final CollectionReference enquiryCollection = FirebaseFirestore.instance
      .collection('enquiry');

  final List<String> enquiryTypes = ["Solar", "Electronics"];
  List<Map<String, dynamic>> assignedToList = [];

  String? selectedEnquiryType;
  Map<String, String>? selectedAssignedToMap;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Fetching from Firestore
    FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "salesman")
        .get()
        .then((snapshot) {
          setState(() {
            assignedToList = snapshot.docs.map<Map<String, String>>((doc) {
              final data = doc.data(); // Firestore returns dynamic map
              return {"id": data["id"] ?? "", "name": data["name"] ?? ""};
            }).toList();
          });
        });
  }

  void searchCustomer() async {
    var data = await FirebaseFirestore.instance
        .collection("users")
        .where("mobile_number", isEqualTo: "+91${_mobileController.text}")
        .where("role", isEqualTo: "customer")
        .limit(1)
        .get();
    if (data.docs.isNotEmpty) {
      setState(() {
        selectedCustomer = data.docs.first.data();
      });
    } else {
      setState(() {
        selectedCustomer = null;
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No Customer Found"),
          action: SnackBarAction(
            label: "label",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCustomerPage()),
              );
            },
          ),
        ),
      );
      }
    }
  }

  void submitEnquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final enquiryId = uuid.v4();
    final newEnquiry = {
      "id": enquiryId,
      "status": "pending",
      "created_at": DateTime.now(),
      "updated_at": null,
      "customer_id": selectedCustomer!["id"],
      "title": _titleController.text,
      "description": _descriptionController.text,
      "enquiry_type": selectedEnquiryType,
      "assigned_to": selectedAssignedToMap!["id"],
    };

    await enquiryCollection
        .doc(enquiryId)
        .set(newEnquiry)
        .then((value) {
          if (mounted) {
            Navigator.pop(context);
          }
        })
        .catchError((err) {
        });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple;
    final lightPurple = Colors.deepPurple[50];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Enquiry"),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mobile Search
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Field Cannot be Empty";
                            }
                            return null;
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
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: searchCustomer,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          backgroundColor: primaryColor,
                        ),
                        child: const Text("Search"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer Details
              if (selectedCustomer != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  color: lightPurple,
                  child: ListTile(
                    title: Text(
                      "Name : ${selectedCustomer!["name"]!}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Address : ${selectedCustomer?["address"] ?? "N/A"}\nMo.No : ${selectedCustomer?["mobile_number"] ?? "N/A"}",
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              const Text(
                "Enquiry Details",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),

              // Title
              TextFormField(
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Field Cannot be Empty";
                  }
                  return null;
                },
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  filled: true,
                  fillColor: lightPurple,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Field Cannot be Empty";
                  }
                  return null;
                },
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Description",
                  filled: true,
                  fillColor: lightPurple,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Enquiry Type Dropdown
              DropdownButtonFormField<String>(
                value: selectedEnquiryType,
                items: enquiryTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => selectedEnquiryType = val),
                decoration: InputDecoration(
                  labelText: "Enquiry Type",
                  filled: true,
                  fillColor: lightPurple,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Assigned To Dropdown
              DropdownButtonFormField<Map<String, String>>(
                value: selectedAssignedToMap,
                items: assignedToList
                    .map<DropdownMenuItem<Map<String, String>>>((user) {
                      return DropdownMenuItem<Map<String, String>>(
                        value:
                            user as Map<String, String>, // store the entire map
                        child: Text(user["name"] ?? ""),
                      );
                    })
                    .toList(),
                onChanged: (val) => setState(() => selectedAssignedToMap = val),
                decoration: InputDecoration(
                  labelText: "Assigned To",
                  filled: true,
                  fillColor: lightPurple,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitEnquiry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Submit Enquiry",
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
