import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../morning/morning_screen.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';
import '../sleep/sleep_screen.dart';

/// Top-level shell: 5 bottom tabs (Alarm/Sleep/Morning/Report/Setting).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );

  static const _tabs = [
    _TabSpec('Alarm', Icons.access_alarm),
    _TabSpec('Sleep', Icons.nightlight_round),
    _TabSpec('Morning', Icons.wb_sunny_outlined),
    _TabSpec('Report', Icons.description_outlined),
    _TabSpec('Setting', Icons.settings_outlined),
  ];

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _fade.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: Tween<double>(begin: .35, end: 1).animate(
            CurvedAnimation(parent: _fade, curve: Curves.easeOut)),
        child: IndexedStack(
          index: _index,
          children: const [
            AlarmTab(),
            SleepScreen(),
            MorningScreen(),
            ReportScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        tabs: _tabs,
        onTap: _select,
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  const _TabSpec(this.label, this.icon);
}

class _BottomNav extends StatelessWidget {
  final int index;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onTap;
  const _BottomNav({
    required this.index,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(12),
                child: _NavItem(
                  spec: tabs[i],
                  selected: i == index,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  const _NavItem({required this.spec, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: selected ? 1.12 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(color: color),
            child: Icon(spec.icon, size: 24, color: color),
          ),
        ),
        const SizedBox(height: 3),
        Text(spec.label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color)),
      ],
    );
  }
}
