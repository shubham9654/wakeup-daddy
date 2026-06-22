import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/enums.dart';
import '../../state/providers.dart';

/// Revenue model surface: Free / Premium monthly / Lifetime.
///
/// The "purchase" here flips local entitlement. Wire to RevenueCat or
/// Google Play / App Store billing before release — [_purchase] is the hook.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const _features = [
    'Penalty mode (donate if you oversleep)',
    'Accountability mode (notify a friend)',
    'Morning routine automation',
    'AI sleep coach insights & history',
    'Cloud backup & multi-device sync',
    'All premium alarm sounds',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('WakeDaddy Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text('Wake up like a boss',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Unlock every anti-oversleep weapon.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: .9))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(f)),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          _PlanCard(
            title: 'Monthly',
            price: '₹299',
            period: '/month',
            highlight: false,
            active: current == PlanTier.monthly,
            onTap: () => _purchase(context, ref, PlanTier.monthly),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Lifetime',
            price: '₹1,499',
            period: 'one-time',
            highlight: true,
            badge: 'BEST VALUE',
            active: current == PlanTier.lifetime,
            onTap: () => _purchase(context, ref, PlanTier.lifetime),
          ),
          const SizedBox(height: 20),
          if (current != PlanTier.free)
            Center(
              child: TextButton(
                onPressed: () =>
                    ref.read(premiumProvider.notifier).setTier(PlanTier.free),
                child: const Text('Switch back to Free (debug)'),
              ),
            ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Cancel anytime. Prices incl. taxes.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(
      BuildContext context, WidgetRef ref, PlanTier tier) async {
    // TODO: integrate in-app billing (Play Billing / StoreKit / RevenueCat).
    await ref.read(premiumProvider.notifier).setTier(tier);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tier.name} plan activated 🎉')),
      );
      Navigator.pop(context, true);
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final bool highlight;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.highlight,
    required this.active,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.success
                : highlight
                    ? AppColors.warning
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(price,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 4),
                      Text(period,
                          style: const TextStyle(
                              color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(active ? Icons.check_circle : Icons.arrow_forward_ios,
                color: active ? AppColors.success : AppColors.textMuted,
                size: active ? 28 : 18),
          ],
        ),
      ),
    );
  }
}
