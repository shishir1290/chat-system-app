package com.example

import android.app.Application
import com.example.data.local.NexoraDatabase
import com.example.data.remote.FirebaseSyncManager
import com.example.data.repository.NexoraRepository
import com.example.webrtc.WebRtcCallManager

class NexoraApplication : Application() {

    lateinit var database: NexoraDatabase
        private set

    lateinit var firebaseManager: FirebaseSyncManager
        private set

    lateinit var repository: NexoraRepository
        private set

    lateinit var callManager: WebRtcCallManager
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this

        database = NexoraDatabase.getInstance(this)
        firebaseManager = FirebaseSyncManager(this)
        repository = NexoraRepository(database, firebaseManager)
        callManager = WebRtcCallManager(this, repository)
    }

    companion object {
        lateinit var instance: NexoraApplication
            private set
    }
}
