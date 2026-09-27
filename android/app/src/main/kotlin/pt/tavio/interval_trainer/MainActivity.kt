package pt.tavio.interval_trainer

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WorkoutService.CHANNEL)
        WorkoutService.channel = channel

        // Voice cues: native TTS with audio focus + ducking (see Speaker.kt).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "interval_trainer/voice")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "init" -> {
                        Speaker.init(this)
                        Speaker.setLanguage(call.argument<String>("lang") ?: "en")
                        result.success(null)
                    }
                    "speak" -> {
                        Speaker.init(this)
                        Speaker.speak(call.argument<String>("text") ?: "")
                        result.success(null)
                    }
                    "stop" -> {
                        Speaker.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val intent = Intent(this, WorkoutService::class.java).apply {
                        action = WorkoutService.ACTION_START
                        putExtra("title", call.argument<String>("title") ?: "")
                        putExtra("text", call.argument<String>("text") ?: "")
                        putExtra("endAt", call.argument<Number>("endAt")?.toLong() ?: 0L)
                        putExtra("paused", call.argument<Boolean>("paused") ?: false)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "update" -> {
                    WorkoutService.instance?.update(
                        call.argument<String>("title") ?: "",
                        call.argument<String>("text") ?: "",
                        call.argument<Number>("endAt")?.toLong() ?: 0L,
                        call.argument<Boolean>("paused") ?: false,
                    )
                    result.success(null)
                }
                "stop" -> {
                    stopService(Intent(this, WorkoutService::class.java))
                    result.success(null)
                }
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                        PackageManager.PERMISSION_GRANTED
                    ) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        // If the app is closed for good, don't leave the service running.
        if (isFinishing) {
            stopService(Intent(this, WorkoutService::class.java))
            WorkoutService.channel = null
        }
        super.onDestroy()
    }
}
