package com.example.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Done
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.example.domain.model.CallType
import com.example.domain.model.ChatRoom
import com.example.domain.model.Message
import com.example.domain.model.MessageType
import com.example.domain.model.UserStatus
import com.example.ui.components.AudioWaveformVisualizer
import com.example.ui.components.NexoraAvatar
import com.example.ui.components.formatChatTime
import com.example.ui.components.formatSecondsToTimer
import com.example.ui.theme.NexoraCallRed
import com.example.ui.theme.NexoraCyanAccent
import com.example.ui.theme.NexoraDarkBg
import com.example.ui.theme.NexoraDarkBorder
import com.example.ui.theme.NexoraDarkSurface
import com.example.ui.theme.NexoraDarkSurfaceCard
import com.example.ui.theme.NexoraEmeraldDark
import com.example.ui.theme.NexoraEmeraldLight
import com.example.ui.theme.NexoraEmeraldPrimary
import com.example.ui.theme.NexoraTextMuted
import com.example.ui.theme.NexoraTextPrimary
import com.example.ui.theme.NexoraTextSecondary
import com.example.ui.viewmodel.NexoraViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun ChatScreen(
    room: ChatRoom,
    viewModel: NexoraViewModel,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    BackHandler { onBack() }

    val messages by viewModel.activeMessages.collectAsStateWithLifecycle()
    val currentUser by viewModel.currentUser.collectAsStateWithLifecycle()

    var inputText by remember { mutableStateOf("") }
    var isRecordingVoice by remember { mutableStateOf(false) }
    var recordingTimer by remember { mutableIntStateOf(0) }
    var showAttachmentMenu by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    // Voice recording timer
    LaunchedEffect(isRecordingVoice) {
        if (isRecordingVoice) {
            recordingTimer = 0
            while (isRecordingVoice) {
                delay(1000)
                recordingTimer += 1
            }
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(NexoraDarkBg)
            .statusBarsPadding()
            .imePadding()
            .testTag("chat_screen")
    ) {
        // Chat Top Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(NexoraDarkSurface)
                .border(
                    width = 1.dp,
                    color = NexoraDarkBorder.copy(alpha = 0.5f),
                    shape = RoundedCornerShape(bottomStart = 16.dp, bottomEnd = 16.dp)
                )
                .padding(horizontal = 8.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack, modifier = Modifier.size(38.dp)) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = NexoraTextPrimary
                )
            }

            Spacer(modifier = Modifier.width(4.dp))

            NexoraAvatar(
                name = room.name,
                avatarUrl = room.avatarUrl,
                size = 40.dp,
                isGroup = room.isGroup,
                status = if (!room.isGroup) UserStatus.ONLINE else null
            )

            Spacer(modifier = Modifier.width(10.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = room.name,
                    color = NexoraTextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1
                )
                Text(
                    text = if (room.isGroup) "${room.memberIds.size} members" else "Online • WebRTC Ready",
                    color = if (room.isGroup) NexoraTextMuted else NexoraEmeraldLight,
                    fontSize = 11.sp
                )
            }

            // WebRTC Voice Call Action Button
            IconButton(
                onClick = { viewModel.startCall(room, CallType.VOICE) },
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(Color(0x1A10B981))
                    .testTag("btn_voice_call")
            ) {
                Icon(
                    imageVector = Icons.Default.Call,
                    contentDescription = "WebRTC Voice Call",
                    tint = NexoraEmeraldLight,
                    modifier = Modifier.size(18.dp)
                )
            }

            Spacer(modifier = Modifier.width(8.dp))

            // WebRTC Video Call Action Button
            IconButton(
                onClick = { viewModel.startCall(room, CallType.VIDEO) },
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(Color(0x2206B6D4))
                    .testTag("btn_video_call")
            ) {
                Icon(
                    imageVector = Icons.Default.Videocam,
                    contentDescription = "WebRTC Video Call",
                    tint = NexoraCyanAccent,
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        // Messages Thread
        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp)
        ) {
            items(messages, key = { it.id }) { message ->
                val isMe = message.senderId == currentUser.id
                MessageBubble(
                    message = message,
                    isMe = isMe,
                    onDelete = { viewModel.deleteMessage(message.id) },
                    onReact = { emoji -> viewModel.reactToMessage(message.id, emoji) }
                )
                Spacer(modifier = Modifier.height(6.dp))
            }
        }

        // Attachment selection popup
        if (showAttachmentMenu) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(NexoraDarkSurfaceCard)
                    .border(1.dp, NexoraDarkBorder, RoundedCornerShape(14.dp))
                    .padding(8.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                AttachmentOption(icon = Icons.Default.Image, label = "Photo", color = NexoraCyanAccent) {
                    showAttachmentMenu = false
                    viewModel.sendMessage(
                        content = "📷 Shared a photo",
                        type = MessageType.IMAGE,
                        mediaUrl = "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=600&q=80",
                        fileName = "snapshot.jpg",
                        fileSize = "1.8 MB"
                    )
                }

                AttachmentOption(icon = Icons.Default.AttachFile, label = "Doc", color = NexoraEmeraldLight) {
                    showAttachmentMenu = false
                    viewModel.sendMessage(
                        content = "📎 Nexora_Architecture_Whitepaper.pdf",
                        type = MessageType.FILE,
                        fileName = "Nexora_Architecture_Whitepaper.pdf",
                        fileSize = "3.4 MB"
                    )
                }

                AttachmentOption(icon = Icons.Default.Headphones, label = "Voice Demo", color = Color(0xFFA78BFA)) {
                    showAttachmentMenu = false
                    viewModel.sendMessage(
                        content = "🎵 Voice Note",
                        type = MessageType.AUDIO_VOICE,
                        audioDuration = 18
                    )
                }
            }
        }

        // Bottom Input Row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(NexoraDarkSurface)
                .navigationBarsPadding()
                .padding(horizontal = 10.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (isRecordingVoice) {
                // Live Voice Recorder Bar
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(24.dp))
                        .background(NexoraDarkSurfaceCard)
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .background(NexoraCallRed, CircleShape)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Recording: ${formatSecondsToTimer(recordingTimer)}",
                        color = NexoraTextPrimary,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    IconButton(
                        onClick = { isRecordingVoice = false },
                        modifier = Modifier.size(24.dp)
                    ) {
                        Icon(Icons.Default.Close, contentDescription = "Cancel", tint = NexoraTextSecondary)
                    }
                }

                Spacer(modifier = Modifier.width(8.dp))

                IconButton(
                    onClick = {
                        isRecordingVoice = false
                        viewModel.sendMessage(
                            content = "🎵 Voice Note (${formatSecondsToTimer(recordingTimer)})",
                            type = MessageType.AUDIO_VOICE,
                            audioDuration = recordingTimer.coerceAtLeast(1)
                        )
                    },
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(NexoraEmeraldPrimary)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Send Voice Note",
                        tint = NexoraDarkBg
                    )
                }
            } else {
                IconButton(
                    onClick = { showAttachmentMenu = !showAttachmentMenu },
                    modifier = Modifier.size(38.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.AttachFile,
                        contentDescription = "Attach file",
                        tint = if (showAttachmentMenu) NexoraEmeraldLight else NexoraTextSecondary
                    )
                }

                OutlinedTextField(
                    value = inputText,
                    onValueChange = { inputText = it },
                    placeholder = { Text("Message...", color = NexoraTextMuted, fontSize = 14.sp) },
                    singleLine = false,
                    maxLines = 4,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedContainerColor = NexoraDarkSurfaceCard,
                        unfocusedContainerColor = NexoraDarkSurfaceCard,
                        focusedBorderColor = NexoraEmeraldPrimary,
                        unfocusedBorderColor = NexoraDarkBorder,
                        focusedTextColor = NexoraTextPrimary,
                        unfocusedTextColor = NexoraTextPrimary
                    ),
                    shape = RoundedCornerShape(20.dp),
                    modifier = Modifier
                        .weight(1f)
                        .testTag("chat_input_field")
                )

                Spacer(modifier = Modifier.width(6.dp))

                if (inputText.isNotBlank()) {
                    IconButton(
                        onClick = {
                            viewModel.sendMessage(inputText)
                            inputText = ""
                        },
                        modifier = Modifier
                            .size(42.dp)
                            .clip(CircleShape)
                            .background(NexoraEmeraldPrimary)
                            .testTag("chat_send_button")
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Send,
                            contentDescription = "Send",
                            tint = NexoraDarkBg,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                } else {
                    IconButton(
                        onClick = { isRecordingVoice = true },
                        modifier = Modifier
                            .size(42.dp)
                            .clip(CircleShape)
                            .background(NexoraDarkSurfaceCard)
                            .testTag("chat_mic_button")
                    ) {
                        Icon(
                            imageVector = Icons.Default.Mic,
                            contentDescription = "Record Voice Note",
                            tint = NexoraEmeraldLight,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MessageBubble(
    message: Message,
    isMe: Boolean,
    onDelete: () -> Unit,
    onReact: (String) -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    var isPlayingVoice by remember { mutableStateOf(false) }

    val bubbleBg = if (isMe) {
        Brush.linearGradient(listOf(NexoraEmeraldPrimary, NexoraEmeraldDark))
    } else {
        Brush.linearGradient(listOf(NexoraDarkSurfaceCard, NexoraDarkSurfaceCard))
    }

    val bubbleShape = RoundedCornerShape(
        topStart = 16.dp,
        topEnd = 16.dp,
        bottomStart = if (isMe) 16.dp else 4.dp,
        bottomEnd = if (isMe) 4.dp else 16.dp
    )

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = if (isMe) Alignment.End else Alignment.Start
    ) {
        if (!isMe) {
            Text(
                text = message.senderName,
                color = NexoraTextMuted,
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(start = 8.dp, bottom = 2.dp)
            )
        }

        Box {
            Surface(
                shape = bubbleShape,
                color = Color.Transparent,
                border = if (!isMe) androidx.compose.foundation.BorderStroke(1.dp, NexoraDarkBorder) else null,
                modifier = Modifier
                    .widthIn(max = 280.dp)
                    .combinedClickable(
                        onClick = {},
                        onLongClick = { showMenu = true }
                    )
            ) {
                Box(
                    modifier = Modifier
                        .background(bubbleBg)
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Column {
                        if (message.isDeleted) {
                            Text(
                                text = "🚫 This message was deleted",
                                color = if (isMe) NexoraDarkBg.copy(alpha = 0.8f) else NexoraTextMuted,
                                fontSize = 13.sp,
                                fontStyle = FontStyle.Italic
                            )
                        } else {
                            // Message Content by Type
                            when (message.type) {
                                MessageType.TEXT -> {
                                    Text(
                                        text = message.content,
                                        color = if (isMe) Color.White else NexoraTextPrimary,
                                        fontSize = 14.sp
                                    )
                                }
                                MessageType.IMAGE -> {
                                    if (!message.mediaUrl.isNullOrBlank()) {
                                        AsyncImage(
                                            model = message.mediaUrl,
                                            contentDescription = "Shared image",
                                            contentScale = ContentScale.Crop,
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .height(160.dp)
                                                .clip(RoundedCornerShape(8.dp))
                                        )
                                        Spacer(modifier = Modifier.height(4.dp))
                                    }
                                    if (message.content.isNotBlank()) {
                                        Text(
                                            text = message.content,
                                            color = if (isMe) Color.White else NexoraTextPrimary,
                                            fontSize = 13.sp
                                        )
                                    }
                                }
                                MessageType.FILE -> {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clip(RoundedCornerShape(8.dp))
                                            .background(Color(0x22000000))
                                            .padding(8.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            Icons.Default.AttachFile,
                                            contentDescription = null,
                                            tint = if (isMe) Color.White else NexoraEmeraldLight,
                                            modifier = Modifier.size(24.dp)
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Column {
                                            Text(
                                                text = message.fileName ?: "Document",
                                                color = if (isMe) Color.White else NexoraTextPrimary,
                                                fontSize = 13.sp,
                                                fontWeight = FontWeight.SemiBold
                                            )
                                            Text(
                                                text = message.fileSize ?: "File",
                                                color = if (isMe) Color.White.copy(alpha = 0.7f) else NexoraTextMuted,
                                                fontSize = 11.sp
                                            )
                                        }
                                    }
                                }
                                MessageType.AUDIO_VOICE -> {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        IconButton(
                                            onClick = { isPlayingVoice = !isPlayingVoice },
                                            modifier = Modifier
                                                .size(32.dp)
                                                .clip(CircleShape)
                                                .background(if (isMe) Color.White.copy(alpha = 0.25f) else Color(0x1A10B981))
                                        ) {
                                            Icon(
                                                imageVector = if (isPlayingVoice) Icons.Default.Pause else Icons.Default.PlayArrow,
                                                contentDescription = "Play voice note",
                                                tint = if (isMe) Color.White else NexoraEmeraldLight,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }
                                        Spacer(modifier = Modifier.width(8.dp))
                                        AudioWaveformVisualizer(
                                            levels = listOf(0.3f, 0.7f, 0.9f, 0.4f, 0.8f, 0.5f, 0.6f, 0.2f, 0.7f, 0.4f),
                                            modifier = Modifier.weight(1f),
                                            barColor = if (isMe) Color.White else NexoraEmeraldLight
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            text = formatSecondsToTimer(message.audioDurationSeconds.coerceAtLeast(6)),
                                            color = if (isMe) Color.White.copy(alpha = 0.8f) else NexoraTextSecondary,
                                            fontSize = 11.sp
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(4.dp))

                        // Timestamp & Read Receipt
                        Row(
                            modifier = Modifier.align(Alignment.End),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = formatChatTime(message.timestamp),
                                color = if (isMe) Color.White.copy(alpha = 0.7f) else NexoraTextMuted,
                                fontSize = 10.sp
                            )
                            if (isMe && !message.isDeleted) {
                                Spacer(modifier = Modifier.width(4.dp))
                                Icon(
                                    imageVector = if (message.isRead) Icons.Default.DoneAll else Icons.Default.Done,
                                    contentDescription = if (message.isRead) "Read" else "Sent",
                                    tint = if (message.isRead) Color.White else Color.White.copy(alpha = 0.6f),
                                    modifier = Modifier.size(13.dp)
                                )
                            }
                        }
                    }
                }
            }

            // Long Press Options Menu (Reactions, Delete)
            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false },
                modifier = Modifier.background(NexoraDarkSurface)
            ) {
                // Quick emoji reaction bar
                Row(modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)) {
                    listOf("👍", "❤️", "🔥", "😂", "😮").forEach { emoji ->
                        Text(
                            text = emoji,
                            fontSize = 20.sp,
                            modifier = Modifier
                                .clip(CircleShape)
                                .clickable {
                                    onReact(emoji)
                                    showMenu = false
                                }
                                .padding(6.dp)
                        )
                    }
                }

                if (isMe && !message.isDeleted) {
                    DropdownMenuItem(
                        text = { Text("Delete message", color = NexoraCallRed) },
                        leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null, tint = NexoraCallRed) },
                        onClick = {
                            onDelete()
                            showMenu = false
                        }
                    )
                }
            }
        }

        // Render Reactions Pill if any
        if (message.reactions.isNotEmpty() && !message.isDeleted) {
            Row(
                modifier = Modifier
                    .padding(top = 2.dp, start = 4.dp, end = 4.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(NexoraDarkSurfaceCard)
                    .border(1.dp, NexoraDarkBorder, RoundedCornerShape(12.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                message.reactions.forEach { (emoji, count) ->
                    Text(
                        text = "$emoji $count",
                        fontSize = 11.sp,
                        color = NexoraTextSecondary
                    )
                }
            }
        }
    }
}

@Composable
fun AttachmentOption(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    color: Color,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .clickable { onClick() }
            .padding(8.dp)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(color.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(imageVector = icon, contentDescription = label, tint = color, modifier = Modifier.size(20.dp))
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(text = label, color = NexoraTextSecondary, fontSize = 11.sp)
    }
}
