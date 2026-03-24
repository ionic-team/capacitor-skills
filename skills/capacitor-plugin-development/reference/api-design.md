# API Design Best Practices

This reference covers how to design clean, intuitive TypeScript APIs for Capacitor plugins.

## Core Principles

### 1. Promise-Based APIs

✅ **Always use Promises** for async operations:

```typescript
// ✅ Good
async getLocation(): Promise<Location> {
  // Returns promise
}

// ❌ Bad - callbacks
getLocation(callback: (location: Location) => void): void {
  // Callback hell
}

// ❌ Bad - synchronous when it shouldn't be
getLocationSync(): Location {
  // Blocks thread
}
```

### 2. Strong Typing

✅ **Define explicit interfaces** for all data:

```typescript
// ✅ Good - Strongly typed
interface PhotoOptions {
  quality: number;          // 0-100
  source: 'camera' | 'gallery';
  resultType: 'base64' | 'uri';
}

interface Photo {
  base64String?: string;
  path?: string;
  format: 'jpeg' | 'png';
}

async getPhoto(options: PhotoOptions): Promise<Photo>;

// ❌ Bad - Weakly typed
async getPhoto(options: any): Promise<any>;
```

### 3. Semantic Method Names

Use clear, action-oriented names:

```typescript
// ✅ Good
async getCurrentPosition(): Promise<Position>
async startMonitoring(): Promise<void>
async requestPermissions(): Promise<PermissionStatus>
async capturePhoto(): Promise<Photo>

// ❌ Bad
async position(): Promise<Position>        // Not clear if get/set
async monitor(): Promise<void>             // Start or stop?
async permissions(): Promise<PermissionStatus>  // Check or request?
async photo(): Promise<Photo>              // Too vague
```

---

## Method Naming Conventions

### Action Verbs

| Verb | Usage | Example |
|------|-------|---------|
| `get` | Retrieve current state | `getBatteryStatus()`, `getLocation()` |
| `check` | Test condition | `checkPermissions()`, `isAvailable()` |
| `request` | Ask for something | `requestPermissions()`, `requestToken()` |
| `start` | Begin continuous operation | `startMonitoring()`, `startScanning()` |
| `stop` | End continuous operation | `stopMonitoring()`, `stopScanning()` |
| `create` | Make new resource | `createFile()`, `createNotification()` |
| `delete` | Remove resource | `deleteFile()`, `removeNotification()` |
| `update` | Modify existing | `updateSettings()`, `modifyRecord()` |
| `open` | Open/show UI | `openSettings()`, `showDialog()` |
| `close` | Close UI | `closeDialog()`, `dismissAlert()` |

### Naming Examples

```typescript
// State retrieval
async getBatteryStatus(): Promise<BatteryInfo>
async getNetworkStatus(): Promise<NetworkInfo>

// Permission handling
async checkPermissions(): Promise<PermissionStatus>
async requestPermissions(): Promise<PermissionStatus>

// Operations
async capturePhoto(options: PhotoOptions): Promise<Photo>
async scanBarcode(): Promise<BarcodeResult>
async shareContent(options: ShareOptions): Promise<void>

// Monitoring
async startLocationUpdates(): Promise<void>
async stopLocationUpdates(): Promise<void>
async addListener(eventName: string, callback: Function): Promise<PluginListenerHandle>
async removeAllListeners(): Promise<void>

// Availability checks
async isAvailable(): Promise<{ available: boolean }>
async isSupported(): Promise<{ supported: boolean }>
```

---

## Parameter Design

### Options Objects

✅ **Use options objects** for methods with multiple parameters:

```typescript
// ✅ Good - Options object
interface WriteFileOptions {
  path: string;
  data: string;
  encoding?: 'utf8' | 'base64';  // Optional with default
  append?: boolean;               // Optional boolean
}

async writeFile(options: WriteFileOptions): Promise<void>

// Usage is clear
await Filesystem.writeFile({
  path: 'notes.txt',
  data: 'Hello world',
  encoding: 'utf8',
  append: true
});

// ❌ Bad - Many parameters
async writeFile(
  path: string,
  data: string,
  encoding?: string,
  append?: boolean
): Promise<void>

// Hard to remember parameter order
await Filesystem.writeFile('notes.txt', 'Hello', 'utf8', true);
```

