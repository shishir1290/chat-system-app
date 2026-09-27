package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.CloudQueue
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Storage
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.domain.model.UserStatus
import com.example.ui.components.NexoraAvatar
import com.example.ui.components.formatChatTime
import com.example.ui.theme.NexoraAwayAmber
import com.example.ui.theme.NexoraCyanAccent
import com.example.ui.theme.NexoraDarkBg
import com.example.ui.theme.NexoraDarkBorder
import com.example.ui.theme.NexoraDarkSurface
import com.example.ui.theme.NexoraDarkSurfaceCard
import com.example.ui.theme.NexoraEmeraldLight
import com.example.ui.theme.NexoraEmeraldPrimary
import com.example.ui.theme.NexoraOnlineGreen
import com.example.ui.theme.NexoraTextMuted
import com.example.ui.theme.NexoraTextPrimary
import com.example.ui.theme.NexoraTextSecondary
import com.example.ui.viewmodel.NexoraViewModel

@Composable
fun ProfileSettingsScreen(
    viewModel: NexoraViewModel,
    onOpenFirebaseDocs: () -> Unit,
    modifier: Modifier = Modifier
) {
    val currentUser by viewModel.currentUser.collectAsStateWithLifecycle()
    val isFirebaseReady by viewModel.firebaseManager.isFirebaseReady.collectAsStateWithLifecycle()
    val syncStatus by viewModel.firebaseManager.syncStatus.collectAsStateWithLifecycle()
    val lastSyncedAt by viewModel.firebaseManager.lastSyncedAt.collectAsStateWithLifecycle()

    var isEditingName by remember { mutableStateOf(false) }
    var editedName by remember(currentUser.name) { mutableStateOf(currentUser.name) }
    var editedStatusMsg by remember(currentUser.statusMessage) { mutableStateOf(currentUser.statusMessage) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
            .testTag("profile_settings_screen")
    ) {
        // User Profile Card
        Surface(
            shape = RoundedCornerShape(16.dp),
            color = NexoraDarkSurface,
            border = androidx.compose.foundation.BorderStroke(1.dp, NexoraDarkBorder),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                NexoraAvatar(
                    name = currentUser.name,
                    avatarUrl = currentUser.avatarUrl,
                    size = 80.dp,
                    status = currentUser.status
                )

                Spacer(modifier = Modifier.height(14.dp))

                if (isEditingName) {
                    OutlinedTextField(
                        value = editedName,
                        onValueChange = { editedName = it },
                        label = { Text("Your Name", color = NexoraTextSecondary) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedContainerColor = NexoraDarkSurfaceCard,
                            unfocusedContainerColor = NexoraDarkSurfaceCard,
                            focusedBorderColor = NexoraEmeraldPrimary,
                            unfocusedBorderColor = NexoraDarkBorder,
                            focusedTextColor = NexoraTextPrimary,
                            unfocusedTextColor = NexoraTextPrimary
                        ),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedTextField(
                        value = editedStatusMsg,
                        onValueChange = { editedStatusMsg = it },
                        label = { Text("Status Message", color = NexoraTextSecondary) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedContainerColor = NexoraDarkSurfaceCard,
                            unfocusedContainerColor = NexoraDarkSurfaceCard,
                            focusedBorderColor = NexoraEmeraldPrimary,
                            unfocusedBorderColor = NexoraDarkBorder,
                            focusedTextColor = NexoraTextPrimary,
                            unfocusedTextColor = NexoraTextPrimary
                        ),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Button(
                        onClick = {
                            viewModel.updateProfile(editedName, currentUser.handle, editedStatusMsg)
                            isEditingName = false
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = NexoraEmeraldPrimary,
                            contentColor = NexoraDarkBg
                        ),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Text("Save Profile", fontWeight = FontWeight.Bold)
                    }
                } else {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = currentUser.name,
                            color = NexoraTextPrimary,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold
                        )
                        IconButton(onClick = { isEditingName = true }, modifier = Modifier.size(28.dp)) {
                            Icon(Icons.Default.Edit, contentDescription = "Edit", tint = NexoraTextSecondary, modifier = Modifier.size(16.dp))
                        }
                    }

                    Text(
                        text = currentUser.handle,
                        color = NexoraEmeraldLight,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = "“${currentUser.statusMessage}”",
                        color = NexoraTextSecondary,
                        fontSize = 13.sp
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Presence Selector
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(NexoraDarkSurfaceCard)
                        .padding(4.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    UserStatus.values().forEach { st ->
                        val isSelected = currentUser.status == st
                        val dotColor = when (st) {
                            UserStatus.ONLINE -> NexoraOnlineGreen
                            UserStatus.AWAY -> NexoraAwayAmber
                            UserStatus.BUSY -> Color(0xFFEF4444)
                            UserStatus.OFFLINE -> Color(0xFF64748B)
                        }

                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(if (isSelected) Color(0x3310B981) else Color.Transparent)
                                .clickable { viewModel.updateUserStatus(st) }
                                .padding(horizontal = 8.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .background(dotColor, CircleShape)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = st.label,
                                color = if (isSelected) NexoraEmeraldLight else NexoraTextSecondary,
                                fontSize = 11.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Modular Architecture & Firebase Educational Section
        Text(
            text = "STORAGE & ARCHITECTURE PATTERN",
            color = NexoraTextMuted,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(start = 4.dp, bottom = 8.dp)
        )

        Surface(
            shape = RoundedCornerShape(16.dp),
            color = NexoraDarkSurface,
            border = androidx.compose.foundation.BorderStroke(1.dp, NexoraDarkBorder),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = if (isFirebaseReady) Icons.Default.CloudDone else Icons.Default.CloudQueue,
                            contentDescription = null,
                            tint = if (isFirebaseReady) NexoraEmeraldLight else NexoraAwayAmber,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = "Firebase Firestore Sync",
                                color = NexoraTextPrimary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp
                            )
                            Text(
                                text = syncStatus,
                                color = NexoraTextSecondary,
                                fontSize = 11.sp
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Educational Blueprint Points
                ArchitectureBadge(
                    layer = "UI Layer",
                    detail = "Jetpack Compose M3 (Declarative, Reactive UI)"
                )
                ArchitectureBadge(
                    layer = "State Management",
                    detail = "ViewModel + Kotlin StateFlow / SharingStarted"
                )
                ArchitectureBadge(
                    layer = "Local Persistence",
                    detail = "Room SQLite Database (Offline-first cache with DAOs)"
                )
                ArchitectureBadge(
                    layer = "Remote Storage",
                    detail = "Firebase Firestore (Real-time snapshot listeners)"
                )
                ArchitectureBadge(
                    layer = "Media Calling",
                    detail = "WebRTC HD Calling Engine + CameraX Local Preview"
                )

                if (lastSyncedAt != null) {
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = "Last remote sync: ${formatChatTime(lastSyncedAt!!)}",
                        color = NexoraEmeraldLight,
                        fontSize = 11.sp
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Firebase configuration guide
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(NexoraDarkSurfaceCard)
                        .padding(12.dp)
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Info, contentDescription = null, tint = NexoraCyanAccent, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("How Firebase Works in this Clone", color = NexoraCyanAccent, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Nexora implements an offline-first modular repository. All messages, rooms, and call logs are written locally to Room and synced to Firestore collections ('users', 'chat_rooms', 'messages', 'call_sessions'). When google-services.json is added to /app, cloud sync activates automatically.",
                            color = NexoraTextSecondary,
                            fontSize = 11.sp,
                            lineHeight = 16.sp
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Security & Account
        Text(
            text = "SECURITY & PEER INTEGRITY",
            color = NexoraTextMuted,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(start = 4.dp, bottom = 8.dp)
        )

        Surface(
            shape = RoundedCornerShape(16.dp),
            color = NexoraDarkSurface,
            border = androidx.compose.foundation.BorderStroke(1.dp, NexoraDarkBorder),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                SettingRowItem(
                    icon = Icons.Default.Security,
                    title = "End-to-End Encryption",
                    subtitle = "WebRTC DTLS-SRTP & local SQLite protection enabled",
                    actionLabel = "Active"
                )

                Spacer(modifier = Modifier.height(12.dp))

                SettingRowItem(
                    icon = Icons.Default.Code,
                    title = "Nexora Clone Target",
                    subtitle = "Cloned from: https://195.35.6.141/",
                    actionLabel = "Verified"
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
    }
}

@Composable
fun ArchitectureBadge(layer: String, detail: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .background(NexoraEmeraldPrimary, CircleShape)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = "$layer: ",
            color = NexoraTextPrimary,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold
        )
        Text(
            text = detail,
            color = NexoraTextSecondary,
            fontSize = 12.sp
        )
    }
}

@Composable
fun SettingRowItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    actionLabel: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(NexoraDarkSurfaceCard),
            contentAlignment = Alignment.Center
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = NexoraEmeraldLight, modifier = Modifier.size(18.dp))
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, color = NexoraTextPrimary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            Text(text = subtitle, color = NexoraTextSecondary, fontSize = 11.sp)
        }

        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(6.dp))
                .background(Color(0x1A10B981))
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Text(text = actionLabel, color = NexoraEmeraldLight, fontSize = 11.sp, fontWeight = FontWeight.Bold)
        }
    }
}
