import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showDrawer;
  final Widget? floatingActionButton;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showDrawer = false,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: showDrawer ? _buildDrawer(context) : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Lead Assist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Salesmen'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to salesmen
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Implement logout
            },
          ),
        ],
      ),
    );
  }
}