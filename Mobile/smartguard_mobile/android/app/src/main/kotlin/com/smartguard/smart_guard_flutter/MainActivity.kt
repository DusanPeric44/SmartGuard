package com.smartguard.smart_guard_flutter

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "smartguard/archive_downloader"
    private val tag = "ArchiveDownloader"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            if (call.method != "downloadToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")
            val fileName = call.argument<String>("fileName")
            val headers = call.argument<HashMap<String, String>>("headers")
            if (url.isNullOrBlank() || fileName.isNullOrBlank()) {
                result.error("invalid_args", "url and fileName are required", null)
                return@setMethodCallHandler
            }

            try {
                val id = enqueueDownload(url, fileName, headers)
                Log.d(tag, "Enqueued download id=$id url=$url fileName=$fileName")
                result.success(null)
            } catch (e: Exception) {
                Log.e(tag, "Download enqueue failed", e)
                result.error("download_failed", e.message, null)
            }
        }
    }

    private fun enqueueDownload(
        url: String,
        fileName: String,
        headers: HashMap<String, String>?
    ): Long {
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(fileName)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)

        if (headers != null) {
            for ((k, v) in headers) {
                if (k.isNotBlank() && v.isNotBlank()) {
                    request.addRequestHeader(k, v)
                }
            }
        }

        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        return manager.enqueue(request)
    }
}
