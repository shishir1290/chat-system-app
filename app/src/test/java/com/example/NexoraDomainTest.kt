package com.example

import com.example.domain.model.CallSession
import com.example.domain.model.CallState
import com.example.domain.model.CallType
import com.example.domain.model.ChatRoom
import com.example.domain.model.Message
import com.example.domain.model.MessageType
import com.example.domain.model.User
import com.example.domain.model.UserStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NexoraDomainTest {

    @Test
    fun testUserCreation() {
        val user = User(
            id = "u_test",
            name = "Sadman Shishir",
            handle = "@sadman",
            email = "sadman@example.com",
            status = UserStatus.ONLINE
        )
        assertEquals("Sadman Shishir", user.name)
        assertEquals(UserStatus.ONLINE, user.status)
        assertEquals("@sadman", user.handle)
    }

    @Test
    fun testMessageModel() {
        val message = Message(
            id = "m_1",
            roomId = "r_1",
            senderId = "u_1",
            senderName = "Alex Rivera",
            content = "Testing WebRTC P2P HD Calling",
            type = MessageType.TEXT,
            isRead = true
        )
        assertEquals("Testing WebRTC P2P HD Calling", message.content)
        assertTrue(message.isRead)
        assertFalse(message.isDeleted)
    }

    @Test
    fun testCallSessionModel() {
        val session = CallSession(
            id = "c_1",
            roomId = "r_1",
            roomName = "Alex Rivera",
            callerId = "u_1",
            callerName = "Alex",
            receiverId = "u_2",
            callType = CallType.VIDEO,
            state = CallState.CONNECTED,
            durationSeconds = 120
        )
        assertEquals(CallType.VIDEO, session.callType)
        assertEquals(CallState.CONNECTED, session.state)
        assertEquals(120, session.durationSeconds)
    }

    @Test
    fun testGroupChatRoomModel() {
        val room = ChatRoom(
            id = "room_gen",
            name = "#general",
            isGroup = true,
            memberIds = listOf("u_1", "u_2", "u_3"),
            adminIds = listOf("u_1")
        )
        assertTrue(room.isGroup)
        assertEquals(3, room.memberIds.size)
        assertEquals("#general", room.name)
    }
}
