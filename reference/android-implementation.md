# Android Implementation Guide

Complete guide for implementing Capacitor plugins in Kotlin/Java for Android using the **two-class pattern**.

## Modern Android Plugin Architecture

Modern Capacitor plugins follow a **two-class pattern** for better separation of concerns:

1. **Plugin class** - Bridges Capacitor to native code (extends `Plugin`)
2. **Implementation class** - Contains business logic (plain Kotlin/Java class)

## Project Structure

```
android/
└── src/main/
    ├── java/                              # Java implementations
    └── kotlin/com/company/plugin/         # Kotlin implementations (recommended)
        ├── MyPlugin.kt                    # Implementation class
        └── MyPluginPlugin.kt              # Plugin bridge class
```

---

## 1. Kotlin Plugin Implementation (Recommended)

### Basic Plugin Bridge

```kotlin
// android/src/main/kotlin/MyPluginPlugin.kt
package com.company.plugin

import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.JSObject

@CapacitorPlugin(name = "MyPlugin")
class MyPluginPlugin : Plugin() {
    private val implementation = MyPlugin()

    @PluginMethod
    fun echo(call: PluginCall) {
        val value = call.getString("value") ?: ""
        val result = implementation.echo(value)

        call.resolve(JSObject().apply {
            put("value", result)
        })
    }
}
```

### Basic Implementation

```kotlin
// android/src/main/kotlin/MyPlugin.kt
package com.company.plugin

import android.util.Log

class MyPlugin {
    fun echo(value: String): String {
        Log.i("MyPlugin", "Echo: $value")
        return value
    }
}
```

**Key points:**
- Plugin class handles Capacitor bridge
- Implementation class has pure business logic
- Clean separation allows easy testing

### Plugin with Multiple Methods

```kotlin
// android/src/main/kotlin/CameraPluginPlugin.kt
package com.example.camera

import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "Camera")
class CameraPluginPlugin : Plugin() {
    private val implementation = CameraPlugin()

    @PluginMethod
    fun getPhoto(call: PluginCall) {
        val quality = call.getInt("quality", 90)
        val source = call.getString("source", "camera")

        implementation.getPhoto(context, quality, source) { result ->
            when {
                result.isSuccess -> call.resolve(result.getOrNull())
                else -> call.reject(result.exceptionOrNull()?.message ?: "Unknown error")
            }
        }
    }

    @PluginMethod
    fun checkPermissions(call: PluginCall) {
        val status = implementation.checkPermissions(context)
        call.resolve(status)
    }

    @PluginMethod
    fun requestPermissions(call: PluginCall) {
        implementation.requestPermissions(activity) { status ->
            call.resolve(status)
        }
    }
}
```

---

## 2. Java Plugin Implementation (Alternative)

### Java Plugin Bridge

```java
// android/src/main/java/MyPluginPlugin.java
package com.company.plugin;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.JSObject;

@CapacitorPlugin(name = "MyPlugin")
public class MyPluginPlugin extends Plugin {
    private final MyPlugin implementation = new MyPlugin();

    @PluginMethod
    public void echo(PluginCall call) {
        String value = call.getString("value", "");
        String result = implementation.echo(value);

        JSObject ret = new JSObject();
        ret.put("value", result);
        call.resolve(ret);
    }
}
```

### Java Implementation

```java
// android/src/main/java/MyPlugin.java
package com.company.plugin;

import android.util.Log;

public class MyPlugin {
    public String echo(String value) {
        Log.i("MyPlugin", "Echo: " + value);
        return value;
    }
}

        // 2. Perform work
        String result = performWork(param1, param2);

        // 3. Return result
        JSObject ret = new JSObject();
        ret.put("success", true);
        ret.put("data", result);
        call.resolve(ret);
    }

    private String performWork(String p1, int p2) {
        return "Android result: " + p1 + " " + p2;
    }
}
```

---

## 2. Parameter Extraction

### Extracting Values from PluginCall

