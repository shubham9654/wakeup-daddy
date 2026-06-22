import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../data/models/mission_config.dart';
import 'mission_scaffold.dart';

/// Take a photo of a specific object to prove you're out of bed.
///
/// On-device object verification (matching the photo to [photoLabel]) would use
/// an ML Kit image-labeling model; that hook is marked below. For now any
/// captured photo counts, which already forces the user up and moving.
class PhotoMission extends StatefulWidget {
  final MissionConfig config;
  final VoidCallback onComplete;
  const PhotoMission(
      {super.key, required this.config, required this.onComplete});

  @override
  State<PhotoMission> createState() => _PhotoMissionState();
}

class _PhotoMissionState extends State<PhotoMission> {
  final _picker = ImagePicker();
  File? _photo;
  bool _verifying = false;

  String get _target =>
      widget.config.photoLabel.isEmpty ? 'something across the room' : widget.config.photoLabel;

  Future<void> _capture() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 1280,
    );
    if (shot == null) return;
    setState(() {
      _photo = File(shot.path);
      _verifying = true;
    });

    // TODO(ml): run on-device ML Kit image labelling and compare to photoLabel.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _verifying = false);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return MissionScaffold(
      title: 'Photo proof',
      subtitle: 'Take a photo of: $_target',
      progress: _photo == null ? 0 : 1,
      child: Column(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              image: _photo != null
                  ? DecorationImage(
                      image: FileImage(_photo!), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: _photo == null
                ? const Icon(Icons.photo_camera_outlined,
                    size: 64, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(height: 24),
          if (_verifying)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _capture,
                icon: const Icon(Icons.camera_alt),
                label: Text(_photo == null ? 'Take photo' : 'Retake'),
              ),
            ),
        ],
      ),
    );
  }
}
