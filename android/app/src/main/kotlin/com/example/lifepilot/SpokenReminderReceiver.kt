package com.example.lifepilot

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.speech.tts.TextToSpeech
import java.util.Locale

class SpokenReminderReceiver : BroadcastReceiver(), TextToSpeech.OnInitListener {
    private var tts: TextToSpeech? = null
    private var text: String = "LifePilot reminder"

    override fun onReceive(context: Context, intent: Intent) {
        text = intent.getStringExtra("text") ?: text
        tts = TextToSpeech(context.applicationContext, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale.getDefault()
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "lifepilot-spoken-reminder")
        }
    }
}
