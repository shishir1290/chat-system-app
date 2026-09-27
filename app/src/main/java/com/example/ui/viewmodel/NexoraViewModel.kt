package com.example.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.data.remote.FirebaseSyncManager
import com.example.data.repository.NexoraRepository
import com.example.domain.model.CallSession
import com.example.domain.model.CallType
import com.example.domain.model.ChatRoom
import com.example.domain.model.Message
import com.example.domain.model.MessageType
import com.example.domain.model.User
import com.example.domain.model.UserStatus
import com.example.webrtc.WebRtcCallManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

enum class HomeTab {
    CHATS,
    CHANNELS,
    CALLS,
    PROFILE
}

class NexoraViewModel(
    private val repository: NexoraRepository,
    val callManager: WebRtcCallManager,
    val firebaseManager: FirebaseSyncManager
) : ViewModel() {

    private val _currentTab = MutableStateFlow(HomeTab.CHATS)
    val currentTab = _currentTab.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery = _searchQuery.asStateFlow()

    private val _activeRoomId = MutableStateFlow<String?>(null)
    val activeRoomId = _activeRoomId.asStateFlow()

    val currentUser: StateFlow<User> = repository.currentUser

    val allUsers: StateFlow<List<User>> = repository.getAllUsers()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allRooms: StateFlow<List<ChatRoom>> = repository.getAllRooms()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val directRooms: StateFlow<List<ChatRoom>> = repository.getDirectChats()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val groupChannels: StateFlow<List<ChatRoom>> = repository.getGroupChannels()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val callLogs: StateFlow<List<CallSession>> = repository.getAllCalls()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val activeMessages: StateFlow<List<Message>> = _activeRoomId.flatMapLatest { roomId ->
        if (roomId != null) repository.getMessages(roomId) else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val activeRoom: StateFlow<ChatRoom?> = combine(allRooms, _activeRoomId) { rooms, id ->
        rooms.firstOrNull { it.id == id }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    fun selectTab(tab: HomeTab) {
        _currentTab.value = tab
    }

    fun updateSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun openRoom(roomId: String) {
        _activeRoomId.value = roomId
        viewModelScope.launch {
            repository.markRoomAsRead(roomId)
        }
    }

    fun closeRoom() {
        _activeRoomId.value = null
    }

    fun sendMessage(
        content: String,
        type: MessageType = MessageType.TEXT,
        mediaUrl: String? = null,
        fileName: String? = null,
        fileSize: String? = null,
        audioDuration: Int = 0
    ) {
        val roomId = _activeRoomId.value ?: return
        if (content.isBlank() && mediaUrl == null) return

        viewModelScope.launch {
            repository.sendMessage(
                roomId = roomId,
                content = content,
                type = type,
                mediaUrl = mediaUrl,
                fileName = fileName,
                fileSize = fileSize,
                audioDuration = audioDuration
            )
        }
    }

    fun deleteMessage(messageId: String) {
        viewModelScope.launch {
            repository.deleteMessage(messageId)
        }
    }

    fun reactToMessage(messageId: String, emoji: String) {
        viewModelScope.launch {
            repository.reactToMessage(messageId, emoji)
        }
    }

    fun createChat(name: String, isGroup: Boolean, memberIds: List<String>, description: String = ""): String {
        var createdId = ""
        viewModelScope.launch {
            createdId = repository.createRoom(name, isGroup, memberIds, description)
            _activeRoomId.value = createdId
        }
        return createdId
    }

    fun startCall(room: ChatRoom, callType: CallType) {
        callManager.startCall(room, callType)
    }

    fun updateUserStatus(status: UserStatus) {
        val user = currentUser.value
        repository.updateUserProfile(user.name, user.handle, status, user.statusMessage)
    }

    fun updateProfile(name: String, handle: String, statusMessage: String) {
        val user = currentUser.value
        repository.updateUserProfile(name, handle, user.status, statusMessage)
    }

    class Factory(
        private val repository: NexoraRepository,
        private val callManager: WebRtcCallManager,
        private val firebaseManager: FirebaseSyncManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return NexoraViewModel(repository, callManager, firebaseManager) as T
        }
    }
}
