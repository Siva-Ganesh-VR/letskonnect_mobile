import 'package:flutter/material.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.headset_mic_outlined, size: 20, color: Color(0xFF0D9488)),
        const SizedBox(width: 8),
        const Text(
          'Need help? ',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Contact Support',
            style: TextStyle(
              color: Color(0xFF0D9488),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0D9488)),
      ],
    );
  }
}