```kotlin
@PluginMethod
fun exampleMethod(call: PluginCall) {
    // String
    val stringValue: String? = call.getString("key")
    val requiredString = call.getString("requiredKey") ?: run {
        call.reject("Missing requiredKey")
        return
    }

    // Int
    val intValue = call.getInt("count", 0) // With default
    val optionalInt: Int? = call.getInt("optionalCount")

    // Double/Float
    val doubleValue = call.getDouble("price", 0.0)
    val floatValue = call.getFloat("percentage", 0.0f)

    // Boolean
    val boolValue = call.getBoolean("enabled", false)

    // Long (for timestamps)
    val timestamp = call.getLong("timestamp", 0L)
    val date = Date(timestamp)

    // Array
    val arrayValue = call.getArray("items") // JSONArray?
    arrayValue?.let { array ->
        for (i in 0 until array.length()) {
            val item = array.getString(i)
            println(item)
        }
    }

    // Object
    val objectValue = call.getObject("config") // JSObject?
    objectValue?.let { config ->
        val name = config.getString("name")
        val age = config.getInteger("age")
    }

    val ret = JSObject()
    ret.put("received", "OK")
    call.resolve(ret)
}
```

### Type-Safe Parameter Extraction

```kotlin
// Define data class for parameters
data class PhotoOptions(
    val quality: Int,
    val source: String,
    val resultType: String
) {
    companion object {
        fun fromCall(call: PluginCall): PhotoOptions? {
            val source = call.getString("source") ?: return null
            val resultType = call.getString("resultType") ?: return null
            val quality = call.getInt("quality", 90)

            return PhotoOptions(quality, source, resultType)
        }
    }
}

@PluginMethod
fun getPhoto(call: PluginCall) {
    val options = PhotoOptions.fromCall(call) ?: run {
        call.reject("Invalid parameters")
        return
    }

    // Use strongly-typed options
    when (options.source) {
        "camera" -> openCamera(options.quality)
        "gallery" -> openGallery(options.quality)
    }
}
```

---

## 3. Returning Results

### Simple Success

```kotlin
@PluginMethod
fun getData(call: PluginCall) {
    val data = fetchData()

    val ret = JSObject()
    ret.put("value", data)
    ret.put("timestamp", System.currentTimeMillis())
    call.resolve(ret)
}
```

### Complex Objects

```kotlin
@PluginMethod
fun getDeviceInfo(call: PluginCall) {
    val ret = JSObject()
    ret.put("manufacturer", Build.MANUFACTURER)
    ret.put("model", Build.MODEL)
    ret.put("osVersion", Build.VERSION.RELEASE)
    ret.put("sdkVersion", Build.VERSION.SDK_INT)
    ret.put("isEmulator", isEmulator())

    call.resolve(ret)
}

private fun isEmulator(): Boolean {
    return (Build.FINGERPRINT.startsWith("generic")
            || Build.FINGERPRINT.startsWith("unknown")
            || Build.MODEL.contains("google_sdk")
            || Build.MODEL.contains("Emulator")
            || Build.MODEL.contains("Android SDK built for x86"))
}
```

### Arrays

```kotlin
@PluginMethod
fun listFiles(call: PluginCall) {
    val directory = context.filesDir
    val files = directory.listFiles() ?: emptyArray()

    val fileArray = JSArray()
    files.forEach { file ->
        val fileObj = JSObject()
        fileObj.put("name", file.name)
        fileObj.put("path", file.absolutePath)
        fileObj.put("size", file.length())
        fileArray.put(fileObj)
    }

    val ret = JSObject()
    ret.put("files", fileArray)
    call.resolve(ret)
}
```

---

## 4. Error Handling

### Basic Error Rejection

```kotlin
@PluginMethod
fun riskyMethod(call: PluginCall) {
    val param = call.getString("param") ?: run {
        call.reject("INVALID_PARAMETER", "param is required")
        return
    }

    // Check availability
    if (!isFeatureAvailable()) {
        call.reject("UNAVAILABLE", "Feature not available on this device")
        return
    }

    // Perform operation
    try {
        val result = performOperation(param)
        call.resolve(JSObject().put("result", result))
    } catch (e: Exception) {
        call.reject("OPERATION_FAILED", e.message, e)
    }
}
```

### Error with Exception