### Optional vs Required

```typescript
interface RequestOptions {
  // Required - no default sensible value
  url: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';

  // Optional - has sensible defaults
  headers?: Record<string, string>;
  timeout?: number;          // Default: 30000
  followRedirects?: boolean; // Default: true
}
```

### Default Values

Document defaults in JSDoc:

```typescript
interface CameraOptions {
  /**
   * Image quality (0-100)
   * @default 90
   */
  quality?: number;

  /**
   * Maximum width in pixels
   * @default 0 (no limit)
   */
  width?: number;

  /**
   * Source for photo
   * @default 'camera'
   */
  source?: 'camera' | 'gallery';
}
```

---

## Return Type Design

### Success Results

```typescript
// Simple success - void
async deleteFile(options: { path: string }): Promise<void>

// Return data
async readFile(options: { path: string }): Promise<{ data: string }>

// Return multiple values
async getLocation(): Promise<{
  latitude: number;
  longitude: number;
  accuracy: number;
  timestamp: number;
}>
```

### Boolean Results

```typescript
// ✅ Good - Explicit naming
async isAvailable(): Promise<{ available: boolean }>
async checkConnection(): Promise<{ connected: boolean }>

// ❌ Bad - Ambiguous
async available(): Promise<boolean>  // Is this checking or setting?
```

### List Results

```typescript
// ✅ Good - Named array property
async listFiles(): Promise<{ files: FileInfo[] }>

interface FileInfo {
  name: string;
  size: number;
  modified: number;
}

// ❌ Bad - Raw array (harder to extend later)
async listFiles(): Promise<FileInfo[]>
```

---

## Error Handling

### Consistent Error Codes

Define error codes as enum or constants:

```typescript
export enum PluginErrorCode {
  // Feature not available
  UNAVAILABLE = 'UNAVAILABLE',

  // Permission issues
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  PERMISSION_NOT_REQUESTED = 'PERMISSION_NOT_REQUESTED',

  // Parameter validation
  INVALID_PARAMETER = 'INVALID_PARAMETER',
  MISSING_PARAMETER = 'MISSING_PARAMETER',

  // Operation failures
  OPERATION_FAILED = 'OPERATION_FAILED',
  TIMEOUT = 'TIMEOUT',
  CANCELLED = 'CANCELLED',

  // Network issues
  NETWORK_ERROR = 'NETWORK_ERROR',
  NO_CONNECTION = 'NO_CONNECTION',
}
```

### Error Objects

```typescript
interface PluginError extends Error {
  code: PluginErrorCode;
  message: string;
  details?: any;  // Platform-specific details
}

// Usage
try {
  await Camera.getPhoto();
} catch (error) {
  if (error.code === 'PERMISSION_DENIED') {
    // Show permission rationale
  } else if (error.code === 'UNAVAILABLE') {
    // Feature not supported
  }
}
```

### When to Throw vs Return

```typescript
// ✅ Throw for exceptional failures
async getPhoto(options: PhotoOptions): Promise<Photo> {
  if (!options.quality || options.quality < 0 || options.quality > 100) {
    throw new Error('INVALID_PARAMETER: quality must be 0-100');
  }
  // ...
}

// ✅ Return status for expected conditions
async checkPermissions(): Promise<PermissionStatus> {
  // Don't throw if permission denied - it's expected
  return { camera: 'denied' };
}
```

---

## Event Listeners

### Event Pattern

```typescript
interface MyPlugin {
  /**
   * Start monitoring (if needed)
   */
  startMonitoring(): Promise<void>;

  /**
   * Listen for events
   */
  addListener(
    eventName: 'dataChange',
    listenerFunc: (data: DataType) => void,
  ): Promise<PluginListenerHandle> & PluginListenerHandle;

  /**
   * Remove specific listener
   */
  removeListener(handle: PluginListenerHandle): Promise<void>;

  /**
   * Remove all listeners for an event
   */
  removeAllListeners(): Promise<void>;

  /**
   * Stop monitoring (if needed)
   */
  stopMonitoring(): Promise<void>;
}
```

