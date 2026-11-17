import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({
    super.key,
    required this.nome,
    required this.radius,
    required this.fontSize,
    this.fotoUrl,
  });

  final String nome;
  final double radius;
  final double fontSize;
  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    final url = Uri.tryParse(fotoUrl?.trim() ?? '');
    final temFoto = url != null && url.scheme == 'https' && url.host.isNotEmpty;
    final inicial = Text(
      nome.trim().characters.firstOrNull?.toUpperCase() ?? 'P',
      style: TextStyle(
        color: AppColors.primaryDark,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lavender,
      child: temFoto
          ? ClipOval(
              child: SizedBox.square(
                dimension: 2 * radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(child: inicial),
                    Image.network(
                      url.toString(),
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            )
          : inicial,
    );
  }
}
