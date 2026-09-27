package com.example.ui.screens

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.CallMade
import androidx.compose.material.icons.filled.CallReceived
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Forum
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.domain.model.CallSession
import com.example.domain.model.CallType
import com.example.domain.model.ChatRoom
import com.example.domain.model.UserStatus
import com.example.ui.components.FirebaseSyncChip
import com.example.ui.components.NexoraAvatar
import com.example.ui.components.NexoraSearchBar
import com.example.ui.components.formatChatTime
import com.example.ui.components.formatSecondsToTimer
import com.example.ui.theme.NexoraCallRed
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
import com.example.ui.viewmodel.HomeTab
import com.example.ui.viewmodel.NexoraViewModel

@Composable
fun HomeScreen(
    viewModel: NexoraViewModel,
    onOpenFirebaseInfo: () -> Unit,
    modifier: Modifier = Modifier
) {
    val currentTab by viewModel.currentTab.collectAsStateWithLifecycle()
    val searchQuery by viewModel.searchQuery.collectAsStateWithLifecycle()
    val directRooms by viewModel.directRooms.collectAsStateWithLifecycle()
    val groupChannels by viewModel.groupChannels.collectAsStateWithLifecycle()
    val allCalls by viewModel.callLogs.collectAsStateWithLifecycle()
    val allUsers by viewModel.allUsers.collectAsStateWithLifecycle()
    val currentUser by viewModel.currentUser.collectAsStateWithLifecycle()
    val isFirebaseReady by viewModel.firebaseManager.isFirebaseReady.collectAsStateWithLifecycle()
    val syncStatus by viewModel.firebaseManager.syncStatus.collectAsStateWithLifecycle()

    var showNewChatDialog by remember { mutableStateOf(false) }

    Scaffold(
        modifier = modifier
            .fillMaxSize()
            .background(NexoraDarkBg)
            .statusBarsPadding(),
        containerColor = NexoraDarkBg,
        topBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(NexoraDarkBg)
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                // Brand Header Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        // Nexora Glowing Emblem
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(
                                    Brush.linearGradient(
                                        listOf(NexoraEmeraldPrimary, NexoraCyanAccent)
                                    )
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "N",
                                color = NexoraDarkBg,
                                fontWeight = FontWeight.Black,
                                fontSize = 20.sp
                            )
                        }

                        Spacer(modifier = Modifier.width(10.dp))

                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = "NEXORA",
                                    color = NexoraTextPrimary,
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Black,
                                    letterSpacing = 1.sp
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .background(NexoraEmeraldPrimary, CircleShape)
                                )
                            }
                            Text(
                                text = "HD WebRTC & Real-time Messaging",
                                color = NexoraTextMuted,
                                fontSize = 10.sp
                            )
                        }
                    }

                    // Firebase status badge
                    FirebaseSyncChip(
                        isReady = isFirebaseReady,
                        statusText = syncStatus,
                        onClick = onOpenFirebaseInfo
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Search Bar
                NexoraSearchBar(
                    query = searchQuery,
                    onQueryChange = { viewModel.updateSearchQuery(it) },
                    placeholder = when (currentTab) {
                        HomeTab.CHATS -> "Search conversations..."
                        HomeTab.CHANNELS -> "Search group channels..."
                        HomeTab.CALLS -> "Search call history..."
                        HomeTab.PROFILE -> "Search settings..."
                    }
                )
            }
        },
        bottomBar = {
            NavigationBar(
                containerColor = NexoraDarkSurface,
                modifier = Modifier
                    .navigationBarsPadding()
                    .border(
                        width = 1.dp,
                        color = NexoraDarkBorder,
                        shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)
                    )
                    .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
            ) {
                val navColors = NavigationBarItemDefaults.colors(
                    selectedIconColor = NexoraEmeraldPrimary,
                    selectedTextColor = NexoraEmeraldLight,
                    indicatorColor = Color(0x2210B981),
                    unselectedIconColor = NexoraTextMuted,
                    unselectedTextColor = NexoraTextMuted
                )

                NavigationBarItem(
                    selected = currentTab == HomeTab.CHATS,
                    onClick = { viewModel.selectTab(HomeTab.CHATS) },
                    icon = { Icon(Icons.Default.ChatBubble, contentDescription = "Chats") },
                    label = { Text("Chats", fontSize = 11.sp, fontWeight = FontWeight.Medium) },
                    colors = navColors,
                    modifier = Modifier.testTag("nav_chats")
                )

                NavigationBarItem(
                    selected = currentTab == HomeTab.CHANNELS,
                    onClick = { viewModel.selectTab(HomeTab.CHANNELS) },
                    icon = { Icon(Icons.Default.Forum, contentDescription = "Channels") },
                    label = { Text("Channels", fontSize = 11.sp, fontWeight = FontWeight.Medium) },
                    colors = navColors,
                    modifier = Modifier.testTag("nav_channels")
                )

                NavigationBarItem(
                    selected = currentTab == HomeTab.CALLS,
                    onClick = { viewModel.selectTab(HomeTab.CALLS) },
                    icon = { Icon(Icons.Default.Call, contentDescription = "Calls") },
                    label = { Text("Calls", fontSize = 11.sp, fontWeight = FontWeight.Medium) },
                    colors = navColors,
                    modifier = Modifier.testTag("nav_calls")
                )

                NavigationBarItem(
                    selected = currentTab == HomeTab.PROFILE,
                    onClick = { viewModel.selectTab(HomeTab.PROFILE) },
                    icon = { Icon(Icons.Default.Person, contentDescription = "Profile") },
                    label = { Text("Profile", fontSize = 11.sp, fontWeight = FontWeight.Medium) },
                    colors = navColors,
                    modifier = Modifier.testTag("nav_profile")
                )
            }
        },
        floatingActionButton = {
            if (currentTab == HomeTab.CHATS || currentTab == HomeTab.CHANNELS) {
                FloatingActionButton(
                    onClick = { showNewChatDialog = true },
                    containerColor = NexoraEmeraldPrimary,
                    contentColor = NexoraDarkBg,
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.testTag("fab_new_chat")
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "New Chat",
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(NexoraDarkBg)
        ) {
            when (currentTab) {
                HomeTab.CHATS -> {
                    val filtered = directRooms.filter {
                        it.name.contains(searchQuery, ignoreCase = true) ||
                                it.lastMessageText.contains(searchQuery, ignoreCase = true)
                    }
                    ChatRoomsList(
                        rooms = filtered,
                        onRoomClick = { viewModel.openRoom(it.id) },
                        emptyMessage = "No direct chats yet. Tap + to start a conversation!"
                    )
                }
                HomeTab.CHANNELS -> {
                    val filtered = groupChannels.filter {
                        it.name.contains(searchQuery, ignoreCase = true) ||
                                it.description.contains(searchQuery, ignoreCase = true)
                    }
                    ChatRoomsList(
                        rooms = filtered,
                        onRoomClick = { viewModel.openRoom(it.id) },
                        emptyMessage = "No group channels found. Tap + to create one!"
                    )
                }
                HomeTab.CALLS -> {
                    val filtered = allCalls.filter {
                        it.roomName.contains(searchQuery, ignoreCase = true) ||
                                it.callerName.contains(searchQuery, ignoreCase = true)
                    }
                    CallsHistoryList(
                        calls = filtered,
                        onCallAgain = { call ->
                            val targetRoom = (directRooms + groupChannels).firstOrNull { it.id == call.roomId }
                            if (targetRoom != null) {
                                viewModel.startCall(targetRoom, call.callType)
                            }
                        }
                    )
                }
                HomeTab.PROFILE -> {
                    ProfileSettingsScreen(
                        viewModel = viewModel,
                        onOpenFirebaseDocs = onOpenFirebaseInfo
                    )
                }
            }
        }
    }

    if (showNewChatDialog) {
        NewChatDialog(
            users = allUsers.filter { it.id != currentUser.id },
            onDismiss = { showNewChatDialog = false },
            onCreateDirect = { targetUser ->
                viewModel.createChat(
                    name = targetUser.name,
                    isGroup = false,
                    memberIds = listOf(targetUser.id),
                    description = ""
                )
            },
            onCreateGroup = { name, memberIds, desc ->
                viewModel.createChat(
                    name = name,
                    isGroup = true,
                    memberIds = memberIds,
                    description = desc
                )
            }
        )
    }
}