```kotlin
@PluginMethod
fun authenticate(call: PluginCall) {
    try {
        val biometricManager = BiometricManager.from(context)
        val canAuthenticate = biometricManager.canAuthenticate(BIOMETRIC_STRONG)

        if (canAuthenticate != BiometricManager.BIOMETRIC_SUCCESS) {
            call.reject(
                "BIOMETRIC_UNAVAILABLE",
                "Biometric authentication not available",
                Exception("Error code: $canAuthenticate")
            )
            return
        }

        // Proceed with authentication
    } catch (e: Exception) {
        call.reject("SETUP_FAILED", e.message, e)
    }
}
```

### Standard Error Codes

```kotlin
enum class PluginError(val code: String) {
    UNAVAILABLE("UNAVAILABLE"),
    PERMISSION_DENIED("PERMISSION_DENIED"),
    INVALID_PARAMETER("INVALID_PARAMETER"),
    OPERATION_FAILED("OPERATION_FAILED"),
    TIMEOUT("TIMEOUT")
}

fun PluginCall.reject(error: PluginError, message: String) {
    this.reject(error.code, message)
}

// Usage
call.reject(PluginError.PERMISSION_DENIED, "Camera permission not granted")
```

---

## 5. Permissions

### Checking Permissions

```kotlin
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

@PluginMethod
fun checkPermissions(call: PluginCall) {
    val cameraPermission = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.CAMERA
    )

    val ret = JSObject()
    ret.put("camera", getPermissionState(cameraPermission))
    call.resolve(ret)
}

private fun getPermissionState(permission: Int): String {
    return when (permission) {
        PackageManager.PERMISSION_GRANTED -> "granted"
        PackageManager.PERMISSION_DENIED -> "denied"
        else -> "prompt"
    }
}
```

### Requesting Permissions

```kotlin
import android.Manifest
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts

class MyPlugin : Plugin() {
    private lateinit var permissionLauncher: ActivityResultLauncher<String>
    private var savedCall: PluginCall? = null

    override fun load() {
        super.load()

        // Register permission launcher
        permissionLauncher = activity.registerForActivityResult(
            ActivityResultContracts.RequestPermission()
        ) { isGranted ->
            val call = savedCall ?: return@registerForActivityResult
            savedCall = null

            val ret = JSObject()
            ret.put("camera", if (isGranted) "granted" else "denied")
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun requestPermissions(call: PluginCall) {
        savedCall = call
        permissionLauncher.launch(Manifest.permission.CAMERA)
    }
}
```

### Permission Guard Pattern

```kotlin
@PluginMethod
fun takePhoto(call: PluginCall) {
    val permission = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.CAMERA
    )

    when (permission) {
        PackageManager.PERMISSION_GRANTED -> {
            // Proceed with camera
            openCamera(call)
        }
        else -> {
            // Request permission
            savedCall = call
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }
}

private fun openCamera(call: PluginCall) {
    // Camera implementation
}
```

### Multiple Permissions

```kotlin
private val multiPermissionLauncher = activity.registerForActivityResult(
    ActivityResultContracts.RequestMultiplePermissions()
) { permissions ->
    val call = savedCall ?: return@registerForActivityResult
    savedCall = null

    val ret = JSObject()
    ret.put("camera", if (permissions[Manifest.permission.CAMERA] == true) "granted" else "denied")
    ret.put("location", if (permissions[Manifest.permission.ACCESS_FINE_LOCATION] == true) "granted" else "denied")
    call.resolve(ret)
}

@PluginMethod
fun requestPermissions(call: PluginCall) {
    savedCall = call
    multiPermissionLauncher.launch(arrayOf(
        Manifest.permission.CAMERA,
        Manifest.permission.ACCESS_FINE_LOCATION
    ))
}
```

---

## 6. Events and Listeners

### Sending Events to JavaScript

```kotlin
@PluginMethod
fun startMonitoring(call: PluginCall) {
    // Start background monitoring
    startLocationUpdates()
    call.resolve()
}

private fun startLocationUpdates() {
    val locationRequest = LocationRequest.create().apply {
        interval = 10000
        fastestInterval = 5000
        priority = LocationRequest.PRIORITY_HIGH_ACCURACY
    }

    val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val location = result.lastLocation ?: return

            // Send event to JavaScript
            val data = JSObject()
            data.put("latitude", location.latitude)
            data.put("longitude", location.longitude)
            data.put("accuracy", location.accuracy)
            data.put("timestamp", location.time)

            notifyListeners("locationUpdate", data)
        }
    }

    fusedLocationClient.requestLocationUpdates(
        locationRequest,
        locationCallback,
        Looper.getMainLooper()
    )
}
```