### Event Naming

```typescript
// ✅ Good - Descriptive event names
addListener('batteryChange', callback)
addListener('networkStatusChange', callback)
addListener('locationUpdate', callback)

// ❌ Bad - Vague names
addListener('change', callback)
addListener('update', callback)
addListener('data', callback)
```

### Multiple Event Types

```typescript
interface SensorPlugin {
  addListener(
    eventName: 'accelerometer',
    listenerFunc: (data: AccelerometerData) => void,
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'gyroscope',
    listenerFunc: (data: GyroscopeData) => void,
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'magnetometer',
    listenerFunc: (data: MagnetometerData) => void,
  ): Promise<PluginListenerHandle>;
}

// Usage
const handle = await Sensor.addListener('accelerometer', (data) => {
  console.log(data.x, data.y, data.z);
});
```

---

## Permission APIs

### Standard Permission Pattern

```typescript
export interface PermissionStatus {
  [key: string]: 'granted' | 'denied' | 'prompt';
}

interface MyPlugin {
  /**
   * Check current permission status without prompting
   */
  checkPermissions(): Promise<PermissionStatus>;

  /**
   * Request permissions from user (shows system dialog)
   */
  requestPermissions(): Promise<PermissionStatus>;
}
```

### Example: Camera Plugin

```typescript
interface CameraPermissionStatus {
  camera: 'granted' | 'denied' | 'prompt';
  photos: 'granted' | 'denied' | 'prompt';  // iOS photo library
}

// Check without prompting
const status = await Camera.checkPermissions();
if (status.camera === 'granted') {
  // Can use camera
}

// Request if needed
if (status.camera !== 'granted') {
  const result = await Camera.requestPermissions();
  if (result.camera === 'granted') {
    // Permission granted
  } else {
    // Permission denied - show rationale
  }
}
```

---

## Platform-Specific APIs

### Conditional Features

```typescript
interface FeatureAvailability {
  available: boolean;
  reason?: string;  // Why not available (if !available)
}

interface MyPlugin {
  /**
   * Check if feature is available on current platform
   */
  isAvailable(): Promise<FeatureAvailability>;
}

// Usage
const { available, reason } = await NFC.isAvailable();
if (!available) {
  console.log(`NFC not available: ${reason}`);
  // e.g., "Not supported on web", "Requires iOS 13+", etc.
}
```

### Platform-Specific Options

```typescript
interface NotificationOptions {
  title: string;
  body: string;

  // iOS-specific
  ios?: {
    sound?: string;
    badge?: number;
    threadId?: string;
  };

  // Android-specific
  android?: {
    channelId: string;
    priority?: 'high' | 'low';
    smallIcon?: string;
  };
}
```

---

## Versioning and Deprecation

### Deprecating Methods

```typescript
interface MyPlugin {
  /**
   * @deprecated Use getDataV2() instead. Will be removed in v3.0.0
   * @see getDataV2
   */
  getData(): Promise<OldData>;

  /**
   * Improved data fetching with additional fields
   * @since 2.1.0
   */
  getDataV2(): Promise<NewData>;
}
```

### Version-Specific Features

```typescript
interface MyPlugin {
  /**
   * Advanced feature
   * @since 2.0.0
   * @requires iOS 14+, Android 11+
   */
  advancedFeature(): Promise<void>;
}
```

---

## Documentation Standards

### JSDoc Comments

```typescript
interface MyPlugin {
  /**
   * Capture a photo using the device camera
   *
   * @param options - Configuration for photo capture
   * @returns Promise with photo data
   * @throws {PluginError} PERMISSION_DENIED if camera permission not granted
   * @throws {PluginError} UNAVAILABLE if camera not available
   *
   * @example
   * ```typescript
   * const photo = await Camera.getPhoto({
   *   quality: 90,
   *   source: 'camera',
   *   resultType: 'base64'
   * });
   * console.log(photo.base64String);
   * ```
   *
   * @see requestPermissions
   * @since 1.0.0
   */
  getPhoto(options: PhotoOptions): Promise<Photo>;
}
```

