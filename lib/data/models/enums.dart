// Shared enums for the WakeDaddy domain model.

enum AlarmSoundType {
  uplift('Uplift', 'assets/audio/uplift.wav'),
  digital('Digital', 'assets/audio/digital.wav'),
  beep('Classic Beep', 'assets/audio/beep.wav'),
  pulse('Pulse', 'assets/audio/pulse.wav'),
  chime('Chime', 'assets/audio/chime.wav'),
  radar('Radar', 'assets/audio/radar.wav'),
  marimba('Marimba', 'assets/audio/marimba.wav'),
  siren('Siren', 'assets/audio/siren.wav'),
  cosmic('Cosmic', 'assets/audio/cosmic.wav'),
  bells('Bells', 'assets/audio/bells.wav');

  const AlarmSoundType(this.label, this.asset);
  final String label;
  final String asset;
}

/// Tasks the user must complete to switch the alarm off.
enum MissionType {
  none('No mission', 'Just tap to dismiss'),
  math('Math problems', 'Solve equations to wake your brain up'),
  typing('Type a sentence', 'Type a random sentence exactly'),
  memory('Memory game', 'Match the hidden pairs'),
  qrScan('Scan QR code', 'Scan a code placed in another room'),
  photo('Photo proof', 'Photograph a specific object'),
  steps('Walk it off', 'Take 100 steps to dismiss');

  const MissionType(this.label, this.description);
  final String label;
  final String description;
}

enum MissionDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const MissionDifficulty(this.label);
  final String label;
}
