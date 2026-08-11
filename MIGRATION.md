# Migration Guide

This document outlines breaking changes and migration steps between major versions of the project.

## Migration from 2.x to 3.0

This section describes the main changes introduced in SDK `3.0` compared to `2.x`.

### Product Modules 

All SDK products (RUM, Trace, Logs, SessionReplay, and so on) remain modular and separated into distinct libraries. The main change is that the `AtatusObjc` module has been removed, with its contents integrated into the corresponding product modules.

The available `Atatus` libraries in 3.0 are:
- `AtatusCore`
- `AtatusCrashReporting`
- `AtatusLogs`
- `AtatusRUM`
- `AtatusSessionReplay`
- `AtatusTrace`
- `AtatusWebViewTracking`

<details>
  <summary>SPM</summary>

  ```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/atatus/atatus-sdk-ios", from: "3.0.0")
    ],
    targets: [
        .target(
            ...
            dependencies: [
                .product(name: "AtatusCore", package: "atatus-sdk-ios"),
                .product(name: "AtatusCrashReporting", package: "atatus-sdk-ios"),
                .product(name: "AtatusLogs", package: "atatus-sdk-ios"),
                .product(name: "AtatusRUM", package: "atatus-sdk-ios"),
                .product(name: "AtatusSessionReplay", package: "atatus-sdk-ios"),
                .product(name: "AtatusTrace", package: "atatus-sdk-ios"),
                .product(name: "AtatusWebViewTracking", package: "atatus-sdk-ios"),
            ]
        ),
    ]
)
  ```
</details>

<details>
  <summary>CocoaPods</summary>

  ```ruby
  pod 'AtatusCore'
  pod 'AtatusCrashReporting'
  pod 'AtatusLogs'
  pod 'AtatusRUM'
  pod 'AtatusSessionReplay'
  pod 'AtatusTrace'
  pod 'AtatusWebViewTracking'
  ```
</details>

<details>
  <summary>Carthage</summary>

  The `Cartfile` remains the same: 
  ```
  github "atatus/atatus-sdk-ios"
  ```

  In Xcode, you **must** link the following frameworks:
  ```
  AtatusCore.xcframework
  AtatusInternal.xcframework
  ```

  Then select the product modules you intend to use:
  ```
  AtatusCrashReporting.xcframework + CrashReporter.xcframework
  AtatusLogs.xcframework
  AtatusRUM.xcframework
  AtatusSessionReplay.xcframework
  AtatusTrace.xcframework
  AtatusWebViewTracking.xcframework
  ```
</details>

### SDK Configuration

The SDK should be initialized as early as possible in the app lifecycle, specifically in the `AppDelegate`'s `application(_:didFinishLaunchingWithOptions:)` callback. This ensures accurate measurement of all metrics, including application startup duration. For apps built with SwiftUI, use `@UIApplicationDelegateAdaptor` to access the `AppDelegate`.

```swift
import AtatusCore

Atatus.initialize(
    with: Atatus.Configuration(
        licenseKey: "<client token>",
        env: "<environment>",
        service: "<service name>"
    ), 
    trackingConsent: .granted
)
```

**Note**: Initializing the SDK elsewhere (for example later during view loading) may result in inaccurate or missing telemetry, especially around app startup performance.

### RUM Product Changes

RUM View-level attributes are now automatically propagated to all related child events, including resources, user actions, errors, and long tasks. This ensures consistent metadata across events, making it easier to filter and correlate data on Atatus dashboards.

To manage View level attributes more effectively, new APIs were added:
- `Monitor.addViewAttribute(forKey:value:)`
- `Monitor.addViewAttributes(_:)`
- `Monitor.removeViewAttribute(forKey:)`
- `Monitor.removeViewAttributes(forKeys:)`

Other notable changes:
- All Objective-C RUM APIs are now included in `AtatusRUM`. The separate `AtatusObjc` module is no longer available.
- App Hangs and Watchdog terminations are no longer reported from app extensions or widgets.
- A new property `trackMemoryWarnings` was added to `RUM.Configuration` to report memory warnings as RUM Errors.

API changes:

|`2.x`|`3.0`|
|---|---|
|-|`RUM.Configuration.trackMemoryWarnings`|
|`RUMView(path:attributes:)`|`RUMView(name:attributes:isUntrackedModal:)`|
|-|`Monitor.addViewAttribute(forKey:value:)`|
|-|`Monitor.addViewAttributes(:)`|
|-|`Monitor.removeViewAttribute(forKey:)`|
|-|`Monitor.removeViewAttributes(forKeys:)`|

### Logs Product Changes

The Logs product no longer reports fatal errors. To enable Error Tracking for crashes, Crash Reporting must be enabled in conjunction with RUM.

