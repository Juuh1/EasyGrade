import 'package:flutter/material.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';

// Badge de status
class StatusBadge extends StatelessWidget {
  final StatusAvaliacao status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.fgColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
