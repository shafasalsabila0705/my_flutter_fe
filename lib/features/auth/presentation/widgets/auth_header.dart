import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? version;

  const AuthHeader({
    super.key,
    this.title = 'Single Sign On',
    this.subtitle,
    this.version,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.asset(
          'assets/animations/logo_registerlogin.json',
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
        if (version != null)
          Text(
            version!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }
}
