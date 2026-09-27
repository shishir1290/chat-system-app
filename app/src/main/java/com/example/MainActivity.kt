package com.example

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.CloudQueue
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.ui.screens.CallScreen
import com.example.ui.screens.ChatScreen
import com.example.ui.screens.HomeScreen
import com.example.ui.theme.NexoraAwayAmber
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
import com.example.ui.theme.NexoraTheme
import com.example.ui.viewmodel.NexoraViewModel

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val app = application as NexoraApplication
        val viewModel: NexoraViewModel by viewModels {
            NexoraViewModel.Factory(
                repository = app.repository,
                callManager = app.callManager,
                firebaseManager = app.firebaseManager
            )
        }

        setContent {
            NexoraTheme {
                NexoraMainContent(viewModel = viewModel)
            }
        }
    }
}

@Composable
fun NexoraMainContent(viewModel: NexoraViewModel) {
    val activeCall by viewModel.callManager.activeCall.collectAsStateWithLifecycle()
    val activeRoom by viewModel.activeRoom.collectAsStateWithLifecycle()
    var showFirebaseModal by remember { mutableStateOf(false) }

    // Request Camera and Audio permissions for WebRTC calling
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { _ ->
        // Permissions handled gracefully
    }

    LaunchedEffect(Unit) {
        permissionLauncher.launch(
            arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.RECORD_AUDIO
            )
        )
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(NexoraDarkBg)
            .testTag("nexora_root_box")
    ) {
        AnimatedContent(
            targetState = when {
                activeCall != null -> "CALL"
                activeRoom != null -> "CHAT"
                else -> "HOME"
            },
            transitionSpec = { fadeIn() togetherWith fadeOut() },
            label = "screen_transition"
        ) { targetState ->
            when (targetState) {
                "CALL" -> {
                    activeCall?.let { session ->
                        CallScreen(
                            callSession = session,
                            callManager = viewModel.callManager,
                            onEndCall = { viewModel.callManager.endCall() }
                        )
                    }
                }
                "CHAT" -> {
                    activeRoom?.let { room ->
                        ChatScreen(
                            room = room,
                            viewModel = viewModel,
                            onBack = { viewModel.closeRoom() }
                        )
                    }
                }
                else -> {
                    HomeScreen(
                        viewModel = viewModel,
                        onOpenFirebaseInfo = { showFirebaseModal = true }
                    )
                }
            }
        }

        if (showFirebaseModal) {
            FirebaseInfoDialog(
                viewModel = viewModel,
                onDismiss = { showFirebaseModal = false }
            )
        }
    }
}

@Composable
fun FirebaseInfoDialog(
    viewModel: NexoraViewModel,
    onDismiss: () -> Unit
) {
    val isReady by viewModel.firebaseManager.isFirebaseReady.collectAsStateWithLifecycle()
    val status by viewModel.firebaseManager.syncStatus.collectAsStateWithLifecycle()

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = NexoraDarkSurface,
            border = androidx.compose.foundation.BorderStroke(1.dp, NexoraDarkBorder),
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp)
                .testTag("firebase_info_dialog")
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = if (isReady) Icons.Default.CloudDone else Icons.Default.CloudQueue,
                            contentDescription = null,
                            tint = if (isReady) NexoraEmeraldLight else NexoraAwayAmber,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Firebase Data Storage",
                            color = NexoraTextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp
                        )
                    }
                    IconButton(onClick = onDismiss, modifier = Modifier.size(30.dp)) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = NexoraTextSecondary)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(NexoraDarkSurfaceCard, RoundedCornerShape(10.dp))
                        .padding(12.dp)
                ) {
                    Column {
                        Text(
                            text = "Status: $status",
                            color = if (isReady) NexoraEmeraldLight else NexoraAwayAmber,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Storage: Offline-First Hybrid (Room SQLite + Firebase Firestore)",
                            color = NexoraTextSecondary,
                            fontSize = 11.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Text(
                    text = "Modular Architecture Breakdown:",
                    color = NexoraTextPrimary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp
                )

                Spacer(modifier = Modifier.height(6.dp))

                val archSteps = listOf(
                    "1. UI Layer (Jetpack Compose M3, declarative & reactive)",
                    "2. Presentation Layer (ViewModel + StateFlow)",
                    "3. Repository Pattern (NexoraRepository orchestrator)",
                    "4. Local Layer (Room DB with Entities, DAOs, SQLite)",
                    "5. Remote Layer (Firebase Firestore with real-time listeners)",
                    "6. Media Engine (WebRTC HD video/audio & CameraX preview)"
                )

                archSteps.forEach { step ->
                    Text(
                        text = "• $step",
                        color = NexoraTextSecondary,
                        fontSize = 11.sp,
                        lineHeight = 16.sp,
                        modifier = Modifier.padding(vertical = 2.dp)
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = onDismiss,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = NexoraEmeraldPrimary,
                        contentColor = NexoraDarkBg
                    ),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Got It", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
