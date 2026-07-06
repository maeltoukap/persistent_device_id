package persistent_device_id.maeltoukap.me

import android.content.Context
import android.content.SharedPreferences
import android.media.MediaDrm
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.UUID

/** PersistentDeviceIdPlugin */
class PersistentDeviceIdPlugin() : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val prefKey = "device_id"
    private val encryptedPrefsName = "keystore_prefs"
    private val fallbackPrefsName = "persistent_device_id_fallback_prefs"
    private var deviceIdProvider: (() -> String?)? = null

    internal constructor(deviceIdProvider: () -> String?) : this() {
        this.deviceIdProvider = deviceIdProvider
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "persistent_device_id")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getDeviceId") {
            result.success(deviceIdProvider?.invoke() ?: getDeviceId())
        } else {
            result.notImplemented()
        }
    }

    private fun getDeviceId(): String? {
        val drmId = getMediaDrmId()
        return drmId ?: getOrCreateStoredId()
    }

    private fun getMediaDrmId(): String? {
        var mediaDrm: MediaDrm? = null
        return try {
            val widevineUUID = UUID(-0x121074568629b532L, -0x5c37d8232ae2de13L)
            mediaDrm = MediaDrm(widevineUUID)
            val deviceId = mediaDrm.getPropertyByteArray(MediaDrm.PROPERTY_DEVICE_UNIQUE_ID)
            Base64.encodeToString(deviceId, Base64.NO_WRAP).takeIf { it.isNotEmpty() }
        } catch (e: Exception) {
            null
        } finally {
            try {
                mediaDrm?.release()
            } catch (e: Exception) {
                // Ignore release failures; fallback storage remains available.
            }
        }
    }

    private fun getOrCreateStoredId(): String? {
        val fallbackPreferences = try {
            context.getSharedPreferences(fallbackPrefsName, Context.MODE_PRIVATE)
        } catch (e: Exception) {
            null
        }

        val encryptedPreferences = try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                context,
                encryptedPrefsName,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            null
        }

        return resolveStoredId(encryptedPreferences, fallbackPreferences)
    }

    internal fun resolveStoredId(
        encryptedPreferences: SharedPreferences?,
        fallbackPreferences: SharedPreferences?,
        idGenerator: () -> String = { UUID.randomUUID().toString() }
    ): String? {
        readStoredId(encryptedPreferences)?.let { return it }

        readStoredId(fallbackPreferences)?.let { fallbackId ->
            if (persistId(encryptedPreferences, fallbackId)) {
                deleteStoredId(fallbackPreferences)
            }
            return fallbackId
        }

        val generatedId = idGenerator()
        if (generatedId.isEmpty()) return null

        if (persistId(encryptedPreferences, generatedId)) return generatedId
        if (persistId(fallbackPreferences, generatedId)) return generatedId

        return null
    }

    private fun readStoredId(sharedPreferences: SharedPreferences?): String? {
        return try {
            sharedPreferences?.getString(prefKey, null)?.takeIf { it.isNotEmpty() }
        } catch (e: Exception) {
            null
        }
    }

    private fun persistId(sharedPreferences: SharedPreferences?, id: String): Boolean {
        return try {
            sharedPreferences
                ?.edit()
                ?.putString(prefKey, id)
                ?.commit() == true
        } catch (e: Exception) {
            false
        }
    }

    private fun deleteStoredId(sharedPreferences: SharedPreferences?): Boolean {
        return try {
            sharedPreferences
                ?.edit()
                ?.remove(prefKey)
                ?.commit() == true
        } catch (e: Exception) {
            false
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
