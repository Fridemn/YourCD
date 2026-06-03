package com.example.your_cd

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private var pendingImageResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadSkills" -> loadSkills(result)
                    "saveSkills" -> saveSkills(call, result)
                    "pickImage" -> pickImage(result)
                    "requestNotifications" -> requestNotifications(result)
                    "scheduleNotification" -> scheduleNotification(call, result)
                    "cancelNotification" -> cancelNotification(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PICK_IMAGE_REQUEST) {
            val result = pendingImageResult ?: return
            pendingImageResult = null

            if (resultCode != RESULT_OK || data?.data == null) {
                result.success(null)
                return
            }

            try {
                result.success(copyPickedImage(data.data!!))
            } catch (error: Exception) {
                result.error("copy_failed", error.message, null)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun loadSkills(result: MethodChannel.Result) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        result.success(prefs.getString(SKILLS_KEY, "[]"))
    }

    private fun saveSkills(call: MethodCall, result: MethodChannel.Result) {
        val json = call.argument<String>("json") ?: "[]"
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(SKILLS_KEY, json)
            .apply()
        result.success(null)
    }

    private fun pickImage(result: MethodChannel.Result) {
        if (pendingImageResult != null) {
            result.error("busy", "Another image picker request is active.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        pendingImageResult = result
        try {
            startActivityForResult(intent, PICK_IMAGE_REQUEST)
        } catch (error: Exception) {
            pendingImageResult = null
            result.error("picker_unavailable", error.message, null)
        }
    }

    private fun requestNotifications(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST
            )
        }
        result.success(true)
    }

    private fun scheduleNotification(call: MethodCall, result: MethodChannel.Result) {
        val id = call.intArg("id")
        val title = call.argument<String>("title") ?: "YourCD"
        val body = call.argument<String>("body") ?: "CD ready"
        val triggerAt = call.longArg("triggerAtMillis")
        if (triggerAt <= System.currentTimeMillis()) {
            result.success(null)
            return
        }

        val intent = Intent(this, CooldownReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        result.success(null)
    }

    private fun cancelNotification(call: MethodCall, result: MethodChannel.Result) {
        val id = call.intArg("id")
        val intent = Intent(this, CooldownReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        result.success(null)
    }

    private fun copyPickedImage(uri: Uri): String {
        val mimeType = contentResolver.getType(uri)
        val extension = MimeTypeMap.getSingleton()
            .getExtensionFromMimeType(mimeType)
            ?.takeIf { it.isNotBlank() } ?: "jpg"
        val iconDir = File(filesDir, "skill_icons")
        if (!iconDir.exists()) {
            iconDir.mkdirs()
        }
        val target = File(iconDir, "skill_icon_${System.currentTimeMillis()}.$extension")
        val input = contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("Unable to open selected image.")

        input.use { source ->
            FileOutputStream(target).use { output ->
                source.copyTo(output)
            }
        }
        return target.absolutePath
    }

    private fun MethodCall.intArg(name: String, fallback: Int = 0): Int {
        return when (val value = argument<Any>(name)) {
            is Number -> value.toInt()
            is String -> value.toIntOrNull() ?: fallback
            else -> fallback
        }
    }

    private fun MethodCall.longArg(name: String, fallback: Long = 0L): Long {
        return when (val value = argument<Any>(name)) {
            is Number -> value.toLong()
            is String -> value.toLongOrNull() ?: fallback
            else -> fallback
        }
    }

    companion object {
        private const val CHANNEL_NAME = "your_cd/native"
        private const val PREFS_NAME = "your_cd_store"
        private const val SKILLS_KEY = "skills_json"
        private const val PICK_IMAGE_REQUEST = 7401
        private const val NOTIFICATION_PERMISSION_REQUEST = 7402
    }
}
