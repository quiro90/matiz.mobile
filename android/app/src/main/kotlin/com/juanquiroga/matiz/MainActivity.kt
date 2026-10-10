package com.juanquiroga.matiz

import android.Manifest
import android.app.LocaleManager
import android.content.ClipboardManager
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.LocaleList
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Actividad principal. Expone el canal `matiz/platform` (contenido entrante, portapapeles de imágenes,
 * galería, idioma por app y burbuja) y el canal de eventos `matiz/incoming`.
 */
class MainActivity : FlutterActivity() {
    private var initialContent: Map<String, Any?>? = null
    private var events: EventChannel.EventSink? = null
    private var pendingOverlay: MethodChannel.Result? = null
    private var pendingNotifications: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Solo el intent original; una recreación (p. ej. rotación) no lo vuelve a procesar.
        if (savedInstanceState == null) initialContent = readIncoming(intent)
    }

    override fun onResume() {
        super.onResume()
        bubbleVisibility(false)
    }

    override fun onPause() {
        super.onPause()
        bubbleVisibility(true)
    }

    /** La burbuja no tiene sentido sobre la propia Matiz: se oculta mientras está en primer plano. */
    private fun bubbleVisibility(visible: Boolean) {
        if (!BubbleService.running) return
        runCatching {
            startService(Intent(this, BubbleService::class.java)
                .setAction(if (visible) BubbleService.ACTION_SHOW else BubbleService.ACTION_HIDE))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val content = readIncoming(intent)
        Log.i(TAG, "onNewIntent action=${intent.action} content=${content != null} listener=${events != null}")
        if (content == null) return
        val sink = events
        if (sink != null) sink.success(content) else initialContent = content
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "matiz/incoming").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                events = sink
            }

            override fun onCancel(arguments: Any?) {
                events = null
            }
        })
        MethodChannel(messenger, "matiz/platform").setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialContent" -> {
                    result.success(initialContent)
                    initialContent = null
                }
                "getClipboardImage" -> result.success(readClipboardImage())
                "saveToGallery" -> result.success(
                    saveToGallery(call.argument<ByteArray>("bytes")!!, call.argument<String>("name") ?: "matiz.png")
                )
                "setAppLocale" -> {
                    setAppLocale(call.argument<String>("tag") ?: "")
                    result.success(null)
                }
                "openAppSettings" -> {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null)))
                    result.success(null)
                }
                "canDrawOverlays" -> result.success(Settings.canDrawOverlays(this))
                "requestOverlayPermission" -> {
                    if (Settings.canDrawOverlays(this)) {
                        result.success(true)
                    } else {
                        pendingOverlay = result
                        @Suppress("DEPRECATION")
                        startActivityForResult(
                            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")),
                            REQ_OVERLAY
                        )
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT < 33 ||
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    ) {
                        result.success(true)
                    } else {
                        pendingNotifications = result
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_NOTIFICATIONS)
                    }
                }
                "startBubble" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        result.success(false)
                    } else {
                        startForegroundService(Intent(this, BubbleService::class.java))
                        result.success(true)
                    }
                }
                "stopBubble" -> {
                    stopService(Intent(this, BubbleService::class.java))
                    result.success(null)
                }
                "isBubbleRunning" -> result.success(BubbleService.running)
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_OVERLAY) {
            pendingOverlay?.success(Settings.canDrawOverlays(this))
            pendingOverlay = null
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_NOTIFICATIONS) {
            pendingNotifications?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
            pendingNotifications = null
        }
    }

    // ---------- Contenido entrante ----------

    private fun readIncoming(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        intent.getStringExtra(EXTRA_CAPTURE)?.let { path ->
            intent.removeExtra(EXTRA_CAPTURE)
            return mapOf("path" to path, "mime" to "image/png", "name" to File(path).name, "kind" to "capture", "count" to 1)
        }
        val uris: List<Uri> = when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(streamExtra(intent))
            Intent.ACTION_SEND_MULTIPLE -> streamListExtra(intent)
            Intent.ACTION_VIEW -> listOfNotNull(intent.data)
            else -> emptyList()
        }
        val uri = uris.firstOrNull() ?: return null
        return try {
            val name = displayName(uri) ?: "incoming"
            val dir = File(cacheDir, "incoming").apply { mkdirs() }
            dir.listFiles()?.forEach { it.delete() }
            val target = File(dir, "${System.currentTimeMillis()}_${name.replace(Regex("[^A-Za-z0-9._-]"), "_")}")
            contentResolver.openInputStream(uri)?.use { input -> target.outputStream().use { input.copyTo(it) } }
                ?: return null
            mapOf(
                "path" to target.absolutePath,
                "mime" to (intent.type ?: contentResolver.getType(uri)),
                "name" to name,
                "kind" to if (intent.action == Intent.ACTION_VIEW) "view" else "share",
                "count" to uris.size,
            )
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo leer el contenido recibido: $uri", e)
            null
        }
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableExtra(Intent.EXTRA_STREAM)

    @Suppress("DEPRECATION")
    private fun streamListExtra(intent: Intent): List<Uri> =
        (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)) ?: emptyList()

    private fun displayName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        return try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) c.getString(0) else null
            }
        } catch (e: Exception) {
            null
        }
    }

    // ---------- Portapapeles y galería ----------

    private fun readClipboardImage(): ByteArray? {
        val cm = getSystemService(ClipboardManager::class.java) ?: return null
        val clip = cm.primaryClip ?: return null
        if (clip.itemCount == 0) return null
        val uri = clip.getItemAt(0).uri ?: return null
        val type = contentResolver.getType(uri) ?: clip.description.getMimeType(0)
        if (type == null || !type.startsWith("image/")) return null
        return try {
            contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (e: Exception) {
            null
        }
    }

    private fun saveToGallery(bytes: ByteArray, name: String): Boolean {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Matiz")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
        return try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: return false
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            true
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            false
        }
    }

    private fun setAppLocale(tag: String) {
        if (Build.VERSION.SDK_INT < 33) return
        getSystemService(LocaleManager::class.java)?.applicationLocales =
            if (tag.isEmpty()) LocaleList.getEmptyLocaleList() else LocaleList.forLanguageTags(tag)
    }

    companion object {
        const val EXTRA_CAPTURE = "matiz.capture"
        private const val TAG = "Matiz"
        private const val REQ_OVERLAY = 7101
        private const val REQ_NOTIFICATIONS = 7102
    }
}
