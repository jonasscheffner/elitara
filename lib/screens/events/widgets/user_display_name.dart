import 'package:flutter/material.dart';
import 'package:elitara/services/user_service.dart';

class UserDisplayName extends StatelessWidget {
  final String uid;
  final TextStyle? style;
  const UserDisplayName({super.key, required this.uid, this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: UserService().streamUser(uid),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          return Text(data['displayName'] ?? 'Unknown', style: style);
        }
        return Text('...', style: style);
      },
    );
  }
}