### Interface Documentation

```typescript
/**
 * Configuration options for photo capture
 */
export interface PhotoOptions {
  /**
   * Image quality (0-100)
   * Lower values = smaller file size
   * @default 90
   */
  quality?: number;

  /**
   * Where to get the photo from
   * - 'camera': Open camera to take new photo
   * - 'gallery': Select from photo library
   * @default 'camera'
   */
  source?: 'camera' | 'gallery';

  /**
   * Format of returned data
   * - 'base64': Base64-encoded string
   * - 'uri': File path URI
   * @default 'base64'
   */
  resultType?: 'base64' | 'uri';
}
```

---

## API Design Checklist

When designing a new plugin API:

- [ ] **Methods return Promises** for async operations
- [ ] **All data types have explicit interfaces**
- [ ] **Method names are semantic and action-oriented**
- [ ] **Parameters use options objects** (for methods with 2+ params)
- [ ] **Optional parameters have documented defaults**
- [ ] **Error codes are consistent and well-defined**
- [ ] **Events have descriptive names**
- [ ] **Permission methods follow standard pattern** (check/request)
- [ ] **Platform differences are documented**
- [ ] **All public APIs have JSDoc comments**
- [ ] **Examples provided for complex methods**
- [ ] **Return types are wrapped in objects** (for future extensibility)

---

## Common Patterns

### Pattern: Resource Management

```typescript
interface ResourcePlugin {
  // Open resource
  open(options: { id: string }): Promise<{ handle: string }>;

  // Use resource
  read(options: { handle: string }): Promise<{ data: string }>;
  write(options: { handle: string; data: string }): Promise<void>;

  // Close resource
  close(options: { handle: string }): Promise<void>;
}
```

### Pattern: Batch Operations

```typescript
interface BatchPlugin {
  // Single operation
  processItem(options: { id: string }): Promise<{ result: string }>;

  // Batch operation (more efficient)
  processBatch(options: { ids: string[] }): Promise<{ results: string[] }>;
}
```

### Pattern: Configuration

```typescript
interface ConfigurablePlugin {
  // Get current configuration
  getConfig(): Promise<PluginConfig>;

  // Update configuration
  setConfig(config: Partial<PluginConfig>): Promise<void>;

  // Reset to defaults
  resetConfig(): Promise<void>;
}
```

---

## Anti-Patterns to Avoid

### ❌ Callback Hell

```typescript
// Don't do this
plugin.getData((data) => {
  plugin.processData(data, (result) => {
    plugin.saveResult(result, (success) => {
      console.log('Done');
    });
  });
});

// Use Promises
const data = await plugin.getData();
const result = await plugin.processData(data);
await plugin.saveResult(result);
```

### ❌ Unclear Boolean Returns

```typescript
// Don't do this
async camera(): Promise<boolean>  // What does true/false mean?

// Be explicit
async isCameraAvailable(): Promise<{ available: boolean }>
```

### ❌ Stringly-Typed APIs

```typescript
// Don't do this
async doAction(action: string, data: any): Promise<any>

// Use specific methods and types
async capturePhoto(options: PhotoOptions): Promise<Photo>
async recordVideo(options: VideoOptions): Promise<Video>
```

### ❌ Mutable Options

```typescript
// Don't do this
const options = { quality: 90 };
await plugin.process(options);
// Plugin modifies options internally
console.log(options.quality);  // Changed to 100?

// Keep options immutable
```

---

## Summary

**Good API Design**:
- Clear, predictable method names
- Strong typing with explicit interfaces
- Consistent error handling
- Well-documented with examples
- Extensible for future needs
- Platform differences handled gracefully

**Remember**: The API is the user's first impression of your plugin. Make it intuitive!
