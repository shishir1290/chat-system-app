package com.example.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.example.data.local.dao.CallLogDao
import com.example.data.local.dao.ChatRoomDao
import com.example.data.local.dao.MessageDao
import com.example.data.local.dao.UserDao
import com.example.data.local.entity.CallLogEntity
import com.example.data.local.entity.ChatRoomEntity
import com.example.data.local.entity.MessageEntity
import com.example.data.local.entity.UserEntity

@Database(
    entities = [
        UserEntity::class,
        ChatRoomEntity::class,
        MessageEntity::class,
        CallLogEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class NexoraDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun chatRoomDao(): ChatRoomDao
    abstract fun messageDao(): MessageDao
    abstract fun callLogDao(): CallLogDao

    companion object {
        @Volatile
        private var INSTANCE: NexoraDatabase? = null

        fun getInstance(context: Context): NexoraDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    NexoraDatabase::class.java,
                    "nexora_chat.db"
                ).fallbackToDestructiveMigration().build()
                INSTANCE = instance
                instance
            }
        }
    }
}
