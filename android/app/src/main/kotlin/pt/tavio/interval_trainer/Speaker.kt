package pt.tavio.interval_trainer

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale

/**
 * Speaks the voice cues over other audio (YouTube, Spotify…), like a GPS app:
 * it asks Android for temporary audio focus with "duck", so the music gets
 * quieter while the voice speaks and comes back right after.
 */
object Speaker {
    private var tts: TextToSpeech? = null
    private var ready = false
    private var lang = "en"
    private var pendingText: String? = null
    private var am: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var hasFocus = false
    private var counter = 0
    private val main = Handler(Looper.getMainLooper())
    private val releaseFocus = Runnable { abandonFocus() }

    // Same kind of audio as navigation directions: mixes over music.
    private val attrs: AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()

    fun init(ctx: Context) {
        if (tts != null) return
        val app = ctx.applicationContext
        am = app.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        tts = TextToSpeech(app) { status ->
            main.post { onReady(status == TextToSpeech.SUCCESS) }
        }
    }

    private fun onReady(ok: Boolean) {
        ready = ok
        val t = tts ?: return
        if (!ok) return
        t.setAudioAttributes(attrs)
        t.setSpeechRate(1.0f)
        t.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) = scheduleRelease()
            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) = scheduleRelease()
        })
        applyLanguage()
        pendingText?.let { speak(it) }
        pendingText = null
    }

    fun setLanguage(code: String) {
        lang = code
        if (ready) applyLanguage()
    }

    private fun applyLanguage() {
        val t = tts ?: return
        val candidates = if (lang == "pt") {
            listOf("pt-PT", "pt-BR", "pt")
        } else {
            listOf("en-US", "en-GB", "en")
        }
        for (tag in candidates) {
            val loc = Locale.forLanguageTag(tag)
            if (t.isLanguageAvailable(loc) >= TextToSpeech.LANG_AVAILABLE) {
                t.language = loc
                return
            }
        }
    }

    fun speak(text: String) {
        if (text.isBlank()) return
        val t = tts
        if (t == null || !ready) {
            pendingText = text // spoken as soon as the engine is ready
            return
        }
        main.removeCallbacks(releaseFocus)
        requestFocus()
        t.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), "cue${counter++}")
    }

    fun stop() {
        tts?.stop()
        main.removeCallbacks(releaseFocus)
        abandonFocus()
    }

    // Keep focus a moment after speaking so the music doesn't bounce
    // up and down during the 5-4-3-2-1 countdown.
    private fun scheduleRelease() {
        main.removeCallbacks(releaseFocus)
        main.postDelayed(releaseFocus, 700)
    }

    @Suppress("DEPRECATION")
    private fun requestFocus() {
        if (hasFocus) return
        val a = am ?: return
        hasFocus = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = focusRequest ?: AudioFocusRequest
                .Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attrs)
                .build()
                .also { focusRequest = it }
            a.requestAudioFocus(req) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            a.requestAudioFocus(
                null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    @Suppress("DEPRECATION")
    private fun abandonFocus() {
        if (!hasFocus) return
        val a = am ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { a.abandonAudioFocusRequest(it) }
        } else {
            a.abandonAudioFocus(null)
        }
        hasFocus = false
    }
}
