package persistent_device_id.maeltoukap.me

import android.content.SharedPreferences
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import org.mockito.Mockito

internal class PersistentDeviceIdPluginTest {
    @Test
    fun onMethodCall_getDeviceId_returnsExpectedValue() {
        val plugin = PersistentDeviceIdPlugin { "test-device-id" }
        val call = MethodCall("getDeviceId", null)
        val result: Result = Mockito.mock(Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).success("test-device-id")
    }

    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        val plugin = PersistentDeviceIdPlugin { "test-device-id" }
        val call = MethodCall("unknownMethod", null)
        val result: Result = Mockito.mock(Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).notImplemented()
    }

    @Test
    fun resolveStoredId_regeneratesEmptyStoredValue() {
        val encrypted = mockPreferences(existingId = "", commitResult = true)
        val fallback = mockPreferences(existingId = null, commitResult = true)
        val plugin = PersistentDeviceIdPlugin()

        val result = plugin.resolveStoredId(encrypted.preferences, fallback.preferences) {
            "generated-id"
        }

        assertEquals("generated-id", result)
        Mockito.verify(encrypted.editor).putString("device_id", "generated-id")
        Mockito.verify(encrypted.editor).commit()
        Mockito.verifyNoInteractions(fallback.editor)
    }

    @Test
    fun resolveStoredId_recoversFromCorruptedEncryptedValue() {
        val encrypted = mockPreferences(
            existingId = null,
            commitResult = true,
            readFailure = ClassCastException("corrupted value")
        )
        val fallback = mockPreferences(existingId = "fallback-id", commitResult = true)
        val plugin = PersistentDeviceIdPlugin()

        val result = plugin.resolveStoredId(encrypted.preferences, fallback.preferences)

        assertEquals("fallback-id", result)
        Mockito.verify(encrypted.editor).putString("device_id", "fallback-id")
        Mockito.verify(encrypted.editor).commit()
    }

    @Test
    fun resolveStoredId_usesPlainStorageWhenEncryptedWriteFails() {
        val encrypted = mockPreferences(existingId = null, commitResult = false)
        val fallback = mockPreferences(existingId = null, commitResult = true)
        val plugin = PersistentDeviceIdPlugin()

        val result = plugin.resolveStoredId(encrypted.preferences, fallback.preferences) {
            "generated-id"
        }

        assertEquals("generated-id", result)
        Mockito.verify(encrypted.editor).commit()
        Mockito.verify(fallback.editor).putString("device_id", "generated-id")
        Mockito.verify(fallback.editor).commit()
    }

    @Test
    fun resolveStoredId_migratesExistingPlainFallbackToEncryptedStorage() {
        val encrypted = mockPreferences(existingId = null, commitResult = true)
        val fallback = mockPreferences(existingId = "fallback-id", commitResult = true)
        val plugin = PersistentDeviceIdPlugin()

        val result = plugin.resolveStoredId(encrypted.preferences, fallback.preferences)

        assertEquals("fallback-id", result)
        Mockito.verify(encrypted.editor).putString("device_id", "fallback-id")
        Mockito.verify(encrypted.editor).commit()
        Mockito.verifyNoInteractions(fallback.editor)
    }

    @Test
    fun resolveStoredId_returnsNullWhenAllPersistentWritesFail() {
        val encrypted = mockPreferences(existingId = null, commitResult = false)
        val fallback = mockPreferences(existingId = null, commitResult = false)
        val plugin = PersistentDeviceIdPlugin()

        val result = plugin.resolveStoredId(encrypted.preferences, fallback.preferences) {
            "generated-id"
        }

        assertNull(result)
    }

    private fun mockPreferences(
        existingId: String?,
        commitResult: Boolean,
        readFailure: RuntimeException? = null
    ): MockPreferences {
        val preferences = Mockito.mock(SharedPreferences::class.java)
        val editor = Mockito.mock(SharedPreferences.Editor::class.java)

        val storedValue = Mockito.`when`(preferences.getString("device_id", null))
        if (readFailure == null) {
            storedValue.thenReturn(existingId)
        } else {
            storedValue.thenThrow(readFailure)
        }
        Mockito.`when`(preferences.edit()).thenReturn(editor)
        Mockito.`when`(editor.putString("device_id", "generated-id")).thenReturn(editor)
        Mockito.`when`(editor.putString("device_id", "fallback-id")).thenReturn(editor)
        Mockito.`when`(editor.commit()).thenReturn(commitResult)

        return MockPreferences(preferences, editor)
    }

    private data class MockPreferences(
        val preferences: SharedPreferences,
        val editor: SharedPreferences.Editor
    )
}
