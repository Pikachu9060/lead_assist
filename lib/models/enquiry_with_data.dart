import 'package:leadassist/models/user_model.dart';

import 'customer_model.dart';
import 'enquiry_model.dart';

class EnquiryWithData {
  final EnquiryModel enquiry;      // The main enquiry data
  final CustomerModel? customer;   // Related customer data
  final UserModel? salesman;       // Related salesman data

  EnquiryWithData({
    required this.enquiry,
    this.customer,
    this.salesman,
  });
}