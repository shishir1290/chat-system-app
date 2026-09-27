package com.example.webrtc

import android.content.Context
import com.example.data.repository.NexoraRepository
import com.example.domain.model.CallSession
import com.example.domain.model.CallState
import com.example.domain.model.CallType
import com.example.domain.model.ChatRoom
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.UUID
import kotlin.random.Random

data class WebRtcStats(
    val codec: String = "VP9 / OPUS",
    val resolution: String = "1080p HD",
    val fps: Int = 60,
    val pingMs: Int = 24,
    val packetLossPercent: Float = 0.02f,
    val bitrateKbps: Int = 2450
)

class WebRtcCallManager(
    private val context: Context,
    private val repository: NexoraRepository
) {
    private val scope = CoroutineScope(Dispatchers.Main)
    private var timerJob: Job? = null
    private var waveJob: Job? = null

    private val _activeCall = MutableStateFlow<CallSession?>(null)
    val activeCall = _activeCall.asStateFlow()

    private val _isMuted = MutableStateFlow(false)
    val isMuted = _isMuted.asStateFlow()

    private val _isVideoEnabled = MutableStateFlow(true)
    val isVideoEnabled = _isVideoEnabled.asStateFlow()

    private val _isSpeakerOn = MutableStateFlow(true)
    val isSpeakerOn = _isSpeakerOn.asStateFlow()

    private val _isFrontCamera = MutableStateFlow(true)
    val isFrontCamera = _isFrontCamera.asStateFlow()

    private val _callDurationSeconds = MutableStateFlow(0)
    val callDurationSeconds = _callDurationSeconds.asStateFlow()

    private val _stats = MutableStateFlow(WebRtcStats())
    val stats = _stats.asStateFlow()

    private val _audioLevels = MutableStateFlow(List(16) { 0.2f })
    val audioLevels = _audioLevels.asStateFlow()

    fun startCall(room: ChatRoom, callType: CallType) {
        val user = repository.currentUser.value
        val session = CallSession(
            id = "call_" + UUID.randomUUID().toString().take(8),
            roomId = room.id,
            roomName = room.name,
            roomAvatar = room.avatarUrl,
            callerId = user.id,
            callerName = user.name,
            callerAvatar = user.avatarUrl,
            receiverId = room.memberIds.firstOrNull { it != user.id } ?: "peer",
            callType = callType,
            state = CallState.DIALING,
            durationSeconds = 0,
            timestamp = System.currentTimeMillis()
        )

        _activeCall.value = session
        _callDurationSeconds.value = 0
        _isVideoEnabled.value = (callType == CallType.VIDEO)
        _isMuted.value = false

        // Simulate WebRTC connection establishment (Dialing -> Ringing -> Connected)
        scope.launch {
            delay(1200)
            if (_activeCall.value?.id == session.id) {
                _activeCall.value = session.copy(state = CallState.RINGING)
            }
            delay(1800)
            if (_activeCall.value?.id == session.id) {
                _activeCall.value = session.copy(state = CallState.CONNECTED)
                startTimerAndWaveforms()
            }
        }
    }

    private fun startTimerAndWaveforms() {
        timerJob?.cancel()
        timerJob = scope.launch {
            while (isActive) {
                delay(1000)
                _callDurationSeconds.value += 1

                // Simulate fluctuating network telemetry
                _stats.value = _stats.value.copy(
                    pingMs = Random.nextInt(18, 32),
                    bitrateKbps = Random.nextInt(2300, 2600),
                    fps = if (_isVideoEnabled.value) Random.nextInt(58, 61) else 0
                )
            }
        }

        waveJob?.cancel()
        waveJob = scope.launch {
            while (isActive) {
                delay(100)
                if (!_isMuted.value) {
                    _audioLevels.value = List(16) {
                        Random.nextFloat().coerceIn(0.15f, 0.95f)
                    }
                } else {
                    _audioLevels.value = List(16) { 0.05f }
                }
            }
        }
    }

    fun endCall() {
        val current = _activeCall.value ?: return
        val duration = _callDurationSeconds.value
        timerJob?.cancel()
        waveJob?.cancel()

        _activeCall.value = current.copy(state = CallState.ENDED, durationSeconds = duration)

        scope.launch(Dispatchers.IO) {
            repository.recordCall(current.copy(state = CallState.ENDED, durationSeconds = duration))
        }

        scope.launch {
            delay(600)
            _activeCall.value = null
            _callDurationSeconds.value = 0
        }
    }

    fun toggleMute() {
        _isMuted.value = !_isMuted.value
    }

    fun toggleVideo() {
        _isVideoEnabled.value = !_isVideoEnabled.value
    }

    fun switchCamera() {
        _isFrontCamera.value = !_isFrontCamera.value
    }

    fun toggleSpeaker() {
        _isSpeakerOn.value = !_isSpeakerOn.value
    }
}
