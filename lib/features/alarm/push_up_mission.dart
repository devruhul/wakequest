import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PushUpMission extends StatefulWidget {
  const PushUpMission({
    super.key,
    required this.target,
    required this.onComplete,
  });

  final int target;
  final VoidCallback onComplete;

  @override
  State<PushUpMission> createState() => _PushUpMissionState();
}

class _PushUpMissionState extends State<PushUpMission>
    with WidgetsBindingObserver {
  final _detector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    ),
  );

  CameraController? _camera;
  bool _processing = false;
  bool _wasDown = false;
  bool _completed = false;
  int _count = 0;
  double? _elbowAngle;
  String _instruction = 'Setting up the camera…';
  String? _error;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_supported) _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await controller.startImageStream(_processFrame);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _instruction = 'Hold the top position, then lower your chest.';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Camera setup failed: $error';
          _instruction = 'The AI mission cannot start on this device.';
        });
      }
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_processing || _completed || image.planes.isEmpty) return;
    _processing = true;
    try {
      final camera = _camera;
      if (camera == null) return;
      final rotation = InputImageRotationValue.fromRawValue(
        camera.description.sensorOrientation,
      );
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (rotation == null || format == null) return;

      final input = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      final poses = await _detector.processImage(input);
      if (poses.isEmpty) {
        _updateInstruction('Step back until your upper body is visible.');
        return;
      }
      _evaluate(poses.first);
    } catch (_) {
      _updateInstruction('Keep your shoulders, elbows and wrists visible.');
    } finally {
      _processing = false;
    }
  }

  void _evaluate(Pose pose) {
    final left = _armAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final right = _armAngle(
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    final visibleAngles = [left, right].whereType<double>().toList();
    if (visibleAngles.isEmpty) {
      _updateInstruction('Turn side-on and keep one whole arm visible.');
      return;
    }
    final angle =
        visibleAngles.reduce((first, next) => first + next) /
        visibleAngles.length;

    if (angle < 95) {
      _wasDown = true;
      _update(angle, 'Good depth. Push back up.');
    } else if (angle > 155) {
      if (_wasDown) {
        _wasDown = false;
        _count++;
        if (_count >= widget.target) {
          _completed = true;
          widget.onComplete();
          return;
        }
      }
      _update(angle, 'Lower until your elbows bend past 90°.');
    } else {
      _update(angle, _wasDown ? 'Push through.' : 'Keep lowering.');
    }
  }

  double? _armAngle(
    Pose pose,
    PoseLandmarkType shoulderType,
    PoseLandmarkType elbowType,
    PoseLandmarkType wristType,
  ) {
    final shoulder = pose.landmarks[shoulderType];
    final elbow = pose.landmarks[elbowType];
    final wrist = pose.landmarks[wristType];
    if (shoulder == null || elbow == null || wrist == null) return null;
    if ([shoulder, elbow, wrist].any((point) => point.likelihood < .55)) {
      return null;
    }
    final first = atan2(shoulder.y - elbow.y, shoulder.x - elbow.x);
    final second = atan2(wrist.y - elbow.y, wrist.x - elbow.x);
    var degrees = (first - second).abs() * 180 / pi;
    if (degrees > 180) degrees = 360 - degrees;
    return degrees;
  }

  void _update(double angle, String instruction) {
    if (!mounted) return;
    setState(() {
      _elbowAngle = angle;
      _instruction = instruction;
    });
  }

  void _updateInstruction(String instruction) {
    if (mounted && _instruction != instruction) {
      setState(() => _instruction = instruction);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _camera?.stopImageStream();
    } else if (state == AppLifecycleState.resumed &&
        _camera?.value.isInitialized == true &&
        _camera?.value.isStreamingImages == false) {
      _camera?.startImageStream(_processFrame);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return const Center(
        child: Text('AI push-up detection is currently available on Android.'),
      );
    }
    final camera = _camera;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$_count / ${widget.target} push-ups',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (_elbowAngle != null) Text('${_elbowAngle!.round()}° elbow'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: camera == null || !camera.value.isInitialized
                ? Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: _error == null
                        ? const CircularProgressIndicator()
                        : const Icon(
                            Icons.no_photography_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                  )
                : CameraPreview(camera),
          ),
        ),
        const SizedBox(height: 12),
        Text(_instruction, textAlign: TextAlign.center),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Tooltip(
              message: 'Only use this if camera detection cannot operate.',
              child: OutlinedButton(
                onPressed: widget.onComplete,
                child: const Text('Emergency dismiss'),
              ),
            ),
          ),
      ],
    );
  }
}
