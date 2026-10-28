import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;
import '../theme/app_theme.dart';

void abrir(BuildContext context, Widget tela) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
void avisar(BuildContext context, String texto) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

String mensagemErro(Object erro) {
  if (erro is StateError) {
    return erro.message;
  }
  if (erro is ArgumentError) {
    return erro.message?.toString() ?? 'Confira os dados informados.';
  }
  if (erro is FormatException) {
    return erro.message;
  }
  return 'Confira a conexão e tente novamente.';
}

class Brand extends StatelessWidget {
  final double size;
  final bool wordmark;
  const Brand({super.key, this.size = 32, this.wordmark = true});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset('SVG/easygradesimbolo.svg',
            width: size,
            height: size,
            renderingStrategy: RenderingStrategy.raster,
            semanticsLabel: 'Ícone EasyGrade'),
        if (wordmark) ...[
          const SizedBox(width: 9),
          Text.rich(
              const TextSpan(children: [
                TextSpan(
                    text: 'easy', style: TextStyle(color: AppColors.primary)),
                TextSpan(
                    text: 'grade',
                    style: TextStyle(color: AppColors.primaryDark))
              ]),
              style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: size * .64,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1))
        ],
      ]);
}

class AppPage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool root;
  const AppPage(
      {super.key,
      required this.title,
      required this.child,
      this.actions,
      this.bottom,
      this.root = false});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: !root,
            title: root ? const Brand(size: 28) : Text(title),
            actions: actions == null
                ? null
                : [...actions!, const SizedBox(width: 12)]),
        body: SafeArea(top: false, child: child),
        bottomNavigationBar: bottom == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: bottom)),
      );
}

class PageHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  const PageHeading(
      {super.key, this.eyebrow = '', required this.title, this.subtitle = ''});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (eyebrow.isNotEmpty) ...[
          Eyebrow(eyebrow),
          const SizedBox(height: 8)
        ],
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)
        ],
      ]));
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = AppColors.primary});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: color));
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  const SurfaceCard(
      {super.key,
      required this.child,
      this.color = Colors.white,
      this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) => Material(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
              color: color == Colors.white
                  ? AppColors.border
                  : Colors.transparent)),
      child: Padding(padding: padding, child: child));
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeading(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (action != null)
          TextButton(
              onPressed: onAction,
              child: Text(action!, style: const TextStyle(fontSize: 12)))
      ]));
}

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool warning;
  const InfoBanner(this.text,
      {super.key,
      this.icon = Icons.info_outline_rounded,
      this.warning = false});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: warning ? AppColors.agendadaBg : AppColors.softPurple,
          borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon,
            size: 18,
            color: warning ? AppColors.agendadaFg : AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: warning
                        ? AppColors.agendadaFg
                        : AppColors.primaryDark)))
      ]));
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  final Color tint;
  const ActionTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.tint = AppColors.softPurple});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(13)),
                        child:
                            Icon(icon, color: AppColors.primaryDark, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(subtitle,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.5))
                        ])),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textMuted)
                  ])))));
}

class EmptyState extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  const EmptyState(
      {super.key,
      required this.title,
      required this.subtitle,
      this.icon = Icons.search_off_rounded,
      this.action});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(children: [
        Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
                color: AppColors.softPurple, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 32)),
        const SizedBox(height: 18),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!]
      ]));
}

class Metric extends StatelessWidget {
  final String value, label;
  final Color color;
  const Metric(this.value, this.label, {super.key, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Expanded(
      child: SurfaceCard(
          color: color,
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary))
          ])));
}

class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)));
}

class AnswerBubble extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback? onTap;
  final Color color;
  const AnswerBubble(
      {super.key,
      required this.index,
      this.selected = false,
      this.onTap,
      this.color = AppColors.primary});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Alternativa ${String.fromCharCode(65 + index)}',
      selected: selected,
      button: onTap != null,
      child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
              color: selected ? color : Colors.white,
              shape: CircleBorder(
                  side: BorderSide(color: selected ? color : AppColors.border)),
              child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                          child: Text(String.fromCharCode(65 + index),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary))))))));
}

Future<bool> confirmar(BuildContext context, String title, String text,
        {String action = 'Confirmar'}) async =>
    await showDialog<bool>(
        context: context,
        builder: (c) =>
            AlertDialog(title: Text(title), content: Text(text), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(c, true), child: Text(action))
            ])) ??
    false;
