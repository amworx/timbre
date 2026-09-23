package app.timbre.timbre

import android.app.Activity
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var pendingDelete: MethodChannel.Result? = null
    private var pendingUri: Uri? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "app.timbre.timbre/media"
        ).setMethodCallHandler { call, result ->
            if (call.method == "deleteMedia") {
                val raw = call.argument<String>("contentUri")
                if (raw.isNullOrBlank()) {
                    result.error("ARG", "Missing contentUri", null)
                } else {
                    deleteMedia(Uri.parse(raw), result)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    /// Deletes a MediaStore row. On Android 11+ the system owns the consent
    /// dialog: [MediaStore.createDeleteRequest] shows "Allow Timbre to delete
    /// this file?" and the outcome lands in [onActivityResult]. Older
    /// releases delete directly (no scoped-storage consent needed there).
    private fun deleteMedia(uri: Uri, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            pendingDelete = result
            pendingUri = uri
            try {
                val request = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
                startIntentSenderForResult(
                    request.intentSender, DELETE_REQUEST_CODE, null, 0, 0, 0, null
                )
            } catch (e: Exception) {
                pendingDelete = null
                pendingUri = null
                result.error("DELETE_FAILED", e.message, null)
            }
            return
        }
        try {
            result.success(contentResolver.delete(uri, null, null) > 0)
        } catch (e: Exception) {
            result.error("DELETE_FAILED", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != DELETE_REQUEST_CODE) return
        val result = pendingDelete
        val uri = pendingUri
        pendingDelete = null
        pendingUri = null
        if (result == null || uri == null) return
        if (resultCode == Activity.RESULT_OK) {
            try {
                // Consent granted; the row is gone (or was already gone).
                contentResolver.delete(uri, null, null)
                result.success(true)
            } catch (e: Exception) {
                result.error("DELETE_FAILED", e.message, null)
            }
        } else {
            // User denied the system dialog: nothing was deleted.
            result.success(false)
        }
    }

    companion object {
        private const val DELETE_REQUEST_CODE = 7301
    }
}
