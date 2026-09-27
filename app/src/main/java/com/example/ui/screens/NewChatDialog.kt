package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.GroupAdd
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
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
import androidx.compose.ui.window.Dialog
import com.example.domain.model.User
import com.example.ui.components.NexoraAvatar
import com.example.ui.theme.NexoraDarkBg
import com.example.ui.theme.NexoraDarkBorder
import com.example.ui.theme.NexoraDarkSurface
import com.example.ui.theme.NexoraDarkSurfaceCard
import com.example.ui.theme.NexoraEmeraldLight
import com.example.ui.theme.NexoraEmeraldPrimary
import com.example.ui.theme.NexoraTextMuted
import com.example.ui.theme.NexoraTextPrimary
import com.example.ui.theme.NexoraTextSecondary

@Composable
fun NewChatDialog(
    users: List<User>,
    onDismiss: () -> Unit,
    onCreateDirect: (user: User) -> Unit,
    onCreateGroup: (name: String, memberIds: List<String>, description: String) -> Unit
) {
    var selectedTab by remember { mutableStateOf(0) }
    var groupName by remember { mutableStateOf("") }
    var groupDescription by remember { mutableStateOf("") }
    val selectedUserIds = remember { mutableStateListOf<String>() }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = NexoraDarkSurface,
            border = androidx.compose.foundation.BorderStroke(1.dp, NexoraDarkBorder),
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp)
                .testTag("new_chat_dialog")
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (selectedTab == 0) "New Conversation" else "Create Channel",
                        color = NexoraTextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close",
                            tint = NexoraTextSecondary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Tabs: Direct Message vs Group Channel
                TabRow(
                    selectedTabIndex = selectedTab,
                    containerColor = NexoraDarkSurfaceCard,
                    contentColor = NexoraEmeraldLight,
                    indicator = { tabPositions ->
                        TabRowDefaults.SecondaryIndicator(
                            Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                            color = NexoraEmeraldPrimary
                        )
                    },
                    modifier = Modifier.clip(RoundedCornerShape(10.dp))
                ) {
                    Tab(
                        selected = selectedTab == 0,
                        onClick = { selectedTab = 0 },
                        text = {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.PersonAdd, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Direct Chat", fontSize = 13.sp)
                            }
                        }
                    )
                    Tab(
                        selected = selectedTab == 1,
                        onClick = { selectedTab = 1 },
                        text = {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.GroupAdd, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Group Channel", fontSize = 13.sp)
                            }
                        }
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                if (selectedTab == 0) {
                    // Direct Chat List
                    Text(
                        text = "SELECT CONTACT",
                        color = NexoraTextMuted,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(280.dp)
                    ) {
                        items(users) { user ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(12.dp))
                                    .clickable {
                                        onCreateDirect(user)
                                        onDismiss()
                                    }
                                    .padding(vertical = 10.dp, horizontal = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                NexoraAvatar(name = user.name, avatarUrl = user.avatarUrl, size = 42.dp, status = user.status)
                                Spacer(modifier = Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(text = user.name, color = NexoraTextPrimary, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                    Text(text = user.handle, color = NexoraTextSecondary, fontSize = 12.sp)
                                }
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0x1A10B981))
                                        .padding(horizontal = 8.dp, vertical = 4.dp)
                                ) {
                                    Text("Chat", color = NexoraEmeraldLight, fontSize = 12.sp, fontWeight = FontWeight.Medium)
                                }
                            }
                        }
                    }
                } else {
                    // Group Channel Setup
                    OutlinedTextField(
                        value = groupName,
                        onValueChange = { groupName = it },
                        label = { Text("Channel Name", color = NexoraTextSecondary) },
                        placeholder = { Text("e.g. #mobile-team", color = NexoraTextMuted) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedContainerColor = NexoraDarkSurfaceCard,
                            unfocusedContainerColor = NexoraDarkSurfaceCard,
                            focusedBorderColor = NexoraEmeraldPrimary,
                            unfocusedBorderColor = NexoraDarkBorder,
                            focusedTextColor = NexoraTextPrimary,
                            unfocusedTextColor = NexoraTextPrimary
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    OutlinedTextField(
                        value = groupDescription,
                        onValueChange = { groupDescription = it },
                        label = { Text("Topic / Description (Optional)", color = NexoraTextSecondary) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedContainerColor = NexoraDarkSurfaceCard,
                            unfocusedContainerColor = NexoraDarkSurfaceCard,
                            focusedBorderColor = NexoraEmeraldPrimary,
                            unfocusedBorderColor = NexoraDarkBorder,
                            focusedTextColor = NexoraTextPrimary,
                            unfocusedTextColor = NexoraTextPrimary
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Text(
                        text = "ADD MEMBERS (${selectedUserIds.size} selected)",
                        color = NexoraTextMuted,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(6.dp))

                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(140.dp)
                    ) {
                        items(users) { user ->
                            val isSelected = selectedUserIds.contains(user.id)
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .clickable {
                                        if (isSelected) selectedUserIds.remove(user.id) else selectedUserIds.add(user.id)
                                    }
                                    .padding(vertical = 6.dp, horizontal = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                NexoraAvatar(name = user.name, avatarUrl = user.avatarUrl, size = 32.dp)
                                Spacer(modifier = Modifier.width(10.dp))
                                Text(
                                    text = user.name,
                                    color = NexoraTextPrimary,
                                    fontSize = 13.sp,
                                    modifier = Modifier.weight(1f)
                                )
                                Box(
                                    modifier = Modifier
                                        .size(22.dp)
                                        .clip(CircleShape)
                                        .background(if (isSelected) NexoraEmeraldPrimary else NexoraDarkSurfaceCard)
                                        .border(1.dp, if (isSelected) NexoraEmeraldPrimary else NexoraDarkBorder, CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (isSelected) {
                                        Icon(
                                            imageVector = Icons.Default.Check,
                                            contentDescription = "Selected",
                                            tint = NexoraDarkBg,
                                            modifier = Modifier.size(14.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Button(
                        onClick = {
                            if (groupName.isNotBlank()) {
                                onCreateGroup(groupName, selectedUserIds.toList(), groupDescription)
                                onDismiss()
                            }
                        },
                        enabled = groupName.isNotBlank(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = NexoraEmeraldPrimary,
                            contentColor = NexoraDarkBg,
                            disabledContainerColor = NexoraDarkSurfaceCard,
                            disabledContentColor = NexoraTextMuted
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp)
                            .testTag("create_channel_button")
                    ) {
                        Text("Create Channel", fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    }
                }
            }
        }
    }
}