Additionally, all Objective-C Logs APIs are now included in `AtatusLogs`. The separate `AtatusObjc` module is no longer available.

### APM Trace Product Changes

Trace sampling is now deterministic when used alongside RUM. It uses the RUM `session.id` to ensure consistent sampling.

Also:
- The `Trace.Configuration.URLSessionTracking.FirstPartyHostsTracing` configuration sets sampling for all requests by default and the trace context is injected only into sampled requests.
- All Objective-C Trace APIs are now included in `AtatusTrace`. The separate `AtatusObjc` module is no longer available.

**Note**: A similar configuration exists in `RUM.Configuration.URLSessionTracking.FirstPartyHostsTracing`.

### Session Replay Product Changes

Privacy settings are now more granular. The previous `defaultPrivacyLevel` parameter has been replaced with:
- `textAndInputPrivacyLevel`
- `imagePrivacyLevel`
- `touchPrivacyLevel`

Learn more about [privacy levels][1].

API changes:

|`2.x`|`3.0`|
|---|---|
|`SessionReplay.Configuration(replaySampleRate:defaultPrivacyLevel:startRecordingImmediately:customEndpoint:)`|`SessionReplay.Configuration(replaySampleRate:textAndInputPrivacyLevel:imagePrivacyLevel:touchPrivacyLevel:startRecordingImmediately:customEndpoint:featureFlags:)`|
|`SessionReplay.Configuration(replaySampleRate:defaultPrivacyLevel:startRecordingImmediately:customEndpoint:)`|`SessionReplay.Configuration(replaySampleRate:textAndInputPrivacyLevel:imagePrivacyLevel:touchPrivacyLevel:startRecordingImmediately:customEndpoint:featureFlags:)`|

### URLSession Instrumentation Changes

Legacy delegate types have been replaced by a unified instrumentation API:

|`2.x`|`3.0`|
|---|---|
|`AtatusURLSessionDelegate()`|`URLSessionInstrumentation.enable(with:)`|
|`ATURLSessionDelegate()`|`URLSessionInstrumentation.enable(with:)`|
|`ATNSURLSessionDelegate()`|`URLSessionInstrumentation.enable(with:)`|

## Migration from 1.x to 2.0

This section describes the main changes introduced in SDK `2.0` compared to `1.x`.

### Product Modules 

All relevant products (RUM, Trace, Logs, etc.) are now extracted into different modules. That allows you to integrate only what is needed into your application.

Whereas all products in version 1.x were contained in the single module, `Atatus`, you now need to adopt the following libraries:

- `AtatusCore`
- `AtatusLogs`
- `AtatusTrace`
- `AtatusRUM`
- `AtatusWebViewTracking`

These come in addition to the existing `AtatusCrashReporting` and `AtatusObjc`.

<details>
  <summary>SPM</summary>

  ```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/atatus/atatus-sdk-ios", from: "2.0.0")
    ],
    targets: [
        .target(
            ...
            dependencies: [
                .product(name: "AtatusCore", package: "atatus-sdk-ios"),
                .product(name: "AtatusLogs", package: "atatus-sdk-ios"),
                .product(name: "AtatusTrace", package: "atatus-sdk-ios"),
                .product(name: "AtatusRUM", package: "atatus-sdk-ios"),
                .product(name: "AtatusCrashReporting", package: "atatus-sdk-ios"),
                .product(name: "AtatusWebViewTracking", package: "atatus-sdk-ios"),
            ]
        ),
    ]
)
  ```
</details>

<details>
  <summary>CocoaPods</summary>

  ```ruby
  pod 'AtatusCore'
  pod 'AtatusLogs'
  pod 'AtatusTrace'
  pod 'AtatusRUM'
  pod 'AtatusCrashReporting'
  pod 'AtatusWebViewTracking'
  pod 'AtatusObjc'
  ```
</details>

<details>
  <summary>Carthage</summary>

  The `Cartfile` stays the same: 
  ```
  github "atatus/atatus-sdk-ios"
  ```

  In Xcode, you **must** link the following frameworks:
  ```
  AtatusInternal.xcframework
  AtatusCore.xcframework
  ```

  Then you can select the modules you want to use:
  ```
  AtatusLogs.xcframework
  AtatusTrace.xcframework
  AtatusRUM.xcframework
  AtatusCrashReporting.xcframework + CrashReporter.xcframework
  AtatusWebViewTracking.xcframework
  AtatusObjc.xcframework
  ```
</details>

**Note**: In case of Crash Reporting and WebView Tracking usage it's also needed to add RUM and/or Logs modules to be able to report events to RUM and/or Logs respectively.

The `2.0` version of the iOS SDK also exposes unified API layouts and naming between iOS and Android SDKs and with other Atatus products.

### SDK Configuration Changes

