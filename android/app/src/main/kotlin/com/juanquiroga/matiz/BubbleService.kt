package com.juanquiroga.matiz

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import java.io.File
import kotlin.math.abs
import kotlin.math.hypot

/**
 * Burbuja flotante: servicio en primer plano (`specialUse` en reposo) con una vista superpuesta arrastrable.
 * Al tocarla se pide el consentimiento de captura (CaptureActivity) y, con él, se toma UNA instantánea
 * (`mediaProjection` solo durante la captura), se guarda en la caché y se abre en Matiz → modo Imagen.
 */
class BubbleService : Service() {
    private lateinit var wm: WindowManager
    private var bubble: View? = null
    private var dismiss: View? = null
    private lateinit var params: WindowManager.LayoutParams
    private val handler = Handler(Looper.getMainLooper())
    private var capturing = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running = true
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        createChannel()
        startIdleForeground()
        showBubble()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_CAPTURE -> {
                val code = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
                @Suppress("DEPRECATION")
                val data: Intent? = if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
                else intent.getParcelableExtra(EXTRA_RESULT_DATA)
                if (data != null) capture(code, data) else bubble?.visibility = View.VISIBLE
            }
            ACTION_CAPTURE_CANCELLED -> bubble?.visibility = View.VISIBLE
            ACTION_HIDE -> if (!capturing) bubble?.visibility = View.GONE
            ACTION_SHOW -> if (!capturing) bubble?.visibility = View.VISIBLE
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        bubble?.let { runCatching { wm.removeView(it) } }
        dismiss?.let { runCatching { wm.removeView(it) } }
        bubble = null
        dismiss = null
        super.onDestroy()
    }

    // ---------- Primer plano ----------

    private fun createChannel() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL, getString(R.string.bubble_channel), NotificationManager.IMPORTANCE_LOW)
        )
    }

    private fun notification(): Notification {
        val stop = PendingIntent.getService(
            this, 1, Intent(this, BubbleService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val open = PendingIntent.getActivity(
            this, 2, Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_matiz)
            .setContentTitle(getString(R.string.bubble_notification_title))
            .setContentText(getString(R.string.bubble_notification_text))
            .setContentIntent(open)
            .setOngoing(true)
            .addAction(Notification.Action.Builder(null, getString(R.string.bubble_stop), stop).build())
            .build()
    }

    private fun startIdleForeground() {
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification())
        }
    }

    private fun startCaptureForeground() {
        val type = if (Build.VERSION.SDK_INT >= 34)
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION or ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        else ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
        startForeground(NOTIFICATION_ID, notification(), type)
    }

    // ---------- Vista flotante ----------

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    @SuppressLint("ClickableViewAccessibility")
    private fun showBubble() {
        val size = dp(52)
        val view = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#F218181B"))
                setStroke(dp(2), Color.WHITE)
            }
            elevation = dp(6).toFloat()
            alpha = IDLE_ALPHA
            contentDescription = getString(R.string.bubble_content_description)
            addView(ImageView(context).apply {
                setImageResource(R.mipmap.ic_launcher)
                scaleType = ImageView.ScaleType.CENTER_CROP
            }, FrameLayout.LayoutParams(dp(36), dp(36), Gravity.CENTER))
        }
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        params = WindowManager.LayoutParams(
            size, size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = prefs.getInt("x", 0)
            y = prefs.getInt("y", dp(180))
        }

        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var dragging = false
        view.setOnTouchListener { v, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX; downY = e.rawY
                    startX = params.x; startY = params.y
                    dragging = false
                    v.alpha = 1f
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = e.rawX - downX
                    val dy = e.rawY - downY
                    if (!dragging && hypot(dx, dy) > dp(8)) {
                        dragging = true
                        showDismissTarget()
                    }
                    if (dragging) {
                        params.x = startX + dx.toInt()
                        params.y = startY + dy.toInt()
                        wm.updateViewLayout(v, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.alpha = IDLE_ALPHA
                    if (dragging) {
                        val overDismiss = isOverDismiss(e.rawX, e.rawY)
                        hideDismissTarget()
                        if (overDismiss) {
                            getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean("dismissed", true).apply()
                            stopSelf()
                        } else {
                            snapToEdge(v)
                        }
                    } else if (e.action == MotionEvent.ACTION_UP) {
                        requestCapture()
                    }
                    true
                }
                else -> false
            }
        }
        wm.addView(view, params)
        bubble = view
    }

    private fun screenSize(): Pair<Int, Int> {
        return if (Build.VERSION.SDK_INT >= 30) {
            val b = wm.currentWindowMetrics.bounds
            b.width() to b.height()
        } else {
            val m = DisplayMetrics()
            @Suppress("DEPRECATION")
            wm.defaultDisplay.getRealMetrics(m)
            m.widthPixels to m.heightPixels
        }
    }

    private fun snapToEdge(v: View) {
        val (w, h) = screenSize()
        params.x = if (params.x + v.width / 2 < w / 2) 0 else w - v.width
        params.y = params.y.coerceIn(0, h - v.height)
        wm.updateViewLayout(v, params)
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putInt("x", params.x).putInt("y", params.y).apply()
    }

    private fun showDismissTarget() {
        if (dismiss != null) return
        val view = TextView(this).apply {
            text = "✕"
            textSize = 22f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#CC000000"))
            }
        }
        val p = WindowManager.LayoutParams(
            dp(64), dp(64),
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = dp(72)
        }
        wm.addView(view, p)
        dismiss = view
    }

    private fun hideDismissTarget() {
        dismiss?.let { runCatching { wm.removeView(it) } }
        dismiss = null
    }

    private fun isOverDismiss(rawX: Float, rawY: Float): Boolean {
        val (w, h) = screenSize()
        val cx = w / 2f
        val cy = h - dp(72) - dp(32)
        return abs(rawX - cx) < dp(64) && abs(rawY - cy) < dp(64)
    }

    // ---------- Captura de un solo fotograma ----------

    private fun requestCapture() {
        if (capturing) return
        bubble?.visibility = View.GONE
        startActivity(Intent(this, CaptureActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun capture(resultCode: Int, data: Intent) {
        capturing = true
        try {
            startCaptureForeground()
        } catch (e: Exception) {
            finishCapture(null)
            return
        }
        // Espera a que la actividad de consentimiento desaparezca de la pantalla.
        handler.postDelayed({ grabFrame(resultCode, data) }, 400)
    }

    private fun grabFrame(resultCode: Int, data: Intent) {
        val mpm = getSystemService(MediaProjectionManager::class.java)
        val projection: MediaProjection = try {
            mpm.getMediaProjection(resultCode, data) ?: return finishCapture(null)
        } catch (e: Exception) {
            return finishCapture(null)
        }
        val (w, h) = screenSize()
        val dpi = resources.displayMetrics.densityDpi
        val reader = ImageReader.newInstance(w, h, PixelFormat.RGBA_8888, 2)
        var display: VirtualDisplay? = null
        var done = false

        fun cleanup() {
            runCatching { display?.release() }
            runCatching { reader.close() }
            runCatching { projection.stop() }
        }

        projection.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                if (!done) {
                    done = true
                    handler.post { finishCapture(null) }
                }
            }
        }, handler)

        reader.setOnImageAvailableListener({ r ->
            if (done) return@setOnImageAvailableListener
            val image = r.acquireLatestImage() ?: return@setOnImageAvailableListener
            done = true
            var path: String? = null
            try {
                val plane = image.planes[0]
                val pixelStride = plane.pixelStride
                val rowPadding = plane.rowStride - pixelStride * w
                val padded = Bitmap.createBitmap(w + rowPadding / pixelStride, h, Bitmap.Config.ARGB_8888)
                padded.copyPixelsFromBuffer(plane.buffer)
                val bmp = Bitmap.createBitmap(padded, 0, 0, w, h)
                val dir = File(cacheDir, "captures").apply { mkdirs() }
                dir.listFiles()?.forEach { it.delete() }
                val file = File(dir, "capture_${System.currentTimeMillis()}.png")
                file.outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
                path = file.absolutePath
                if (bmp !== padded) padded.recycle()
                bmp.recycle()
            } catch (e: Exception) {
                path = null
            } finally {
                image.close()
                cleanup()
            }
            finishCapture(path)
        }, handler)

        display = projection.createVirtualDisplay(
            "matiz-capture", w, h, dpi, DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            reader.surface, null, handler
        )
    }

    private fun finishCapture(path: String?) {
        capturing = false
        runCatching { startIdleForeground() }
        bubble?.visibility = View.VISIBLE
        if (path != null) {
            startActivity(
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    .putExtra(MainActivity.EXTRA_CAPTURE, path)
            )
        }
    }

    companion object {
        @Volatile
        var running = false
        const val ACTION_STOP = "matiz.bubble.STOP"
        const val ACTION_CAPTURE = "matiz.bubble.CAPTURE"
        const val ACTION_CAPTURE_CANCELLED = "matiz.bubble.CAPTURE_CANCELLED"
        const val ACTION_HIDE = "matiz.bubble.HIDE"
        const val ACTION_SHOW = "matiz.bubble.SHOW"
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_RESULT_DATA = "resultData"
        private const val CHANNEL = "matiz_bubble"
        private const val NOTIFICATION_ID = 4201
        private const val PREFS = "matiz_bubble"
        private const val IDLE_ALPHA = 0.8f
    }
}
