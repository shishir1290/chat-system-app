package com.example.domain.model

enum class UserStatus(val label: String) {
    ONLINE("Online"),
    AWAY("Away"),
    BUSY("Do Not Disturb"),
    OFFLINE("Offline")
}

data class User(
    val id: String,
    val name: String,
    val handle: String,
    val email: String,
    val avatarUrl: String = "",
    val status: UserStatus = UserStatus.ONLINE,
    val statusMessage: String = "Building with Nexora",
    val lastSeen: Long = System.currentTimeMillis()
)

enum class MessageType {
    TEXT,
    IMAGE,
    FILE,
    AUDIO_VOICE
}

data class Message(
    val id: String,
    val roomId: String,
    val senderId: String,
    val senderName: String,
    val senderAvatar: String = "",
    val content: String,
    val type: MessageType = MessageType.TEXT,
    val mediaUrl: String? = null,
    val fileName: String? = null,
    val fileSize: String? = null,
    val audioDurationSeconds: Int = 0,
    val isRead: Boolean = true,
    val isDeleted: Boolean = false,
    val reactions: Map<String, Int> = emptyMap(),
    val timestamp: Long = System.currentTimeMillis()
)

data class ChatRoom(
    val id: String,
    val name: String,
    val isGroup: Boolean,
    val avatarUrl: String = "",
    val lastMessageText: String = "",
    val lastMessageTime: Long = System.currentTimeMillis(),
    val lastMessageSenderName: String = "",
    val unreadCount: Int = 0,
    val memberIds: List<String> = emptyList(),
    val adminIds: List<String> = emptyList(),
    val description: String = ""
)

enum class CallType {
    VOICE,
    VIDEO
}

enum class CallState {
    IDLE,
    DIALING,
    RINGING,
    CONNECTED,
    ENDED
}

data class CallSession(
    val id: String,
    val roomId: String,
    val roomName: String,
    val roomAvatar: String = "",
    val callerId: String,
    val callerName: String,
    val callerAvatar: String = "",
    val receiverId: String,
    val callType: CallType = CallType.VIDEO,
    val state: CallState = CallState.DIALING,
    val durationSeconds: Int = 0,
    val timestamp: Long = System.currentTimeMillis()
)
