package com.example.netflix_clone

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.netflix_clone/cast"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openCastSettings") {
                var launched = false
                val intentActions = listOf(
                    "android.settings.CAST_SETTINGS",
                    "android.settings.WIFI_DISPLAY_SETTINGS",
                    Settings.ACTION_WIRELESS_SETTINGS
                )
                for (action in intentActions) {
                    try {
                        val intent = Intent(action)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        launched = true
                        break
                    } catch (e: Exception) {
                        // try next action
                    }
                }
                if (launched) {
                    result.success(true)
                } else {
                    result.error("UNAVAILABLE", "Cannot open cast settings", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
