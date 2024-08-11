import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeleteAccountScreen extends StatefulWidget {
  @override
  _DeleteAccountScreenState createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool isAgreed = false;

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                // Delete the account logic
                try {
                  await FirebaseAuth.instance.currentUser?.delete();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } on FirebaseAuthException catch (e) {
                  // Handle error, show error message
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Delete Account', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0XFF2F004F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deleting your account will remove all your data from our system. '
              'This action is irreversible.',
              style: TextStyle(fontSize: 16),
            ),
            CheckboxListTile(
              title: const Text('I have read and agree to the terms.'),
              value: isAgreed,
              onChanged: (bool? value) {
                setState(() {
                  isAgreed = value!;
                });
              },
            ),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: isAgreed
                      ? const Color.fromARGB(255, 172, 17, 6)
                      : Colors.grey,
                ),
                onPressed: isAgreed ? _showDeleteConfirmation : null,
                child: const Text('Delete Account',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
