package com.example.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.Cameraswitch
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.VideocamOff
import androidx.compose.material.icons.filled.VolumeDown
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.example.domain.model.CallSession
import com.example.domain.model.CallState
import com.example.domain.model.CallType
import com.example.ui.components.AudioWaveformVisualizer
import com.example.ui.components.CameraPreview
import com.example.ui.components.NexoraAvatar
import com.example.ui.components.PulsingCallEmblem
import com.example.ui.components.formatSecondsToTimer
import com.example.ui.theme.NexoraCallRed
import com.example.ui.theme.NexoraCyanAccent
import com.example.ui.theme.NexoraDarkBg
import com.example.ui.theme.NexoraDarkBorder
import com.example.ui.theme.NexoraDarkSurface
import com.example.ui.theme.NexoraDarkSurfaceCard
import com.example.ui.theme.NexoraEmeraldLight
import com.example.ui.theme.NexoraEmeraldPrimary
import com.example.ui.theme.NexoraTextMuted
import com.example.ui.theme.NexoraTextPrimary
import com.example.ui.theme.NexoraTextSecondary
import com.example.webrtc.WebRtcCallManager

@Composable
fun CallScreen(
    callSession: CallSession,
    callManager: WebRtcCallManager,
    onEndCall: () -> Unit,
    modifier: Modifier = Modifier
) {
    BackHandler {
        callManager.endCall()
        onEndCall()
    }

    val isMuted by callManager.isMuted.collectAsStateWithLifecycle()
    val isVideoEnabled by callManager.isVideoEnabled.collectAsStateWithLifecycle()
    val isSpeakerOn by callManager.isSpeakerOn.collectAsStateWithLifecycle()
    val isFrontCamera by callManager.isFrontCamera.collectAsStateWithLifecycle()
    val durationSeconds by callManager.callDurationSeconds.collectAsStateWithLifecycle()
    val stats by callManager.stats.collectAsStateWithLifecycle()
    val audioLevels by callManager.audioLevels.collectAsStateWithLifecycle()

    val isConnected = callSession.state == CallState.CONNECTED

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(NexoraDarkBg)
            .statusBarsPadding()
            .navigationBarsPadding()
            .testTag("call_screen")
    ) {
        if (callSession.callType == CallType.VIDEO && isConnected && isVideoEnabled) {
            // Fullscreen Remote Video Canvas simulation
            Box(modifier = Modifier.fillMaxSize()) {
                if (callSession.roomAvatar.isNotBlank()) {
                    AsyncImage(
                        model = callSession.roomAvatar,
                        contentDescription = "Remote video feed",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.verticalGradient(
                                    listOf(Color(0xFF0F172A), Color(0xFF020617))
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        NexoraAvatar(name = callSession.roomName, size = 120.dp)
                    }
                }

                // Dark vignette overlay
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                listOf(
                                    Color.Black.copy(alpha = 0.6f),
                                    Color.Transparent,
                                    Color.Black.copy(alpha = 0.85f)
                                )
                            )
                        )
                )

                // Picture-in-Picture Local CameraX Preview
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = NexoraDarkSurfaceCard,
                    border = androidx.compose.foundation.BorderStroke(2.dp, NexoraEmeraldPrimary),
                    modifier = Modifier
                        .size(width = 110.dp, height = 160.dp)
                        .align(Alignment.TopEnd)
                        .padding(top = 70.dp, end = 16.dp)
                        .clip(RoundedCornerShape(16.dp))
                ) {
                    CameraPreview(
                        isFrontCamera = isFrontCamera,
                        isEnabled = isVideoEnabled,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        } else {
            // Voice Call Mode / Connecting View
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                if (!isConnected) {
                    PulsingCallEmblem {
                        NexoraAvatar(
                            name = callSession.roomName,
                            avatarUrl = callSession.roomAvatar,
                            size = 110.dp
                        )
                    }
                } else {
                    NexoraAvatar(
                        name = callSession.roomName,
                        avatarUrl = callSession.roomAvatar,
                        size = 120.dp
                    )

                    Spacer(modifier = Modifier.height(28.dp))

                    // Audio sound wave spectrum
                    AudioWaveformVisualizer(
                        levels = audioLevels,
                        modifier = Modifier
                            .width(220.dp)
                            .height(40.dp)
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                Text(
                    text = callSession.roomName,
                    color = NexoraTextPrimary,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(6.dp))

                Text(
                    text = when (callSession.state) {
                        CallState.DIALING -> "Dialing WebRTC node..."
                        CallState.RINGING -> "Ringing..."
                        CallState.CONNECTED -> "Encrypted HD Voice (${formatSecondsToTimer(durationSeconds)})"
                        CallState.ENDED -> "Call Ended"
                        else -> "Connecting..."
                    },
                    color = if (isConnected) NexoraEmeraldLight else NexoraTextSecondary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        // Top Status Header (WebRTC Security & Stats Bar)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(NexoraDarkSurface.copy(alpha = 0.85f))
                .border(1.dp, NexoraDarkBorder, RoundedCornerShape(12.dp))
                .padding(horizontal = 14.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Security,
                    contentDescription = "Encrypted",
                    tint = NexoraEmeraldLight,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = if (isConnected) "P2P WebRTC Direct" else "Establishing SDP Offer...",
                    color = NexoraEmeraldLight,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            if (isConnected) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(Color(0x2206B6D4))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "HD 60FPS",
                            color = NexoraCyanAccent,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Spacer(modifier = Modifier.width(8.dp))

                    Text(
                        text = "${stats.pingMs}ms",
                        color = NexoraTextSecondary,
                        fontSize = 11.sp
                    )
                }
            }
        }

        // Bottom Controls Dock
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .padding(bottom = 32.dp, start = 20.dp, end = 20.dp)
                .clip(RoundedCornerShape(28.dp))
                .background(NexoraDarkSurface.copy(alpha = 0.95f))
                .border(1.dp, NexoraDarkBorder, RoundedCornerShape(28.dp))
                .padding(horizontal = 14.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Mute / Unmute
            IconButton(
                onClick = { callManager.toggleMute() },
                modifier = Modifier
                    .size(50.dp)
                    .clip(CircleShape)
                    .background(if (isMuted) Color(0x33EF4444) else NexoraDarkSurfaceCard)
            ) {
                Icon(
                    imageVector = if (isMuted) Icons.Default.MicOff else Icons.Default.Mic,
                    contentDescription = "Mute",
                    tint = if (isMuted) NexoraCallRed else NexoraTextPrimary,
                    modifier = Modifier.size(24.dp)
                )
            }

            // Video Toggle
            if (callSession.callType == CallType.VIDEO) {
                IconButton(
                    onClick = { callManager.toggleVideo() },
                    modifier = Modifier
                        .size(50.dp)
                        .clip(CircleShape)
                        .background(if (!isVideoEnabled) Color(0x33EF4444) else NexoraDarkSurfaceCard)
                ) {
                    Icon(
                        imageVector = if (isVideoEnabled) Icons.Default.Videocam else Icons.Default.VideocamOff,
                        contentDescription = "Toggle Video",
                        tint = if (isVideoEnabled) NexoraEmeraldLight else NexoraCallRed,
                        modifier = Modifier.size(24.dp)
                    )
                }

                // Switch Camera
                IconButton(
                    onClick = { callManager.switchCamera() },
                    modifier = Modifier
                        .size(50.dp)
                        .clip(CircleShape)
                        .background(NexoraDarkSurfaceCard)
                ) {
                    Icon(
                        imageVector = Icons.Default.Cameraswitch,
                        contentDescription = "Switch Camera",
                        tint = NexoraTextPrimary,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            // Speakerphone Toggle
            IconButton(
                onClick = { callManager.toggleSpeaker() },
                modifier = Modifier
                    .size(50.dp)
                    .clip(CircleShape)
                    .background(if (isSpeakerOn) Color(0x2210B981) else NexoraDarkSurfaceCard)
            ) {
                Icon(
                    imageVector = if (isSpeakerOn) Icons.Default.VolumeUp else Icons.Default.VolumeDown,
                    contentDescription = "Speaker",
                    tint = if (isSpeakerOn) NexoraEmeraldLight else NexoraTextSecondary,
                    modifier = Modifier.size(24.dp)
                )
            }

            // Hangup / End Call
            IconButton(
                onClick = {
                    callManager.endCall()
                    onEndCall()
                },
                modifier = Modifier
                    .size(54.dp)
                    .clip(CircleShape)
                    .background(NexoraCallRed)
                    .testTag("btn_end_call")
            ) {
                Icon(
                    imageVector = Icons.Default.CallEnd,
                    contentDescription = "End Call",
                    tint = Color.White,
                    modifier = Modifier.size(26.dp)
                )
            }
        }
    }
}
