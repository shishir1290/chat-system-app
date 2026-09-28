import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/constants.dart';

class WebRTCService {
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, List<RTCIceCandidate>> _candidateQueues = {};

  bool _isAudioMuted = false;
  bool _isVideoOff = false;

  Map<String, RTCPeerConnection> get peerConnections => _peerConnections;
  RTCVideoRenderer get localRenderer => _localRenderer;
  Map<String, RTCVideoRenderer> get remoteRenderers => _remoteRenderers;
  MediaStream? get localStream => _localStream;
  bool get isAudioMuted => _isAudioMuted;
  bool get isVideoOff => _isVideoOff;

  Future<void> initializeRenderers() async {
    try {
      await _localRenderer.initialize();
    } catch (e) {
      debugPrint('Error initializing local renderer: $e');
    }
  }

  Future<MediaStream?> openUserMedia(bool isVideo) async {
    try {
      await [
        Permission.microphone,
        if (isVideo) Permission.camera,
      ].request();
    } catch (_) {}

    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
                'frameRate': {'ideal': 30},
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      _isVideoOff = !isVideo;
      _isAudioMuted = false;

      // Attach tracks to all existing peer connections
      for (final pc in _peerConnections.values) {
        try {
          final senders = await pc.getSenders();
          for (final track in _localStream!.getTracks()) {
            if (!senders.any((s) => s.track?.id == track.id)) {
              await pc.addTrack(track, _localStream!);
            }
          }
        } catch (e) {
          debugPrint('Error attaching track to existing PC: $e');
        }
      }
      return _localStream;
    } catch (e) {
      debugPrint('Error getting user media: $e');
      if (isVideo) {
        try {
          _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
          _localRenderer.srcObject = _localStream;
          _isVideoOff = true;
          _isAudioMuted = false;
          return _localStream;
        } catch (_) {}
      }
      return null;
    }
  }

  Future<RTCPeerConnection> createPeerConnectionInstance({
    required String peerId,
    required void Function(RTCIceCandidate candidate) onIceCandidate,
    required void Function(MediaStream stream) onAddStream,
    required void Function(RTCPeerConnectionState state) onConnectionState,
  }) async {
    if (_peerConnections.containsKey(peerId)) {
      final existingPc = _peerConnections[peerId]!;
      if (_localStream != null) {
        try {
          final senders = await existingPc.getSenders();
          for (final track in _localStream!.getTracks()) {
            if (!senders.any((s) => s.track?.id == track.id)) {
              await existingPc.addTrack(track, _localStream!);
            }
          }
        } catch (_) {}
      }
      return existingPc;
    }

    final pc = await createPeerConnection(AppConfig.iceConfiguration, {
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    });

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        pc.addTrack(track, _localStream!);
      }
    }

    MediaStream? peerRemoteStream;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        onIceCandidate(candidate);
      }
    };

    pc.onTrack = (event) async {
      MediaStream stream;
      if (event.streams.isNotEmpty) {
        stream = event.streams[0];
        peerRemoteStream = stream;
      } else {
        peerRemoteStream ??= await createLocalMediaStream('remote_stream_$peerId');
        peerRemoteStream!.addTrack(event.track);
        stream = peerRemoteStream!;
      }
      await _setupRemoteRenderer(peerId, stream);
      onAddStream(stream);
    };

    pc.onAddStream = (stream) async {
      peerRemoteStream = stream;
      await _setupRemoteRenderer(peerId, stream);
      onAddStream(stream);
    };

    pc.onConnectionState = (state) {
      onConnectionState(state);
    };

    _peerConnections[peerId] = pc;
    return pc;
  }

  Future<void> _setupRemoteRenderer(String peerId, MediaStream stream) async {
    try {
      if (!_remoteRenderers.containsKey(peerId)) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = stream;
        _remoteRenderers[peerId] = renderer;
      } else {
        _remoteRenderers[peerId]!.srcObject = stream;
      }
    } catch (e) {
      debugPrint('Error setting up remote renderer: $e');
    }
  }

  Future<RTCSessionDescription> createOffer(String peerId) async {
    final pc = _peerConnections[peerId] ?? (_peerConnections.isNotEmpty ? _peerConnections.values.first : null);
    if (pc == null) throw Exception('PeerConnection not found for $peerId');

    final offer = await pc.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
    await pc.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription?> createAnswer(String peerId, dynamic remoteOffer) async {
    final pc = _peerConnections[peerId] ?? (_peerConnections.isNotEmpty ? _peerConnections.values.first : null);
    if (pc == null) {
      debugPrint('createAnswer: no PC for $peerId');
      return null;
    }

    if (remoteOffer != null) {
      if (remoteOffer is String && remoteOffer.trim().startsWith('{')) {
        try {
          remoteOffer = jsonDecode(remoteOffer);
        } catch (_) {}
      }

      String sdp = '';
      String type = 'offer';

      if (remoteOffer is Map) {
        final inner = remoteOffer['offer'] ?? remoteOffer['signal'] ?? remoteOffer['signalData'] ?? remoteOffer;
        Map innerMap = inner is Map ? inner : remoteOffer;
        if (inner is String && inner.trim().startsWith('{')) {
          try {
            innerMap = jsonDecode(inner);
          } catch (_) {}
        }
        sdp = innerMap['sdp']?.toString() ?? (inner is String ? inner : '');
        type = innerMap['type']?.toString() ?? 'offer';
      } else if (remoteOffer is RTCSessionDescription) {
        sdp = remoteOffer.sdp ?? '';
        type = remoteOffer.type ?? 'offer';
      } else {
        sdp = remoteOffer.toString();
      }

      if (sdp.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(sdp);
          if (decoded is Map) {
            sdp = decoded['sdp']?.toString() ?? sdp;
            type = decoded['type']?.toString() ?? type;
          }
        } catch (_) {}
      }

      debugPrint('createAnswer: sdp length=${sdp.length}, type=$type for peer $peerId');

      if (sdp.isNotEmpty && sdp != 'null' && sdp != '<nil>') {
        try {
          await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
          await processQueuedCandidates(peerId);
          debugPrint('✅ Remote offer set successfully for $peerId');
        } catch (e) {
          debugPrint('Warning setting remote description in createAnswer: $e');
        }
      } else {
        debugPrint('⚠️ createAnswer: empty SDP from offer');
      }
    } else {
      debugPrint('⚠️ createAnswer: remoteOffer is null');
    }

    try {
      final sigState = await pc.getSignalingState();
      if (sigState != RTCSignalingState.RTCSignalingStateHaveRemoteOffer) {
        debugPrint('createAnswer skipped: signaling state is $sigState (requires haveRemoteOffer)');
        return null;
      }

      final answer = await pc.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      await pc.setLocalDescription(answer);
      debugPrint('✅ Answer created and local description set for $peerId');
      return answer;
    } catch (e) {
      debugPrint('Error in createAnswer/setLocalDescription: $e');
      return null;
    }
  }

  Future<void> setRemoteAnswer(String peerId, dynamic answerData) async {
    final pc = _peerConnections[peerId] ?? (_peerConnections.isNotEmpty ? _peerConnections.values.first : null);
    if (pc == null || answerData == null) {
      debugPrint('setRemoteAnswer: pc=${pc != null}, answerData=${answerData != null} — skipping');
      return;
    }

    if (answerData is String && answerData.trim().startsWith('{')) {
      try {
        answerData = jsonDecode(answerData);
      } catch (_) {}
    }

    String sdp = '';
    String type = 'answer';
    if (answerData is Map) {
      final inner = answerData['answer'] ?? answerData['signal'] ?? answerData['signalData'] ?? answerData;
      Map innerMap = inner is Map ? inner : answerData;
      if (inner is String && inner.trim().startsWith('{')) {
        try {
          innerMap = jsonDecode(inner);
        } catch (_) {}
      }
      sdp = innerMap['sdp']?.toString() ?? (inner is String ? inner : '');
      type = innerMap['type']?.toString() ?? 'answer';
    } else if (answerData is RTCSessionDescription) {
      sdp = answerData.sdp ?? '';
      type = answerData.type ?? 'answer';
    } else {
      sdp = answerData.toString();
    }

    if (sdp.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(sdp);
        if (decoded is Map) {
          sdp = decoded['sdp']?.toString() ?? sdp;
          type = decoded['type']?.toString() ?? type;
        }
      } catch (_) {}
    }

    if (sdp.isNotEmpty && sdp != 'null' && sdp != '<nil>') {
      try {
        final sigState = await pc.getSignalingState();
        debugPrint('setRemoteAnswer: sigState=$sigState, type=$type for peer $peerId');
        // Allow setting remote description in HaveLocalOffer (normal answer flow)
        // and also in Stable (renegotiation) and HaveRemoteOffer
        if (sigState == RTCSignalingState.RTCSignalingStateHaveLocalOffer ||
            sigState == RTCSignalingState.RTCSignalingStateHaveRemoteOffer ||
            sigState == RTCSignalingState.RTCSignalingStateStable) {
          await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
          await processQueuedCandidates(peerId);
          debugPrint('✅ Remote description ($type) set successfully for $peerId');
        } else {
          debugPrint('⚠️ setRemoteAnswer skipped: sigState=$sigState');
        }
      } catch (e) {
        debugPrint('Warning setting remote answer: $e');
        // Retry once — sometimes the state transitions during async
        try {
          await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
          await processQueuedCandidates(peerId);
          debugPrint('✅ Remote description ($type) set on retry for $peerId');
        } catch (retryE) {
          debugPrint('❌ Retry also failed: $retryE');
        }
      }
    } else {
      debugPrint('⚠️ setRemoteAnswer: empty/null SDP — skipping');
    }
  }

  Future<void> addIceCandidate(String peerId, dynamic candidateData) async {
    final pc = _peerConnections[peerId] ?? (_peerConnections.isNotEmpty ? _peerConnections.values.first : null);
    if (pc == null || candidateData == null) return;

    try {
      if (candidateData is String && candidateData.trim().startsWith('{')) {
        try {
          candidateData = jsonDecode(candidateData);
        } catch (_) {}
      }

      if (candidateData is Map) {
        dynamic innerCandidate = candidateData['candidate'] ?? candidateData;
        if (innerCandidate is String && innerCandidate.trim().startsWith('{')) {
          try {
            innerCandidate = jsonDecode(innerCandidate);
          } catch (_) {}
        }

        String candStr = '';
        String sdpMid = candidateData['sdpMid']?.toString() ?? '';
        int sdpMLineIndex = 0;

        if (innerCandidate is Map) {
          candStr = innerCandidate['candidate']?.toString() ?? '';
          sdpMid = innerCandidate['sdpMid']?.toString() ?? sdpMid;
          sdpMLineIndex = innerCandidate['sdpMLineIndex'] is int
              ? innerCandidate['sdpMLineIndex']
              : int.tryParse(innerCandidate['sdpMLineIndex']?.toString() ?? '0') ?? 0;
        } else if (innerCandidate is String) {
          candStr = innerCandidate;
          sdpMLineIndex = candidateData['sdpMLineIndex'] is int
              ? candidateData['sdpMLineIndex']
              : int.tryParse(candidateData['sdpMLineIndex']?.toString() ?? '0') ?? 0;
        }

        if (candStr.isNotEmpty) {
          final cand = RTCIceCandidate(candStr, sdpMid, sdpMLineIndex);
          final remoteDesc = await pc.getRemoteDescription();
          if (remoteDesc != null) {
            await pc.addCandidate(cand);
          } else {
            _candidateQueues.putIfAbsent(peerId, () => []).add(cand);
          }
        }
      }
    } catch (e) {
      debugPrint('Error adding ICE candidate: $e');
    }
  }

  Future<void> processQueuedCandidates(String peerId) async {
    final pc = _peerConnections[peerId];
    final queue = _candidateQueues[peerId];
    if (pc != null && queue != null && queue.isNotEmpty) {
      final list = List<RTCIceCandidate>.from(queue);
      _candidateQueues.remove(peerId);
      for (final cand in list) {
        try {
          await pc.addCandidate(cand);
        } catch (e) {
          debugPrint('Error processing queued ICE candidate: $e');
        }
      }
    }
  }

  void toggleAudio() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final enabled = audioTracks[0].enabled;
        audioTracks[0].enabled = !enabled;
        _isAudioMuted = !audioTracks[0].enabled;
      }
    }
  }

  Future<void> toggleVideo() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isEmpty) {
        // Audio-only call dynamically activating camera
        try {
          await Permission.camera.request();
          final videoStream = await navigator.mediaDevices.getUserMedia({
            'audio': false,
            'video': {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
              'frameRate': {'ideal': 30},
            },
          });
          if (videoStream.getVideoTracks().isNotEmpty) {
            final newTrack = videoStream.getVideoTracks().first;
            await _localStream!.addTrack(newTrack);
            _localRenderer.srcObject = _localStream;
            _isVideoOff = false;

            // Attach new video track to all active peer connections
            for (final pc in _peerConnections.values) {
              try {
                final senders = await pc.getSenders();
                if (!senders.any((s) => s.track?.id == newTrack.id)) {
                  await pc.addTrack(newTrack, _localStream!);
                }
              } catch (e) {
                debugPrint('Error adding video track to PC: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('Error enabling camera in audio call: $e');
        }
      } else {
        final enabled = videoTracks[0].enabled;
        videoTracks[0].enabled = !enabled;
        _isVideoOff = !videoTracks[0].enabled;
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
      }
    }
  }

  Future<void> closePeer(String peerId) async {
    _candidateQueues.remove(peerId);
    if (_peerConnections.containsKey(peerId)) {
      await _peerConnections[peerId]?.close();
      _peerConnections.remove(peerId);
    }
    if (_remoteRenderers.containsKey(peerId)) {
      await _remoteRenderers[peerId]?.dispose();
      _remoteRenderers.remove(peerId);
    }
  }

  Future<void> cleanUp() async {
    _candidateQueues.clear();
    final pcs = _peerConnections.values.toList();
    _peerConnections.clear();
    for (final pc in pcs) {
      try {
        await pc.close();
      } catch (_) {}
    }

    final renderers = _remoteRenderers.values.toList();
    _remoteRenderers.clear();
    for (final renderer in renderers) {
      try {
        await renderer.dispose();
      } catch (_) {}
    }

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }
    _localRenderer.srcObject = null;
    _isAudioMuted = false;
    _isVideoOff = false;
  }
}