### Multiple Event Types

```kotlin
@PluginMethod
fun startSensorMonitoring(call: PluginCall) {
    val sensorType = call.getString("sensorType") ?: run {
        call.reject("Missing sensorType")
        return
    }

    when (sensorType) {
        "accelerometer" -> startAccelerometer()
        "gyroscope" -> startGyroscope()
        else -> {
            call.reject("Invalid sensor type")
            return
        }
    }

    call.resolve()
}

private fun startAccelerometer() {
    val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    val listener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            val data = JSObject()
            data.put("x", event.values[0])
            data.put("y", event.values[1])
            data.put("z", event.values[2])
            data.put("timestamp", System.currentTimeMillis())

            notifyListeners("accelerometer", data)
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    sensorManager.registerListener(
        listener,
        accelerometer,
        SensorManager.SENSOR_DELAY_UI
    )
}
```

---

## 7. Activity Results

### Launch Activity for Result

```kotlin
private val activityLauncher = activity.registerForActivityResult(
    ActivityResultContracts.StartActivityForResult()
) { result ->
    val call = savedCall ?: return@registerForActivityResult
    savedCall = null

    if (result.resultCode == Activity.RESULT_OK) {
        val data = result.data?.getStringExtra("result")
        call.resolve(JSObject().put("result", data))
    } else {
        call.reject("CANCELLED", "Operation cancelled")
    }
}

@PluginMethod
fun openCustomActivity(call: PluginCall) {
    val intent = Intent(context, CustomActivity::class.java)
    intent.putExtra("param", call.getString("param"))

    savedCall = call
    activityLauncher.launch(intent)
}
```

### Pick File

```kotlin
private val pickFileLauncher = activity.registerForActivityResult(
    ActivityResultContracts.GetContent()
) { uri ->
    val call = savedCall ?: return@registerForActivityResult
    savedCall = null

    if (uri != null) {
        val ret = JSObject()
        ret.put("uri", uri.toString())
        ret.put("path", getRealPath(uri))
        call.resolve(ret)
    } else {
        call.reject("CANCELLED", "File selection cancelled")
    }
}

@PluginMethod
fun pickFile(call: PluginCall) {
    savedCall = call
    pickFileLauncher.launch("*/*")
}

private fun getRealPath(uri: Uri): String? {
    val projection = arrayOf(MediaStore.Images.Media.DATA)
    context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            return cursor.getString(columnIndex)
        }
    }
    return null
}
```

---

## 8. Background Tasks

### WorkManager Example

```kotlin
import androidx.work.*

@PluginMethod
fun scheduleBackgroundTask(call: PluginCall) {
    val taskId = call.getString("taskId") ?: run {
        call.reject("Missing taskId")
        return
    }

    val workRequest = OneTimeWorkRequestBuilder<BackgroundWorker>()
        .setInputData(workDataOf("taskId" to taskId))
        .build()

    WorkManager.getInstance(context).enqueue(workRequest)

    val ret = JSObject()
    ret.put("scheduled", true)
    ret.put("workId", workRequest.id.toString())
    call.resolve(ret)
}

class BackgroundWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val taskId = inputData.getString("taskId")

        // Perform background work
        performLongRunningTask()

        // Notify completion (if plugin is loaded)
        // You'll need to save a reference to the plugin to call notifyListeners

        return Result.success()
    }

    private fun performLongRunningTask() {
        // Long-running operation
    }
}
```

---

## 9. File Operations

### Read File

```kotlin
@PluginMethod
fun readFile(call: PluginCall) {
    val path = call.getString("path") ?: run {
        call.reject("Missing path")
        return
    }

    val file = File(context.filesDir, path)

    if (!file.exists()) {
        call.reject("FILE_NOT_FOUND", "File does not exist")
        return
    }

    try {
        val encoding = call.getString("encoding")
        val data = if (encoding == "utf8") {
            file.readText()
        } else {
            Base64.encodeToString(file.readBytes(), Base64.DEFAULT)
        }

        val ret = JSObject()
        ret.put("data", data)
        call.resolve(ret)
    } catch (e: Exception) {
        call.reject("READ_FAILED", e.message, e)
    }
}
```

