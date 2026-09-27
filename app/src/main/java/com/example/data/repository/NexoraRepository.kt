package com.example.data.repository

import com.example.data.local.NexoraDatabase
import com.example.data.local.entity.CallLogEntity
import com.example.data.local.entity.ChatRoomEntity
import com.example.data.local.entity.MessageEntity
import com.example.data.local.entity.UserEntity
import com.example.data.remote.FirebaseSyncManager
import com.example.domain.model.CallSession
import com.example.domain.model.CallState
import com.example.domain.model.CallType
import com.example.domain.model.ChatRoom
import com.example.domain.model.Message
import com.example.domain.model.MessageType
import com.example.domain.model.User
import com.example.domain.model.UserStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import java.util.UUID

class NexoraRepository(
    private val database: NexoraDatabase,
    val firebaseManager: FirebaseSyncManager
) {
    private val scope = CoroutineScope(Dispatchers.IO)

    private val _currentUser = MutableStateFlow(
        User(
            id = "current_user_101",
            name = "Sadman Shishir",
            handle = "@sadman_nexora",
            email = "sadmanurshishir1290@gmail.com",
            avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80",
            status = UserStatus.ONLINE,
            statusMessage = "Developing real-time WebRTC & Firebase modules 🚀",
            lastSeen = System.currentTimeMillis()
        )
    )
    val currentUser = _currentUser.asStateFlow()

    init {
        scope.launch {
            seedInitialDataIfEmpty()
        }
    }

    private suspend fun seedInitialDataIfEmpty() {
        val userDao = database.userDao()
        val roomDao = database.chatRoomDao()
        val msgDao = database.messageDao()
        val callDao = database.callLogDao()

        // Seed Users
        val users = listOf(
            UserEntity("u_1", "Alex Rivera", "@alex_r", "alex@nexora.chat", "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=256&q=80", "ONLINE", "Testing WebRTC P2P mesh", System.currentTimeMillis()),
            UserEntity("u_2", "Sophia Zhang", "@sophia_z", "sophia@nexora.chat", "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=256&q=80", "ONLINE", "Refining Slate-950 UI components", System.currentTimeMillis()),
            UserEntity("u_3", "Tariq Mansoor", "@tariq_m", "tariq@nexora.chat", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80", "AWAY", "Reviewing Firestore security rules", System.currentTimeMillis() - 3600000),
            UserEntity("u_4", "Elena Rostova", "@elena_dev", "elena@nexora.chat", "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=256&q=80", "BUSY", "In a video standup", System.currentTimeMillis() - 7200000)
        )
        userDao.insertUsers(users)

        // Seed Rooms
        val rooms = listOf(
            ChatRoomEntity(
                id = "room_alex",
                name = "Alex Rivera",
                isGroup = false,
                avatarUrl = "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=256&q=80",
                lastMessageText = "WebRTC peer connection established! Check out the 60fps feed.",
                lastMessageTime = System.currentTimeMillis() - 60000 * 5,
                lastMessageSenderName = "Alex Rivera",
                unreadCount = 1,
                memberIds = "current_user_101,u_1",
                adminIds = "",
                description = "Direct peer conversation"
            ),
            ChatRoomEntity(
                id = "room_general",
                name = "#general",
                isGroup = true,
                avatarUrl = "",
                lastMessageText = "Welcome to Nexora! Real-time messaging & WebRTC HD calling clone ready.",
                lastMessageTime = System.currentTimeMillis() - 60000 * 25,
                lastMessageSenderName = "Sophia Zhang",
                unreadCount = 0,
                memberIds = "current_user_101,u_1,u_2,u_3,u_4",
                adminIds = "current_user_101,u_2",
                description = "General community channel for announcements & collaboration."
            ),
            ChatRoomEntity(
                id = "room_webrtc",
                name = "WebRTC Core Team",
                isGroup = true,
                avatarUrl = "",
                lastMessageText = "OPUS 48kHz audio codec packet loss concealment enabled.",
                lastMessageTime = System.currentTimeMillis() - 60000 * 90,
                lastMessageSenderName = "Tariq Mansoor",
                unreadCount = 3,
                memberIds = "current_user_101,u_1,u_3",
                adminIds = "u_1",
                description = "High-definition voice & video WebRTC media server integration."
            ),
            ChatRoomEntity(
                id = "room_elena",
                name = "Elena Rostova",
                isGroup = false,
                avatarUrl = "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=256&q=80",
                lastMessageText = "🎵 Voice Note (0:14)",
                lastMessageTime = System.currentTimeMillis() - 60000 * 180,
                lastMessageSenderName = "Elena Rostova",
                unreadCount = 0,
                memberIds = "current_user_101,u_4",
                adminIds = "",
                description = "Direct peer conversation"
            )
        )
        roomDao.insertRooms(rooms)

        // Seed initial messages for Alex
        val alexMessages = listOf(
            MessageEntity("m_1", "room_alex", "u_1", "Alex Rivera", "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=256&q=80", "Hey Sadman! Have you inspected the server architecture at 195.35.6.141?", "TEXT", null, null, null, 0, true, false, "👍:2,🔥:1", System.currentTimeMillis() - 60000 * 30),
            MessageEntity("m_2", "room_alex", "current_user_101", "Sadman Shishir", _currentUser.value.avatarUrl, "Yes! Nexora features real-time messaging, group channels, and WebRTC HD calling.", "TEXT", null, null, null, 0, true, false, "🚀:2", System.currentTimeMillis() - 60000 * 20),
            MessageEntity("m_3", "room_alex", "u_1", "Alex Rivera", "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=256&q=80", "Here is the network diagram for Firebase and WebRTC signaling.", "IMAGE", "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=600&q=80", "nexora_arch.png", "2.4 MB", 0, true, false, "❤️:1", System.currentTimeMillis() - 60000 * 12),
            MessageEntity("m_4", "room_alex", "u_1", "Alex Rivera", "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=256&q=80", "WebRTC peer connection established! Check out the 60fps feed.", "TEXT", null, null, null, 0, false, false, "", System.currentTimeMillis() - 60000 * 5)
        )
        msgDao.insertMessages(alexMessages)

        // Seed initial calls
        val calls = listOf(
            CallLogEntity("c_1", "room_alex", "Alex Rivera", "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=256&q=80", "u_1", "Alex Rivera", "", "current_user_101", "VIDEO", "CONNECTED", 342, System.currentTimeMillis() - 3600000 * 4),
            CallLogEntity("c_2", "room_elena", "Elena Rostova", "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=256&q=80", "current_user_101", "Sadman Shishir", "", "u_4", "VOICE", "CONNECTED", 128, System.currentTimeMillis() - 3600000 * 24)
        )
        callDao.insertCall(calls[0])
        callDao.insertCall(calls[1])
    }

    fun getAllRooms(): Flow<List<ChatRoom>> = database.chatRoomDao().getAllRooms().map { list ->
        list.map { it.toDomain() }
    }

    fun getDirectChats(): Flow<List<ChatRoom>> = database.chatRoomDao().getDirectChats().map { list ->
        list.map { it.toDomain() }
    }

    fun getGroupChannels(): Flow<List<ChatRoom>> = database.chatRoomDao().getGroupChannels().map { list ->
        list.map { it.toDomain() }
    }

    fun getMessages(roomId: String): Flow<List<Message>> = database.messageDao().getMessagesForRoom(roomId).map { list ->
        list.map { it.toDomain() }
    }

    fun getAllCalls(): Flow<List<CallSession>> = database.callLogDao().getAllCalls().map { list ->
        list.map { it.toDomain() }
    }

    fun getAllUsers(): Flow<List<User>> = database.userDao().getAllUsers().map { list ->
        list.map { it.toDomain() }
    }

    suspend fun sendMessage(
        roomId: String,
        content: String,
        type: MessageType = MessageType.TEXT,
        mediaUrl: String? = null,
        fileName: String? = null,
        fileSize: String? = null,
        audioDuration: Int = 0
    ) {
        val user = _currentUser.value
        val msgId = UUID.randomUUID().toString()
        val message = Message(
            id = msgId,
            roomId = roomId,
            senderId = user.id,
            senderName = user.name,
            senderAvatar = user.avatarUrl,
            content = content,
            type = type,
            mediaUrl = mediaUrl,
            fileName = fileName,
            fileSize = fileSize,
            audioDurationSeconds = audioDuration,
            isRead = true,
            isDeleted = false,
            reactions = emptyMap(),
            timestamp = System.currentTimeMillis()
        )

        // Save locally to Room
        database.messageDao().insertMessage(message.toEntity())
        database.chatRoomDao().updateLastMessage(roomId, content, message.timestamp, user.name)

        // Sync with Firebase Firestore
        scope.launch {
            firebaseManager.sendMessageToRemote(roomId, message)
        }
    }

    suspend fun deleteMessage(messageId: String) {
        database.messageDao().markMessageDeleted(messageId)
    }

    suspend fun reactToMessage(messageId: String, emoji: String) {
        // Toggle reaction
        val currentStr = "$emoji:1"
        database.messageDao().updateMessageReactions(messageId, currentStr)
    }

    suspend fun markRoomAsRead(roomId: String) {
        database.chatRoomDao().markRoomAsRead(roomId)
    }

    suspend fun createRoom(name: String, isGroup: Boolean, memberIds: List<String>, description: String = ""): String {
        val roomId = "room_" + UUID.randomUUID().toString().take(8)
        val newRoom = ChatRoom(
            id = roomId,
            name = name,
            isGroup = isGroup,
            avatarUrl = if (isGroup) "" else "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80",
            lastMessageText = "Channel created",
            lastMessageTime = System.currentTimeMillis(),
            lastMessageSenderName = _currentUser.value.name,
            unreadCount = 0,
            memberIds = memberIds + _currentUser.value.id,
            adminIds = listOf(_currentUser.value.id),
            description = description
        )

        database.chatRoomDao().insertRoom(newRoom.toEntity())
        scope.launch {
            firebaseManager.syncRoomToRemote(newRoom)
        }
        return roomId
    }

    suspend fun recordCall(session: CallSession) {
        database.callLogDao().insertCall(session.toEntity())
        scope.launch {
            firebaseManager.logCallToRemote(session)
        }
    }

    suspend fun updateCallState(callId: String, state: CallState, duration: Int) {
        database.callLogDao().updateCallStatus(callId, state.name, duration)
    }

    fun updateUserProfile(name: String, handle: String, status: UserStatus, statusMessage: String) {
        val updated = _currentUser.value.copy(
            name = name,
            handle = handle,
            status = status,
            statusMessage = statusMessage
        )
        _currentUser.value = updated
        scope.launch {
            firebaseManager.syncUserToRemote(updated)
        }
    }

    // Mapping extensions
    private fun ChatRoomEntity.toDomain() = ChatRoom(
        id = id,
        name = name,
        isGroup = isGroup,
        avatarUrl = avatarUrl,
        lastMessageText = lastMessageText,
        lastMessageTime = lastMessageTime,
        lastMessageSenderName = lastMessageSenderName,
        unreadCount = unreadCount,
        memberIds = memberIds.split(",").filter { it.isNotBlank() },
        adminIds = adminIds.split(",").filter { it.isNotBlank() },
        description = description
    )

    private fun ChatRoom.toEntity() = ChatRoomEntity(
        id = id,
        name = name,
        isGroup = isGroup,
        avatarUrl = avatarUrl,
        lastMessageText = lastMessageText,
        lastMessageTime = lastMessageTime,
        lastMessageSenderName = lastMessageSenderName,
        unreadCount = unreadCount,
        memberIds = memberIds.joinToString(","),
        adminIds = adminIds.joinToString(","),
        description = description
    )

    private fun MessageEntity.toDomain(): Message {
        val parsedReactions = mutableMapOf<String, Int>()
        if (reactions.isNotBlank()) {
            reactions.split(",").forEach { pair ->
                val parts = pair.split(":")
                if (parts.size == 2) {
                    parts[0].let { emoji -> parts[1].toIntOrNull()?.let { count -> parsedReactions[emoji] = count } }
                }
            }
        }
        return Message(
            id = id,
            roomId = roomId,
            senderId = senderId,
            senderName = senderName,
            senderAvatar = senderAvatar,
            content = content,
            type = try { MessageType.valueOf(type) } catch (_: Exception) { MessageType.TEXT },
            mediaUrl = mediaUrl,
            fileName = fileName,
            fileSize = fileSize,
            audioDurationSeconds = audioDurationSeconds,
            isRead = isRead,
            isDeleted = isDeleted,
            reactions = parsedReactions,
            timestamp = timestamp
        )
    }

    private fun Message.toEntity(): MessageEntity {
        val reactionStr = reactions.entries.joinToString(",") { "${it.key}:${it.value}" }
        return MessageEntity(
            id = id,
            roomId = roomId,
            senderId = senderId,
            senderName = senderName,
            senderAvatar = senderAvatar,
            content = content,
            type = type.name,
            mediaUrl = mediaUrl,
            fileName = fileName,
            fileSize = fileSize,
            audioDurationSeconds = audioDurationSeconds,
            isRead = isRead,
            isDeleted = isDeleted,
            reactions = reactionStr,
            timestamp = timestamp
        )
    }

    private fun CallLogEntity.toDomain() = CallSession(
        id = id,
        roomId = roomId,
        roomName = roomName,
        roomAvatar = roomAvatar,
        callerId = callerId,
        callerName = callerName,
        callerAvatar = callerAvatar,
        receiverId = receiverId,
        callType = try { CallType.valueOf(callType) } catch (_: Exception) { CallType.VIDEO },
        state = try { CallState.valueOf(state) } catch (_: Exception) { CallState.CONNECTED },
        durationSeconds = durationSeconds,
        timestamp = timestamp
    )

    private fun CallSession.toEntity() = CallLogEntity(
        id = id,
        roomId = roomId,
        roomName = roomName,
        roomAvatar = roomAvatar,
        callerId = callerId,
        callerName = callerName,
        callerAvatar = callerAvatar,
        receiverId = receiverId,
        callType = callType.name,
        state = state.name,
        durationSeconds = durationSeconds,
        timestamp = timestamp
    )

    private fun UserEntity.toDomain() = User(
        id = id,
        name = name,
        handle = handle,
        email = email,
        avatarUrl = avatarUrl,
        status = try { UserStatus.valueOf(status) } catch (_: Exception) { UserStatus.ONLINE },
        statusMessage = statusMessage,
        lastSeen = lastSeen
    )
}
