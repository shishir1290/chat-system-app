import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/constants.dart';

class WebRTCService {
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};

  bool _isAudioMuted = false;
  bool _isVideoOff = false;

  RTCVideoRenderer get localRenderer => _localRenderer;
  Map<String, RTCVideoRenderer> get remoteRenderers => _remoteRenderers;
  MediaStream? get localStream => _localStream;
  bool get isAudioMuted => _isAudioMuted;
  bool get isVideoOff => _isVideoOff;

  Future<void> initializeRenderers() async {
    await _localRenderer.initialize();
  }

  Future<MediaStream> openUserMedia(bool isVideo) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;
    _isVideoOff = !isVideo;
    _isAudioMuted = false;
    return _localStream!;
  }

  Future<RTCPeerConnection> createPeerConnectionInstance({
    required String peerId,
    required void Function(RTCIceCandidate candidate) onIceCandidate,
    required void Function(MediaStream stream) onAddStream,
    required void Function(RTCPeerConnectionState state) onConnectionState,
  }) async {
    if (_peerConnections.containsKey(peerId)) {
      return _peerConnections[peerId]!;
    }

    final pc = await createPeerConnection(AppConfig.iceConfiguration, {
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    });

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onIceCandidate(candidate);
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        _setupRemoteRenderer(peerId, stream);
        onAddStream(stream);
      }
    };

    pc.onConnectionState = (state) {
      onConnectionState(state);
    };

    _peerConnections[peerId] = pc;
    return pc;
  }

  Future<void> _setupRemoteRenderer(String peerId, MediaStream stream) async {
    if (!_remoteRenderers.containsKey(peerId)) {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = stream;
      _remoteRenderers[peerId] = renderer;
    } else {
      _remoteRenderers[peerId]!.srcObject = stream;
    }
  }

  Future<RTCSessionDescription> createOffer(String peerId) async {
    final pc = _peerConnections[peerId];
    if (pc == null) throw Exception('PeerConnection not found for $peerId');

    final offer = await pc.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
    await pc.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer(String peerId, dynamic remoteOffer) async {
    final pc = _peerConnections[peerId];
    if (pc == null) throw Exception('PeerConnection not found for $peerId');

    final sdp = remoteOffer is Map ? (remoteOffer['sdp']?.toString() ?? '') : remoteOffer.toString();
    final type = remoteOffer is Map ? (remoteOffer['type']?.toString() ?? 'offer') : 'offer';

    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
    final answer = await pc.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
    await pc.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteAnswer(String peerId, dynamic answerData) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    final sdp = answerData is Map ? (answerData['sdp']?.toString() ?? '') : answerData.toString();
    final type = answerData is Map ? (answerData['type']?.toString() ?? 'answer') : 'answer';

    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
  }

  Future<void> addIceCandidate(String peerId, dynamic candidateData) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    if (candidateData is Map) {
      final candidate = RTCIceCandidate(
        candidateData['candidate']?.toString(),
        candidateData['sdpMid']?.toString(),
        candidateData['sdpMLineIndex'] is int ? candidateData['sdpMLineIndex'] : int.tryParse(candidateData['sdpMLineIndex']?.toString() ?? '0') ?? 0,
      );
      await pc.addCandidate(candidate);
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

  void toggleVideo() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
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
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();

    for (final renderer in _remoteRenderers.values) {
      await renderer.dispose();
    }
    _remoteRenderers.clear();

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      await _localStream!.dispose();
      _localStream = null;
    }
    _localRenderer.srcObject = null;
    _isAudioMuted = false;
    _isVideoOff = false;
  }
}