@Composable
fun ChatRoomsList(
    rooms: List<ChatRoom>,
    onRoomClick: (ChatRoom) -> Unit,
    emptyMessage: String,
    modifier: Modifier = Modifier
) {
    if (rooms.isEmpty()) {
        Box(
            modifier = modifier
                .fillMaxSize()
                .padding(32.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(CircleShape)
                        .background(NexoraDarkSurfaceCard),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.ChatBubble,
                        contentDescription = null,
                        tint = NexoraTextMuted,
                        modifier = Modifier.size(28.dp)
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = emptyMessage,
                    color = NexoraTextSecondary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    } else {
        LazyColumn(
            modifier = modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp)
        ) {
            items(rooms, key = { it.id }) { room ->
                ChatRoomRow(room = room, onClick = { onRoomClick(room) })
                Spacer(modifier = Modifier.height(6.dp))
            }
        }
    }
}

@Composable
fun ChatRoomRow(
    room: ChatRoom,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(NexoraDarkSurface)
            .border(1.dp, NexoraDarkBorder.copy(alpha = 0.5f), RoundedCornerShape(14.dp))
            .clickable { onClick() }
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        NexoraAvatar(
            name = room.name,
            avatarUrl = room.avatarUrl,
            size = 50.dp,
            isGroup = room.isGroup,
            status = if (!room.isGroup) UserStatus.ONLINE else null
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = room.name,
                    color = NexoraTextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )

                Text(
                    text = formatChatTime(room.lastMessageTime),
                    color = NexoraTextMuted,
                    fontSize = 11.sp
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Icon indicator for message type preview
                when {
                    room.lastMessageText.contains("📷") || room.lastMessageText.contains("Photo") -> {
                        Icon(Icons.Default.Image, contentDescription = null, tint = NexoraCyanAccent, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                    room.lastMessageText.contains("🎵") || room.lastMessageText.contains("Voice Note") -> {
                        Icon(Icons.Default.Headphones, contentDescription = null, tint = NexoraEmeraldLight, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                }

                Text(
                    text = room.lastMessageText.ifBlank { "No messages yet" },
                    color = if (room.unreadCount > 0) NexoraTextPrimary else NexoraTextSecondary,
                    fontWeight = if (room.unreadCount > 0) FontWeight.SemiBold else FontWeight.Normal,
                    fontSize = 13.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )

                if (room.unreadCount > 0) {
                    Spacer(modifier = Modifier.width(8.dp))
                    Box(
                        modifier = Modifier
                            .size(20.dp)
                            .clip(CircleShape)
                            .background(NexoraEmeraldPrimary),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "${room.unreadCount}",
                            color = NexoraDarkBg,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun CallsHistoryList(
    calls: List<CallSession>,
    onCallAgain: (CallSession) -> Unit,
    modifier: Modifier = Modifier
) {
    if (calls.isEmpty()) {
        Box(
            modifier = modifier
                .fillMaxSize()
                .padding(32.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(text = "No recent WebRTC calls.", color = NexoraTextSecondary, fontSize = 14.sp)
        }
    } else {
        LazyColumn(
            modifier = modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp)
        ) {
            items(calls, key = { it.id }) { call ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(NexoraDarkSurface)
                        .border(1.dp, NexoraDarkBorder.copy(alpha = 0.5f), RoundedCornerShape(14.dp))
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    NexoraAvatar(name = call.roomName, avatarUrl = call.roomAvatar, size = 46.dp)

                    Spacer(modifier = Modifier.width(12.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = call.roomName,
                            color = NexoraTextPrimary,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp
                        )
                        Spacer(modifier = Modifier.height(3.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = if (call.state == com.example.domain.model.CallState.ENDED) Icons.Default.CallMade else Icons.Default.CallReceived,
                                contentDescription = null,
                                tint = if (call.durationSeconds > 0) NexoraEmeraldLight else NexoraCallRed,
                                modifier = Modifier.size(13.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = if (call.durationSeconds > 0) "${formatSecondsToTimer(call.durationSeconds)} • HD WebRTC" else "Missed Call",
                                color = NexoraTextSecondary,
                                fontSize = 12.sp
                            )
                        }
                    }

                    IconButton(
                        onClick = { onCallAgain(call) },
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(Color(0x1A10B981))
                    ) {
                        Icon(
                            imageVector = if (call.callType == CallType.VIDEO) Icons.Default.Videocam else Icons.Default.Call,
                            contentDescription = "Call Again",
                            tint = NexoraEmeraldLight,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.height(6.dp))
            }
        }
    }
}
