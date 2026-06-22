import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// A collapsible group of settings. Keeps the editor visually calm — advanced
/// and premium options stay tucked away until the user opens them.
class CollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool premium;
  final bool initiallyExpanded;
  final List<Widget> children;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    this.premium = false,
    this.initiallyExpanded = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          leading: Icon(icon, color: AppColors.primary, size: 20),
          title: Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              if (premium) ...[
                const SizedBox(width: 8),
                const _ProBadge(),
              ],
            ],
          ),
          children: children,
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('PRO',
          style: TextStyle(
              color: AppColors.warning,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

/// A titled card used to group related settings in the alarm editor.
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool premium;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.premium = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                if (premium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PRO',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
