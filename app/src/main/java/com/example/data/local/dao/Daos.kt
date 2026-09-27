package com.example.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.data.local.entity.CallLogEntity
import com.example.data.local.entity.ChatRoomEntity
import com.example.data.local.entity.MessageEntity
import com.example.data.local.entity.UserEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {
    @Query("SELECT * FROM users ORDER BY name ASC")
    fun getAllUsers(): Flow<List<UserEntity>>

    @Query("SELECT * FROM users WHERE id = :userId")
    suspend fun getUserById(userId: String): UserEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<UserEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)

    @Update
    suspend fun updateUser(user: UserEntity)
}

@Dao
interface ChatRoomDao {
    @Query("SELECT * FROM chat_rooms ORDER BY lastMessageTime DESC")
    fun getAllRooms(): Flow<List<ChatRoomEntity>>

    @Query("SELECT * FROM chat_rooms WHERE isGroup = 0 ORDER BY lastMessageTime DESC")
    fun getDirectChats(): Flow<List<ChatRoomEntity>>

    @Query("SELECT * FROM chat_rooms WHERE isGroup = 1 ORDER BY lastMessageTime DESC")
    fun getGroupChannels(): Flow<List<ChatRoomEntity>>

    @Query("SELECT * FROM chat_rooms WHERE id = :roomId")
    suspend fun getRoomById(roomId: String): ChatRoomEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRoom(room: ChatRoomEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRooms(rooms: List<ChatRoomEntity>)

    @Query("UPDATE chat_rooms SET unreadCount = 0 WHERE id = :roomId")
    suspend fun markRoomAsRead(roomId: String)

    @Query("UPDATE chat_rooms SET lastMessageText = :text, lastMessageTime = :time, lastMessageSenderName = :sender WHERE id = :roomId")
    suspend fun updateLastMessage(roomId: String, text: String, time: Long, sender: String)
}

@Dao
interface MessageDao {
    @Query("SELECT * FROM messages WHERE roomId = :roomId ORDER BY timestamp ASC")
    fun getMessagesForRoom(roomId: String): Flow<List<MessageEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: MessageEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessages(messages: List<MessageEntity>)

    @Query("UPDATE messages SET isDeleted = 1, content = 'This message was deleted' WHERE id = :messageId")
    suspend fun markMessageDeleted(messageId: String)

    @Query("UPDATE messages SET reactions = :reactions WHERE id = :messageId")
    suspend fun updateMessageReactions(messageId: String, reactions: String)

    @Query("SELECT * FROM messages WHERE content LIKE '%' || :query || '%' AND isDeleted = 0 ORDER BY timestamp DESC")
    fun searchMessages(query: String): Flow<List<MessageEntity>>
}

@Dao
interface CallLogDao {
    @Query("SELECT * FROM call_logs ORDER BY timestamp DESC")
    fun getAllCalls(): Flow<List<CallLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCall(call: CallLogEntity)

    @Query("UPDATE call_logs SET state = :state, durationSeconds = :duration WHERE id = :callId")
    suspend fun updateCallStatus(callId: String, state: String, duration: Int)
}
