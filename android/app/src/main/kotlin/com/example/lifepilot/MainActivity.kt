package com.example.lifepilot

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lifepilot/spoken_reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val atMillis = call.argument<Long>("atMillis") ?: 0L
                        val text = call.argument<String>("text") ?: "LifePilot reminder"
                        scheduleSpokenReminder(id, atMillis, text)
                        result.success(null)
                    }
                    "cancel" -> {
                        val id = call.argument<Int>("id") ?: 0
                        cancelSpokenReminder(id)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lifepilot/secure_window")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun scheduleSpokenReminder(id: Int, atMillis: Long, text: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = spokenIntent(id, text)
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pendingIntent)
    }

    private fun cancelSpokenReminder(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(spokenIntent(id, ""))
    }

    private fun spokenIntent(id: Int, text: String): PendingIntent {
        val intent = Intent(this, SpokenReminderReceiver::class.java).putExtra("text", text)
        return PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
