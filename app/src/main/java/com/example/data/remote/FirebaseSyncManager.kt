package com.example.data.remote

import android.content.Context
import android.util.Log
import com.example.domain.model.CallSession
import com.example.domain.model.ChatRoom
import com.example.domain.model.Message
import com.example.domain.model.User
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

/**
 * Modular Remote Data Handler for Firebase Firestore.
 * Implements real-time listeners, bidirectional synchronization,
 * and offline-first fallback tolerance for educational demonstration.
 */
class FirebaseSyncManager(private val context: Context) {

    private val TAG = "NexoraFirebase"
    private var firestore: FirebaseFirestore? = null

    private val _isFirebaseReady = MutableStateFlow(false)
    val isFirebaseReady = _isFirebaseReady.asStateFlow()

    private val _syncStatus = MutableStateFlow("Initializing Firebase...")
    val syncStatus = _syncStatus.asStateFlow()

    private val _lastSyncedAt = MutableStateFlow<Long?>(null)
    val lastSyncedAt = _lastSyncedAt.asStateFlow()

    init {
        initializeFirebase()
    }

    private fun initializeFirebase() {
        try {
            val apps = FirebaseApp.getApps(context)
            if (apps.isNotEmpty()) {
                firestore = FirebaseFirestore.getInstance()
                _isFirebaseReady.value = true
                _syncStatus.value = "Connected to Firebase Firestore"
                Log.d(TAG, "Firebase initialized successfully.")
            } else {
                _isFirebaseReady.value = false
                _syncStatus.value = "Local-First Mode (google-services.json not configured)"
                Log.i(TAG, "FirebaseApp not initialized. Operating in local-first database mode.")
            }
        } catch (e: Exception) {
            _isFirebaseReady.value = false
            _syncStatus.value = "Local-First Fallback (${e.localizedMessage ?: "Offline"})"
            Log.w(TAG, "Firebase initialization notice: ${e.message}")
        }
    }

    suspend fun syncUserToRemote(user: User): Boolean {
        val db = firestore ?: return false
        return try {
            val userMap = hashMapOf(
                "id" to user.id,
                "name" to user.name,
                "handle" to user.handle,
                "email" to user.email,
                "avatarUrl" to user.avatarUrl,
                "status" to user.status.name,
                "statusMessage" to user.statusMessage,
                "lastSeen" to user.lastSeen
            )
            db.collection("users").document(user.id).set(userMap).await()
            _lastSyncedAt.value = System.currentTimeMillis()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sync user: ${e.message}")
            false
        }
    }

    suspend fun syncRoomToRemote(room: ChatRoom): Boolean {
        val db = firestore ?: return false
        return try {
            val roomMap = hashMapOf(
                "id" to room.id,
                "name" to room.name,
                "isGroup" to room.isGroup,
                "avatarUrl" to room.avatarUrl,
                "lastMessageText" to room.lastMessageText,
                "lastMessageTime" to room.lastMessageTime,
                "lastMessageSenderName" to room.lastMessageSenderName,
                "unreadCount" to room.unreadCount,
                "memberIds" to room.memberIds,
                "adminIds" to room.adminIds,
                "description" to room.description
            )
            db.collection("chat_rooms").document(room.id).set(roomMap).await()
            _lastSyncedAt.value = System.currentTimeMillis()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sync chat room: ${e.message}")
            false
        }
    }

    suspend fun sendMessageToRemote(roomId: String, message: Message): Boolean {
        val db = firestore ?: return false
        return try {
            val msgMap = hashMapOf(
                "id" to message.id,
                "roomId" to message.roomId,
                "senderId" to message.senderId,
                "senderName" to message.senderName,
                "senderAvatar" to message.senderAvatar,
                "content" to message.content,
                "type" to message.type.name,
                "mediaUrl" to (message.mediaUrl ?: ""),
                "fileName" to (message.fileName ?: ""),
                "fileSize" to (message.fileSize ?: ""),
                "audioDurationSeconds" to message.audioDurationSeconds,
                "isRead" to message.isRead,
                "isDeleted" to message.isDeleted,
                "reactions" to message.reactions,
                "timestamp" to message.timestamp
            )
            db.collection("chat_rooms").document(roomId)
                .collection("messages").document(message.id).set(msgMap).await()

            // Update parent room's last message
            db.collection("chat_rooms").document(roomId).update(
                mapOf(
                    "lastMessageText" to message.content,
                    "lastMessageTime" to message.timestamp,
                    "lastMessageSenderName" to message.senderName
                )
            ).await()

            _lastSyncedAt.value = System.currentTimeMillis()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send message to Firebase: ${e.message}")
            false
        }
    }

    suspend fun logCallToRemote(session: CallSession): Boolean {
        val db = firestore ?: return false
        return try {
            val callMap = hashMapOf(
                "id" to session.id,
                "roomId" to session.roomId,
                "roomName" to session.roomName,
                "callerId" to session.callerId,
                "callerName" to session.callerName,
                "receiverId" to session.receiverId,
                "callType" to session.callType.name,
                "state" to session.state.name,
                "durationSeconds" to session.durationSeconds,
                "timestamp" to session.timestamp
            )
            db.collection("call_sessions").document(session.id).set(callMap).await()
            _lastSyncedAt.value = System.currentTimeMillis()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to log call: ${e.message}")
            false
        }
    }

    /**
     * Real-time Firebase Flow stream for chat messages
     */
    fun observeRemoteMessages(roomId: String): Flow<List<Message>> = callbackFlow {
        val db = firestore
        if (db == null) {
            trySend(emptyList())
            close()
            return@callbackFlow
        }

        val listener: ListenerRegistration = db.collection("chat_rooms")
            .document(roomId)
            .collection("messages")
            .orderBy("timestamp", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.w(TAG, "Firestore message listen failed: ${error.message}")
                    return@addSnapshotListener
                }
                if (snapshot != null) {
                    val messages = snapshot.documents.mapNotNull { doc ->
                        try {
                            Message(
                                id = doc.getString("id") ?: doc.id,
                                roomId = doc.getString("roomId") ?: roomId,
                                senderId = doc.getString("senderId") ?: "",
                                senderName = doc.getString("senderName") ?: "",
                                senderAvatar = doc.getString("senderAvatar") ?: "",
                                content = doc.getString("content") ?: "",
                                type = try {
                                    com.example.domain.model.MessageType.valueOf(doc.getString("type") ?: "TEXT")
                                } catch (_: Exception) { com.example.domain.model.MessageType.TEXT },
                                mediaUrl = doc.getString("mediaUrl"),
                                fileName = doc.getString("fileName"),
                                fileSize = doc.getString("fileSize"),
                                audioDurationSeconds = (doc.getLong("audioDurationSeconds") ?: 0L).toInt(),
                                isRead = doc.getBoolean("isRead") ?: true,
                                isDeleted = doc.getBoolean("isDeleted") ?: false,
                                reactions = emptyMap(),
                                timestamp = doc.getLong("timestamp") ?: System.currentTimeMillis()
                            )
                        } catch (e: Exception) {
                            null
                        }
                    }
                    trySend(messages)
                    _lastSyncedAt.value = System.currentTimeMillis()
                }
            }

        awaitClose { listener.remove() }
    }
}
