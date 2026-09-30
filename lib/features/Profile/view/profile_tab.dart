import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../Login/view/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryNavy,
              child: Icon(Icons.person, size: 60, color: AppTheme.brandRed),
            ),
            const SizedBox(height: 16),
            Text(user?.email ?? 'student@brahmastra.com',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email, color: AppTheme.primaryNavy),
                title: const Text('Email ID'),
                subtitle: Text(user?.email ?? 'N/A'),
              ),
            ),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.verified, color: AppTheme.primaryNavy),
                title: const Text('Status'),
                subtitle: Text(user != null ? 'Active Member' : 'Guest'),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false);
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label:
                  const Text('Log Out', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
