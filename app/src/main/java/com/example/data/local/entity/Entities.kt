package com.example.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.domain.model.CallState
import com.example.domain.model.CallType
import com.example.domain.model.MessageType
import com.example.domain.model.UserStatus

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val handle: String,
    val email: String,
    val avatarUrl: String,
    val status: String,
    val statusMessage: String,
    val lastSeen: Long
)

@Entity(tableName = "chat_rooms")
data class ChatRoomEntity(
    @PrimaryKey val id: String,
    val name: String,
    val isGroup: Boolean,
    val avatarUrl: String,
    val lastMessageText: String,
    val lastMessageTime: Long,
    val lastMessageSenderName: String,
    val unreadCount: Int,
    val memberIds: String, // Comma-separated or JSON
    val adminIds: String,
    val description: String
)

@Entity(tableName = "messages")
data class MessageEntity(
    @PrimaryKey val id: String,
    val roomId: String,
    val senderId: String,
    val senderName: String,
    val senderAvatar: String,
    val content: String,
    val type: String,
    val mediaUrl: String?,
    val fileName: String?,
    val fileSize: String?,
    val audioDurationSeconds: Int,
    val isRead: Boolean,
    val isDeleted: Boolean,
    val reactions: String, // e.g. "👍:2,❤️:1"
    val timestamp: Long
)

@Entity(tableName = "call_logs")
data class CallLogEntity(
    @PrimaryKey val id: String,
    val roomId: String,
    val roomName: String,
    val roomAvatar: String,
    val callerId: String,
    val callerName: String,
    val callerAvatar: String,
    val receiverId: String,
    val callType: String,
    val state: String,
    val durationSeconds: Int,
    val timestamp: Long
)
