package persistent_device_id.maeltoukap.me

import android.content.Context
import android.media.MediaDrm
import android.os.Build
import android.util.Base64
import androidx.annotation.NonNull
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class PersistentDeviceIdPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val PREF_KEY = "device_id"

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "persistent_device_id")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        if (call.method == "getDeviceId") {
            result.success(getDeviceId())
        } else {
            result.notImplemented()
        }
    }

    private fun getDeviceId(): String {
        val drmId = getMediaDrmId()
        return drmId ?: getOrCreateStoredId()
    }

    private fun getMediaDrmId(): String? {
        return try {
            val widevineUUID = UUID(-0x121074568629b532L, -0x5c37d8232ae2de13L)
            val mediaDrm = MediaDrm(widevineUUID)
            val deviceId = mediaDrm.getPropertyByteArray(MediaDrm.PROPERTY_DEVICE_UNIQUE_ID)
            mediaDrm.release()
            Base64.encodeToString(deviceId, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }

    private fun getOrCreateStoredId(): String {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        val sharedPreferences = EncryptedSharedPreferences.create(
            context,
            "keystore_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )

        val existingId = sharedPreferences.getString(PREF_KEY, null)
        if (existingId != null) {
            return existingId
        }

        val uuid = UUID.randomUUID().toString()
        sharedPreferences.edit().putString(PREF_KEY, uuid).apply()
        return uuid
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