### Write File

```kotlin
@PluginMethod
fun writeFile(call: PluginCall) {
    val path = call.getString("path") ?: run {
        call.reject("Missing path")
        return
    }
    val dataString = call.getString("data") ?: run {
        call.reject("Missing data")
        return
    }

    val file = File(context.filesDir, path)

    try {
        val encoding = call.getString("encoding")
        if (encoding == "utf8") {
            file.writeText(dataString)
        } else {
            val data = Base64.decode(dataString, Base64.DEFAULT)
            file.writeBytes(data)
        }

        call.resolve()
    } catch (e: Exception) {
        call.reject("WRITE_FAILED", e.message, e)
    }
}
```

---

## 10. Threading

### Run on Main Thread

```kotlin
@PluginMethod
fun showToast(call: PluginCall) {
    val message = call.getString("message") ?: "Hello"

    activity.runOnUiThread {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
        call.resolve()
    }
}
```

### Run on Background Thread

```kotlin
@PluginMethod
fun heavyOperation(call: PluginCall) {
    Thread {
        // Perform heavy work
        val result = performLongOperation()

        // Return result on main thread
        activity.runOnUiThread {
            call.resolve(JSObject().put("result", result))
        }
    }.start()
}

// Or using Kotlin Coroutines
@PluginMethod
fun heavyOperationCoroutine(call: PluginCall) {
    CoroutineScope(Dispatchers.IO).launch {
        val result = performLongOperation()

        withContext(Dispatchers.Main) {
            call.resolve(JSObject().put("result", result))
        }
    }
}
```

---

## 11. Configuration

### AndroidManifest.xml

```xml
<!-- android/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.company.plugin">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Features -->
    <uses-feature
        android:name="android.hardware.camera"
        android:required="false" />

</manifest>
```

### build.gradle

```gradle
// android/build.gradle
android {
    namespace "com.company.plugin"
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 22
        targetSdkVersion 33
    }
}

dependencies {
    implementation "androidx.appcompat:appcompat:1.6.1"
    implementation "androidx.core:core-ktx:1.10.1"

    // Capacitor
    implementation project(':capacitor-android')
}
```

---

## 12. Testing

### JUnit Example

```kotlin
import org.junit.Test
import org.junit.Assert.*

class MyPluginTest {

    @Test
    fun testPerformWork() {
        val plugin = MyPlugin()
        val result = plugin.performWork("test", 42)
        assertEquals("Android result: test 42", result)
    }

    @Test
    fun testParameterValidation() {
        // Test with mock PluginCall
    }
}
```

---

## 13. Best Practices

### DO:
- ✅ Always check for null parameters
- ✅ Run UI code on main thread with `activity.runOnUiThread`
- ✅ Use Kotlin for cleaner, safer code
- ✅ Handle all error cases with try-catch
- ✅ Request permissions at runtime
- ✅ Clean up resources in `handleOnDestroy()`

### DON'T:
- ❌ Block main thread with long operations
- ❌ Use `!!` (force unwrap) in Kotlin
- ❌ Log sensitive data
- ❌ Assume permissions are granted
- ❌ Forget to call `call.resolve()` or `call.reject()`
- ❌ Hard-code file paths

---

## Summary

**Android Implementation Checklist**:

- [ ] Create Kotlin/Java plugin class extending `Plugin`
- [ ] Annotate with `@CapacitorPlugin`
- [ ] Mark methods with `@PluginMethod`
- [ ] Extract parameters safely with null checks
- [ ] Return results with `call.resolve(JSObject())`
- [ ] Handle errors with `call.reject()`
- [ ] Request permissions with ActivityResultLauncher
- [ ] Use `notifyListeners()` for events
- [ ] Run UI code on main thread
- [ ] Declare permissions in AndroidManifest.xml

**Remember**: Android has strict permission and threading requirements. Always test on real devices!
