import 'package:url_launcher/url_launcher.dart';

Future<void> sendCredentialsEmail({
  required String email,
  required String customerId,
  required String password,
}) async {
  final subject = Uri.encodeComponent("Your Login Credentials");
  final body = Uri.encodeComponent("""
Hello,

Here are your login credentials:

Customer ID: $customerId
Password: $password

Please keep this information safe.

Thanks,
Your Company
""");

  final Uri emailUri = Uri.parse("mailto:$email?subject=$subject&body=$body");

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    throw Exception("Could not launch email app");
  }
}
