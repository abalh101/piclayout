package com.example.piclayout

import android.Manifest
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingGallery: Pair<File, MethodChannel.Result>? = null
    private val packages = mapOf(
        "instagram" to listOf("com.instagram.android"),
        "snapchat" to listOf("com.snapchat.android"),
        "tiktok" to listOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill"),
        "whatsapp" to listOf("com.whatsapp", "com.whatsapp.w4b"),
        "facebook" to listOf("com.facebook.katana")
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "piclayout/media")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isInstalled" -> result.success(installedPackage(call.argument<String>("app")) != null)
                    "shareTo" -> {
                        val target = installedPackage(call.argument<String>("app"))
                        val file = File(call.argument<String>("path") ?: "")
                        if (target == null || !file.isFile) result.success(false)
                        else try {
                            val uri = FileProvider.getUriForFile(this, "$packageName.exports", file)
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = mime(file)
                                setPackage(target)
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("PicLayout", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) { result.success(false) }
                    }
                    "saveToGallery" -> {
                        val file = File(call.argument<String>("path") ?: "")
                        if (!file.isFile) result.error("file_missing", null, null)
                        else if (Build.VERSION.SDK_INT < 29 && checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                            if (pendingGallery != null) result.error("busy", null, null)
                            else {
                                pendingGallery = Pair(file, result)
                                requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 2401)
                            }
                        } else saveGallery(file, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installedPackage(app: String?): String? = packages[app]?.firstOrNull {
        try { packageManager.getPackageInfo(it, 0); true }
        catch (_: PackageManager.NameNotFoundException) { false }
    }
    private fun mime(file: File) = if (file.extension.lowercase() == "png") "image/png" else "image/jpeg"

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 2401) {
            val pending = pendingGallery ?: return
            pendingGallery = null
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) saveGallery(pending.first, pending.second)
            else pending.second.error("permission_denied", null, null)
        }
    }

    private fun saveGallery(file: File, result: MethodChannel.Result) {
        Thread {
            try {
                if (Build.VERSION.SDK_INT >= 29) {
                    val values = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, file.name)
                        put(MediaStore.Images.Media.MIME_TYPE, mime(file))
                        put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/PicLayout")
                        put(MediaStore.Images.Media.IS_PENDING, 1)
                    }
                    val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                        ?: throw IllegalStateException("Gallery unavailable")
                    try {
                        contentResolver.openOutputStream(uri)?.use { output -> file.inputStream().use { it.copyTo(output) } }
                            ?: throw IllegalStateException("Cannot open gallery")
                        values.clear()
                        values.put(MediaStore.Images.Media.IS_PENDING, 0)
                        if (contentResolver.update(uri, values, null, null) == 0) throw IllegalStateException("Cannot publish image")
                    } catch (error: Exception) {
                        contentResolver.delete(uri, null, null)
                        throw error
                    }
                    runOnUiThread { result.success(null) }
                } else {
                    if (Environment.getExternalStorageState() != Environment.MEDIA_MOUNTED) {
                        runOnUiThread { result.error("unavailable", null, null) }
                        return@Thread
                    }
                    val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "PicLayout")
                    directory.mkdirs()
                    val target = File(directory, "${System.nanoTime()}_${file.name}")
                    try { file.copyTo(target, overwrite = false) }
                    catch (error: Exception) { target.delete(); throw error }
                    MediaScannerConnection.scanFile(this, arrayOf(target.path), arrayOf(mime(file))) { _, uri ->
                        runOnUiThread {
                            if (uri != null) result.success(null)
                            else result.error("save_failed", null, null)
                        }
                    }
                }
            } catch (_: SecurityException) {
                runOnUiThread { result.error("permission_denied", null, null) }
            } catch (_: Exception) {
                runOnUiThread { result.error("save_failed", null, null) }
            }
        }.start()
    }
}
