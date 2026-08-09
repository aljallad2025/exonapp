import 'package:flutter/material.dart';
import '../config/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 46, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