Better SDK granularity is achieved with the extraction of different products into independent modules, therefore all product-specific configurations have been moved to their dedicated modules.

> The SDK must be initialized before enabling any product.

The Builder pattern of the SDK initialization has been removed in favor of structure definitions. The following example shows how a `1.x` initialization would translate in `2.0`.

**V1 Initialization**
```swift
import Atatus

Atatus.initialize(
    appContext: .init(),
    trackingConsent: .granted,
    configuration: Atatus.Configuration
        .builderUsing(
            licenseKey: "<client token>",
            environment: "<environment>"
        )
        .set(serviceName: "<service name>")
        .build()
```
**V2 Initialization**
```swift
import AtatusCore

Atatus.initialize(
    with: Atatus.Configuration(
        licenseKey: "<client token>",
        env: "<environment>",
        service: "<service name>"
    ), 
    trackingConsent: .granted
)
```

API changes:

|`1.x`|`2.0`|
|---|---|
|`Atatus.Configuration.Builder.set(serviceName:)`|`Atatus.Configuration.service`|
|`Atatus.Configuration.Builder.set(batchSize:)`|`Atatus.Configuration.batchSize`|
|`Atatus.Configuration.Builder.set(uploadFrequency:)`|`Atatus.Configuration.uploadFrequency`|
|`Atatus.Configuration.Builder.set(proxyConfiguration:)`|`Atatus.Configuration.proxyConfiguration`|
|`Atatus.Configuration.Builder.set(encryption:)`|`Atatus.Configuration.encryption`|
|`Atatus.Configuration.Builder.set(serverDateProvider:)`|`Atatus.Configuration.serverDateProvider`|
|`Atatus.AppContext(mainBundle:)`|`Atatus.Configuration.bundle`|

### Logs Product Changes

All the classes related to Logs are now strictly in the `AtatusLogs` module. You first need to enable the product:

```swift
import AtatusLogs

Logs.enable(with: Logs.Configuration(...))
```

Then, you can create a logger instance:

```swift
import AtatusLogs

let logger = Logger.create(
    with: Logger.Configuration(name: "<logger name>")
)
```

API changes:

|`1.x`|`2.0`|
|---|---|
|`Atatus.Configuration.Builder.setLogEventMapper(_:)`|`Logs.Configuration.eventMapper`|
|`Atatus.Configuration.Builder.set(loggingSamplingRate:)`|`Logs.Configuration.eventMapper`|
|`Logger.Builder.set(serviceName:)`|`Logger.Configuration.service`|
|`Logger.Builder.set(loggerName:)`|`Logger.Configuration.name`|
|`Logger.Builder.sendNetworkInfo(_:)`|`Logger.Configuration.networkInfoEnabled`|
|`Logger.Builder.bundleWithRUM(_:)`|`Logger.Configuration.bundleWithRumEnabled`|
|`Logger.Builder.bundleWithTrace(_:)`|`Logger.Configuration.bundleWithTraceEnabled`|
|`Logger.Builder.sendLogsToAtatus(false)`|`Logger.Configuration.remoteSampleRate = 0`|
|`Logger.Builder.set(atatusReportingThreshold:)`|`Logger.Configuration.remoteLogThreshold`|
|`Logger.Builder.printLogsToConsole(_:, usingFormat)`|`Logger.Configuration.consoleLogFormat`|

### APM Trace Product Changes

All the classes related to Trace are now strictly in the `AtatusTrace` module. You first need to enable the product:

```swift
import AtatusTrace

Trace.enable(
    with: Trace.Configuration(...)
)
```

Then, you can access the shared Tracer instance:

```swift
import AtatusTrace

let tracer = Tracer.shared()
```

API changes:

|`1.x`|`2.0`|
|---|---|
|`Atatus.Configuration.Builder.trackURLSession(_:)`|`Trace.Configuration.urlSessionTracking`|
|`Atatus.Configuration.Builder.setSpanEventMapper(_:)`|`Trace.Configuration.eventMapper`|
|`Atatus.Configuration.Builder.set(tracingSamplingRate:)`|`Trace.Configuration.sampleRate`|
|`Tracer.Configuration.serviceName`|`Trace.Configuration.service`|
|`Tracer.Configuration.sendNetworkInfo`|`Trace.Configuration.networkInfoEnabled`|
|`Tracer.Configuration.globalTags`|`Trace.Configuration.tags`|
|`Tracer.Configuration.bundleWithRUM`|`Trace.Configuration.bundleWithRumEnabled`|
|`Tracer.Configuration.samplingRate`|`Trace.Configuration.sampleRate`|

### RUM Product Changes

All the classes related to RUM are now strictly in the `AtatusRUM` module. You will first need to enable the product:

```swift
import AtatusRUM

RUM.enable(
    with: RUM.Configuration(applicationID: "<RUM Application ID>")
)
```

