package persistent_device_id.maeltoukap.me

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import org.mockito.Mockito
import kotlin.test.Test

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class PersistentDeviceIdPluginTest {
  @Test
  fun onMethodCall_getDeviceId_returnsExpectedValue() {
    val plugin = PersistentDeviceIdPlugin { "test-device-id" }

    val call = MethodCall("getDeviceId", null)
    val mockResult: Result = Mockito.mock(Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success("test-device-id")
  }

  @Test
  fun onMethodCall_unknownMethod_returnsNotImplemented() {
    val plugin = PersistentDeviceIdPlugin { "test-device-id" }

    val call = MethodCall("unknownMethod", null)
    val mockResult: Result = Mockito.mock(Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).notImplemented()
  }
}
