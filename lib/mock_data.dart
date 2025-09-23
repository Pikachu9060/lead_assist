final List<Map<String, String>> mockCustomers = [
  {
    "customerId": "CUST001",
    "mobile": "9876543210",
    "name": "Rahul Sharma",
    "address": "123, Green Park, Pune, Maharashtra",
  },
  {
    "customerId": "CUST002",
    "mobile": "9123456789",
    "name": "Sneha Patil",
    "address": "45, MG Road, Mumbai, Maharashtra",
  },
  {
    "customerId": "CUST003",
    "mobile": "9988776655",
    "name": "Amit Joshi",
    "address": "78, Sector 12, Bangalore, Karnataka",
  },
  {
    "customerId": "CUST004",
    "mobile": "9012345678",
    "name": "Neha Kulkarni",
    "address": "56, Brigade Road, Bangalore, Karnataka",
  }
];

final List<Map<String, String>> mockEnquiries = [
  {
    "id": "e1",
    "enquiryTitle": "Bulk Order Request",
    "enquiryFor": "500 Plastic Chairs",
    "enquiryFrom": "John Doe",
    "date": "22 Sep 2025",
    "assignedTo": "S_Rahul",
  },
  {
    "id": "e2",
    "enquiryTitle": "Wedding Decoration",
    "enquiryFor": "Flower Arrangements & Lighting",
    "enquiryFrom": "Anita Sharma",
    "date": "20 Sep 2025",
    "assignedTo": "S_Priya",
  },
  {
    "id": "e3",
    "enquiryTitle": "Corporate Event Setup",
    "enquiryFor": "Stage + Sound System",
    "enquiryFrom": "XYZ Corp",
    "date": "18 Sep 2025",
    "assignedTo": "S_Arjun",
  },
  {
    "id": "e4",
    "enquiryTitle": "Birthday Party Supplies",
    "enquiryFor": "Balloons, Tables & Chairs",
    "enquiryFrom": "Rahul & Family",
    "date": "15 Sep 2025",
    "assignedTo": "S_Sneha",
  },
  {
    "id": "e5",
    "enquiryTitle": "Catering Service",
    "enquiryFor": "North Indian Food for 200 Guests",
    "enquiryFrom": "Foodies Pvt Ltd",
    "date": "12 Sep 2025",
    "assignedTo": "S_Amit",
  },
];


final List<Map<String, dynamic>> mockEnquiryUpdates = [
  // Updates for e1
  {
    "id": "u1",
    "enquiryId": "e1",
    "title": "Initial Contact",
    "description": "Called the client and discussed requirements.",
    "createdAt": DateTime(2025, 9, 22, 10, 30),
  },
  {
    "id": "u2",
    "enquiryId": "e1",
    "title": "Quotation Sent",
    "description": "Sent quotation for 500 chairs via email.",
    "createdAt": DateTime(2025, 9, 22, 15, 0),
  },

  // Updates for e2
  {
    "id": "u3",
    "enquiryId": "e2",
    "title": "Venue Confirmation",
    "description": "Confirmed the wedding venue details.",
    "createdAt": DateTime(2025, 9, 20, 11, 0),
  },

  // Updates for e3
  {
    "id": "u4",
    "enquiryId": "e3",
    "title": "Equipment Booking",
    "description": "Booked stage and sound system.",
    "createdAt": DateTime(2025, 9, 18, 14, 30),
  },
  {
    "id": "u5",
    "enquiryId": "e3",
    "title": "Site Visit",
    "description": "Visited corporate site for layout confirmation.",
    "createdAt": DateTime(2025, 9, 18, 16, 0),
  },

  // Updates for e4
  {
    "id": "u6",
    "enquiryId": "e4",
    "title": "Decor Items List",
    "description": "Prepared list of balloons, tables, and chairs.",
    "createdAt": DateTime(2025, 9, 15, 10, 0),
  },

  // Updates for e5
  {
    "id": "u7",
    "enquiryId": "e5",
    "title": "Menu Discussion",
    "description": "Discussed North Indian menu for 200 guests.",
    "createdAt": DateTime(2025, 9, 12, 13, 30),
  },
  {
    "id": "u8",
    "enquiryId": "e5",
    "title": "Quote Shared",
    "description": "Shared catering quotation via email.",
    "createdAt": DateTime(2025, 9, 12, 15, 45),
  },
];
