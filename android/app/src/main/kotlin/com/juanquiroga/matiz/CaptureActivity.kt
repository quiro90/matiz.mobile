package com.juanquiroga.matiz

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle

/**
 * Actividad transparente que solo pide el consentimiento de captura de pantalla del sistema y
 * entrega el resultado a [BubbleService]. Se cierra de inmediato para no aparecer en la instantánea.
 */
class CaptureActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val mpm = getSystemService(MediaProjectionManager::class.java)
        val intent = if (Build.VERSION.SDK_INT >= 34)
            mpm.createScreenCaptureIntent(MediaProjectionConfig.createConfigForDefaultDisplay())
        else mpm.createScreenCaptureIntent()
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQ_CAPTURE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_CAPTURE && resultCode == RESULT_OK && data != null) {
            startService(
                Intent(this, BubbleService::class.java)
                    .setAction(BubbleService.ACTION_CAPTURE)
                    .putExtra(BubbleService.EXTRA_RESULT_CODE, resultCode)
                    .putExtra(BubbleService.EXTRA_RESULT_DATA, data)
            )
        } else {
            startService(Intent(this, BubbleService::class.java).setAction(BubbleService.ACTION_CAPTURE_CANCELLED))
        }
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    companion object {
        private const val REQ_CAPTURE = 7201
    }
}