Then, you can access the shared RUM monitor instance:

```swift
import AtatusRUM

let monitor = RUMMonitor.shared()
```

API changes:

|`1.x`|`2.0`|
|---|---|
|`Atatus.Configuration.Builder.trackURLSession(_:)`|`RUM.Configuration.urlSessionTracking`|
|`Atatus.Configuration.Builder.set(rumSessionsSamplingRate:)`|`RUM.Configuration.sessionSampleRate`|
|`Atatus.Configuration.Builder.onRUMSessionStart`|`RUM.Configuration.onSessionStart`|
|`Atatus.Configuration.Builder.trackUIKitRUMViews(using:)`|`RUM.Configuration.uiKitViewsPredicate`|
|`Atatus.Configuration.Builder.trackUIKitRUMActions(using:)`|`RUM.Configuration.uiKitActionsPredicate`|
|`Atatus.Configuration.Builder.trackRUMLongTasks(threshold:)`|`RUM.Configuration.longTaskThreshold`|
|`Atatus.Configuration.Builder.setRUMViewEventMapper(_:)`|`RUM.Configuration.viewEventMapper`|
|`Atatus.Configuration.Builder.setRUMResourceEventMapper(_:)`|`RUM.Configuration.resourceEventMapper`|
|`Atatus.Configuration.Builder.setRUMActionEventMapper(_:)`|`RUM.Configuration.actionEventMapper`|
|`Atatus.Configuration.Builder.setRUMErrorEventMapper(_:)`|`RUM.Configuration.errorEventMapper`|
|`Atatus.Configuration.Builder.setRUMLongTaskEventMapper(_:)`|`RUM.Configuration.longTaskEventMapper`|
|`Atatus.Configuration.Builder.setRUMResourceAttributesProvider(_:)`|`RUM.Configuration.urlSessionTracking.resourceAttributesProvider`|
|`Atatus.Configuration.Builder.trackBackgroundEvents(_:)`|`RUM.Configuration.trackBackgroundEvents`|
|`Atatus.Configuration.Builder.trackFrustrations(_:)`|`RUM.Configuration.frustrationsTracking`|
|`Atatus.Configuration.Builder.set(mobileVitalsFrequency:)`|`RUM.Configuration.vitalsUpdateFrequency`|
|`Atatus.Configuration.Builder.set(sampleTelemetry:)`|`RUM.Configuration.telemetrySampleRate`|

### Crash Reporting Changes

To enable Crash Reporting, make sure to also enable RUM and/or Logs.

```swift
import AtatusCrashReporting

CrashReporting.enable()
```

|`1.x`|`2.0`|
|---|---|
|`Atatus.Configuration.Builder.enableCrashReporting()`|`CrashReporting.enable()`|

### WebView Tracking Changes

To enable WebViewTracking, make sure to also enable RUM and/or Logs.

```swift
import WebKit
import AtatusWebViewTracking

let webView = WKWebView(...)
WebViewTracking.enable(webView: webView)
```

|`1.x`|`2.0`|
|---|---|
|`WKUserContentController.startTrackingAtatusEvents`|`WebViewTracking.enable(webView:)`|

### Using a Secondary Instance of the SDK

Previously Atatus SDK implemented a singleton and only one SDK instance could exist in the application process. This created obstacles for use-cases like the usage of the SDK by 3rd party libraries.

With version 2.0 we addressed this limitation:

* Now it is possible to initialize multiple instances of the SDK, associating them with a name.
* Many methods of the SDK can optionally take a SDK instance as an argument. If not provided, the call will be associated with the default (nameless) SDK instance.

Here is an example illustrating how to initialize a secondary core instance and enable products:

```swift
import AtatusCore
import AtatusRUM
import AtatusLogs
import AtatusTrace

let core = Atatus.initialize(
    with: configuration, 
    trackingConsent: trackingConsent, 
    instanceName: "my-instance"
)

RUM.enable(
    with: RUM.Configuration(applicationID: "<RUM Application ID>"),
    in: core
)

Logs.enable(in: core)

Trace.enable(in: core)
```

**Note**: The SDK instance name should have the same value between application runs. Storage paths for SDK events are associated with it.

Once initialized, you can retrieve the named SDK instance by calling `Atatus.sdkInstance(named: "<name>")` and use it for accessing the products.

```swift
import AtatusCore

let core = Atatus.sdkInstance(named: "my-instance")
```

#### Logs
```swift
import AtatusLogs

let logger = Logger.create(in: core)
```

#### Trace
```swift
import AtatusRUM

let monitor = RUMMonitor.shared(in: core)
```

#### RUM
```swift
import AtatusRUM

let monitor = RUMMonitor.shared(in: core)
```

[1]: /real_user_monitoring/session_replay/mobile/privacy_options?platform=ios