import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DarkCard extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Widget? header;

  const DarkCard({
    super.key,
    required this.children,
    this.padding,
    this.borderColor,
    this.onTap,
    this.header,
  });

  @override
  State<DarkCard> createState() => _DarkCardState();
}

class _DarkCardState extends State<DarkCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inner top highlight
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.transparent,
            ]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        if (widget.header != null) ...[
          Padding(
            padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: widget.header,
          ),
          const Divider(height: 1),
        ],
        ...widget.children.asMap().entries.map((e) => Column(
          children: [
            Padding(
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: e.value,
            ),
            if (e.key < widget.children.length - 1) const Divider(height: 1),
          ],
        )),
      ],
    );

    final decorated = Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor ?? AppTheme.border, width: 0.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: widget.onTap != null
          ? InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: content,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: content,
            ),
    );

    if (widget.onTap == null) return decorated;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (_pressed && !disableAnimations) ? 0.97 : 1.0,
        duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 120),
        curve: Curves.easeOutExpo,
        child: decorated,
      ),
    );
  }
}
