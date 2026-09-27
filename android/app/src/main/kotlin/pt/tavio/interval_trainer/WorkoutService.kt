package pt.tavio.interval_trainer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.widget.RemoteViews
import io.flutter.plugin.common.MethodChannel

/**
 * Foreground service that keeps the app process (and the Dart timer) alive
 * while the screen is locked or another app is open. It shows an ongoing
 * notification with a live countdown and Pause / Skip / Stop buttons.
 */
class WorkoutService : Service() {

    companion object {
        const val CHANNEL = "interval_trainer/service"
        const val ACTION_START = "pt.tavio.interval_trainer.START"
        const val ACTION_PAUSE = "pt.tavio.interval_trainer.PAUSE"
        const val ACTION_SKIP = "pt.tavio.interval_trainer.SKIP"
        const val ACTION_STOP = "pt.tavio.interval_trainer.STOP"
        // v2: channel settings can't change after creation, so a new id is used.
        private const val NOTIF_CHANNEL = "workout_v2"
        private const val NOTIF_ID = 4201
        private const val MAX_WAKE_MS = 4L * 60 * 60 * 1000 // safety cap: 4 hours

        @Volatile var channel: MethodChannel? = null
        @Volatile var instance: WorkoutService? = null
    }

    private val main = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var title = "Interval Trainer"
    private var text = ""
    private var endAt = 0L
    private var paused = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createChannel()
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "IntervalTrainer::workout").apply {
            setReferenceCounted(false)
            acquire(MAX_WAKE_MS)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PAUSE -> sendToDart("pause")
            ACTION_SKIP -> sendToDart("skip")
            ACTION_STOP -> sendToDart("stop")
            else -> {
                if (intent != null) {
                    title = intent.getStringExtra("title") ?: title
                    text = intent.getStringExtra("text") ?: text
                    endAt = intent.getLongExtra("endAt", 0L)
                    paused = intent.getBooleanExtra("paused", false)
                }
                goForeground()
            }
        }
        return START_NOT_STICKY
    }

    fun update(title: String, text: String, endAt: Long, paused: Boolean) {
        this.title = title
        this.text = text
        this.endAt = endAt
        this.paused = paused
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, build())
    }

    private fun goForeground() {
        val n = build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    private fun sendToDart(action: String) {
        main.post { channel?.invokeMethod("action", action) }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // DEFAULT importance (not LOW) so the notification is shown on the
            // lock screen; sound and vibration are off because the app speaks
            // and vibrates on its own.
            val ch = NotificationChannel(
                NOTIF_CHANNEL, "Workout in progress", NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Shows the running workout timer"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.deleteNotificationChannel("workout") // old, silent channel
            nm.createNotificationChannel(ch)
        }
    }

    private fun piFlags(): Int {
        var f = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) f = f or PendingIntent.FLAG_IMMUTABLE
        return f
    }

    private fun actionIntent(action: String, code: Int): PendingIntent =
        PendingIntent.getService(
            this, code, Intent(this, WorkoutService::class.java).setAction(action), piFlags()
        )

    @Suppress("DEPRECATION")
    private fun build(): Notification {
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIF_CHANNEL)
        } else {
            Notification.Builder(this)
        }

        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        if (launch != null) {
            b.setContentIntent(PendingIntent.getActivity(this, 0, launch, piFlags()))
        }

        b.setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setVisibility(Notification.VISIBILITY_PUBLIC)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Custom layout with a BIG countdown. The Chronometer is drawn by
            // Android itself, so it keeps ticking with no per-second updates.
            b.setStyle(Notification.DecoratedCustomViewStyle())
            b.setCustomContentView(timerViews(R.layout.notification_timer))
            b.setCustomBigContentView(timerViews(R.layout.notification_timer_big))
            b.setShowWhen(false)
        } else if (!paused && endAt > 0) {
            b.setUsesChronometer(true)
            b.setWhen(endAt)
        }

        b.addAction(
            if (paused) android.R.drawable.ic_media_play else android.R.drawable.ic_media_pause,
            if (paused) "Resume" else "Pause",
            actionIntent(ACTION_PAUSE, 1)
        )
        b.addAction(android.R.drawable.ic_media_next, "Skip", actionIntent(ACTION_SKIP, 2))
        b.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", actionIntent(ACTION_STOP, 3))

        return b.build()
    }

    /** Fills a timer layout. The chronometer base uses the monotonic clock. */
    private fun timerViews(layout: Int): RemoteViews {
        val v = RemoteViews(packageName, layout)
        val remainingMs = if (endAt > 0) (endAt - System.currentTimeMillis()).coerceAtLeast(0) else 0L
        val base = SystemClock.elapsedRealtime() + remainingMs
        v.setTextViewText(R.id.nt_title, title)
        v.setTextViewText(R.id.nt_text, text)
        v.setChronometer(R.id.nt_timer, base, null, !paused)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            v.setChronometerCountDown(R.id.nt_timer, true)
        }
        return v
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // App swiped away from recents: the timer is gone, so stop too.
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    @Suppress("DEPRECATION")
    override fun onDestroy() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
        instance = null
        super.onDestroy()
    }
}
