import 'package:flutter/material.dart';

/// A selectable alarm wallpaper. Either an animated GIF asset (rendered on the
/// ring screen) or a plain gradient. All assets are original & royalty-free.
class Wallpaper {
  final String name;

  /// Gradient shown for plain wallpapers and as a placeholder behind a GIF.
  final List<Color> colors;

  /// Optional animated GIF asset path. Flutter's [Image.asset] plays it.
  final String? gif;

  const Wallpaper(this.name, this.colors, {this.gif});

  bool get isAnimated => gif != null;

  LinearGradient get gradient => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Foreground (clock) colour with enough contrast. GIFs are dark → white.
  Color get onColor {
    if (gif != null) return Colors.white;
    final luminance =
        colors.map((c) => c.computeLuminance()).reduce((a, b) => a + b) /
            colors.length;
    return luminance > .5 ? Colors.black : Colors.white;
  }
}

/// The wallpaper gallery. Index 0 is the default (plain). The order is stable
/// because alarms persist the chosen index.
class Wallpapers {
  static const all = <Wallpaper>[
    // Index 0 is the default for new alarms — Rings.
    Wallpaper('Rings', [Color(0xFF0C0810), Color(0xFFFB4E63)],
        gif: 'assets/wallpapers/w_rings.gif'),
    Wallpaper('Midnight', [Color(0xFF1A1A1E), Color(0xFF000000)]),
    Wallpaper('Aurora', [Color(0xFF2A0A1A), Color(0xFFFB4E63)],
        gif: 'assets/wallpapers/w_aurora.gif'),
    Wallpaper('Embers', [Color(0xFF1A0404), Color(0xFFFF8A3C)],
        gif: 'assets/wallpapers/w_embers.gif'),
    Wallpaper('Plasma', [Color(0xFF1E0023), Color(0xFFFB4E63)],
        gif: 'assets/wallpapers/w_plasma.gif'),
    Wallpaper('Starfield', [Color(0xFF04040A), Color(0xFF20203A)],
        gif: 'assets/wallpapers/w_starfield.gif'),
    Wallpaper('Streaks', [Color(0xFF0A0406), Color(0xFFFB7850)],
        gif: 'assets/wallpapers/w_streaks.gif'),
    Wallpaper('Waves', [Color(0xFF0C040A), Color(0xFFFB4E63)],
        gif: 'assets/wallpapers/w_waves.gif'),
    Wallpaper('Bokeh', [Color(0xFF140810), Color(0xFFC85AA0)],
        gif: 'assets/wallpapers/w_bokeh.gif'),
    Wallpaper('Sunrise', [Color(0xFF120818), Color(0xFFFF9646)],
        gif: 'assets/wallpapers/w_sunrise.gif'),
    Wallpaper('Nebula', [Color(0xFF08040E), Color(0xFFEC4899)],
        gif: 'assets/wallpapers/w_nebula.gif'),
  ];

  static Wallpaper byIndex(int i) =>
      (i >= 0 && i < all.length) ? all[i] : all.first;
}

/// Renders a wallpaper as a fill: the animated GIF if present, else its
/// gradient. The gradient always sits underneath so there's no flash while the
/// GIF decodes. Wrap in a ClipRRect for rounded corners.
class WallpaperView extends StatelessWidget {
  final Wallpaper wallpaper;
  final BoxFit fit;
  const WallpaperView(this.wallpaper, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: wallpaper.gradient)),
        if (wallpaper.gif != null)
          Image.asset(
            wallpaper.gif!,
            fit: fit,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
          ),
      ],
    );
  }
}
