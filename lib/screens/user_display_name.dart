import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDisplayName extends StatelessWidget {
  final String uid;
  final TextStyle? style;
  const UserDisplayName({super.key, required this.uid, this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Text(data['displayName'] ?? 'Unknown', style: style);
        }
        return Text('...', style: style);
      },
    );
  }
}
