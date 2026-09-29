package com.nexora.chat.nexora_chat

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nexora.chat/lockscreen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableCallLockScreenMode" -> {
                    enableCallLockScreenMode()
                    result.success(true)
                }
                "disableCallLockScreenMode" -> {
                    disableCallLockScreenMode()
                    result.success(true)
                }
                "isKeyguardLocked" -> {
                    val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    result.success(km?.isKeyguardLocked ?: false)
                }
                "requestDismissKeyguard" -> {
                    val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && km != null) {
                        km.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                            override fun onDismissSucceeded() {
                                result.success(true)
                            }
                            override fun onDismissError() {
                                result.success(false)
                            }
                            override fun onDismissCancelled() {
                                result.success(false)
                            }
                        })
                    } else {
                        result.success(false)
                    }
                }
                "exitLockScreenIfLocked" -> {
                    val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    val isLocked = km?.isKeyguardLocked ?: false
                    if (isLocked) {
                        disableCallLockScreenMode()
                        moveTaskToBack(true)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enableCallLockScreenMode() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else {
                @Suppress("DEPRECATION")
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                )
            }
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun disableCallLockScreenMode() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(false)
                setTurnScreenOn(false)
            } else {
                @Suppress("DEPRECATION")
                window.clearFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                )
            }
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }
}
