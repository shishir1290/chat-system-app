import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../theme/app_theme.dart';

class VoiceRecordBar extends StatefulWidget {
  final Function(File voiceFile) onSendVoice;
  final VoidCallback onCancel;

  const VoiceRecordBar({
    super.key,
    required this.onSendVoice,
    required this.onCancel,
  });

  @override
  State<VoiceRecordBar> createState() => _VoiceRecordBarState();
}

class _VoiceRecordBarState extends State<VoiceRecordBar> {
  late final AudioRecorder _audioRecorder;
  Timer? _timer;
  int _recordDuration = 0;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _filePath = path;

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _recordDuration = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDuration++;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting voice recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _stopAndSend() async {
    _timer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null && File(path).existsSync()) {
        widget.onSendVoice(File(path));
      } else if (_filePath != null && File(_filePath!).existsSync()) {
        widget.onSendVoice(File(_filePath!));
      } else {
        widget.onCancel();
      }
    } catch (e) {
      debugPrint('Error stopping voice recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    try {
      await _audioRecorder.stop();
      if (_filePath != null) {
        final f = File(_filePath!);
        if (f.existsSync()) f.deleteSync();
      }
    } catch (_) {}
    widget.onCancel();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            onPressed: _cancelRecording,
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(_recordDuration),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Recording voice message...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _stopAndSend,
            ),
          ),
        ],
      ),
    );
  }
}
