import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // for web check
import 'package:flutter/services.dart'; // Required for PlatformException

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<String?> getDeviceId() async {
    String? deviceIdentifier;
    try {
      if (kIsWeb) {
        // Web doesn't have a stable, uniquely identifiable device ID in the same way as native apps.
        // Using a placeholder or a browser fingerprinting library might be options,
        // but they have limitations for strong anti-abuse.
        // For this exercise, we'll return a placeholder. In a real app, consider implications.
        print("[DeviceInfoService] Running on web. Returning placeholder device ID.");
        deviceIdentifier = 'web_device_placeholder_${DateTime.now().millisecondsSinceEpoch}'; 
        // A slightly more unique placeholder for web for demonstration if needed, 
        // but not truly a device ID.
        // Consider using a package like `fingerprintjs2` via JS interop for more robust browser fingerprinting.
      } else {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
          deviceIdentifier = androidInfo.id; // This is Settings.Secure.ANDROID_ID
          print("[DeviceInfoService] Android Device ID (androidId): $deviceIdentifier");
          // Notes on androidInfo.id:
          // - Can be null on some devices or emulators.
          // - Can change on factory reset.
          // - Can change if the user has multiple profiles on the device (rare).
          // - Generally does not require special permissions.
          // - If `androidInfo.id` is null or empty, you might consider a fallback,
          //   but other identifiers like `androidInfo.serialNumber` are heavily restricted
          //   and require `READ_PHONE_STATE` permission (and might not be available on Android 10+).
          //   For simplicity and fewer permissions, `androidInfo.id` is a common choice.
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
          deviceIdentifier = iosInfo.identifierForVendor; // UUID specific to the app vendor.
          print("[DeviceInfoService] iOS Device ID (identifierForVendor): $deviceIdentifier");
          // Notes on iosInfo.identifierForVendor:
          // - A UUID unique to the app's vendor on the device.
          // - Stays the same as long as at least one app from that vendor is installed.
          // - Will be different if all apps from that vendor are uninstalled and then one is reinstalled.
          // - Returns null if the value is not available (e.g. on simulator before a certain iOS version sometimes).
        } else if (Platform.isLinux) {
          LinuxDeviceInfo linuxInfo = await _deviceInfoPlugin.linuxInfo;
          deviceIdentifier = linuxInfo.machineId; // Often /etc/machine-id
          print("[DeviceInfoService] Linux Device ID (machineId): $deviceIdentifier");
        } else if (Platform.isMacOS) {
          MacOsDeviceInfo macOsInfo = await _deviceInfoPlugin.macOsInfo;
          deviceIdentifier = macOsInfo.systemGUID; 
          print("[DeviceInfoService] macOS Device ID (systemGUID): $deviceIdentifier");
        } else if (Platform.isWindows) {
          WindowsDeviceInfo windowsInfo = await _deviceInfoPlugin.windowsInfo;
          deviceIdentifier = windowsInfo.deviceId; // A per-app, per-user ID
          print("[DeviceInfoService] Windows Device ID (deviceId): $deviceIdentifier");
        } else {
          print("[DeviceInfoService] Unsupported platform for device ID retrieval.");
          deviceIdentifier = 'unsupported_platform_${DateTime.now().millisecondsSinceEpoch}';
        }
      }
    } on PlatformException catch (e) {
      // This can happen if the platform-specific code fails, e.g., permission issues (though less likely for these IDs)
      // or if the plugin is not correctly set up for the current platform.
      print('[DeviceInfoService] Failed to get device ID via PlatformException: ${e.message}');
      deviceIdentifier = 'platform_error_${DateTime.now().millisecondsSinceEpoch}';
    } 
    catch (e) {
      print('[DeviceInfoService] Failed to get device ID due to other error: $e');
      deviceIdentifier = 'generic_error_${DateTime.now().millisecondsSinceEpoch}';
    }

    if (deviceIdentifier == null || deviceIdentifier.isEmpty) {
        print("[DeviceInfoService] Device ID obtained was null or empty. Generating a fallback ID.");
        // Fallback for safety, though less ideal as it's not a true device/install ID
        deviceIdentifier = 'fallback_generated_${DateTime.now().millisecondsSinceEpoch}_${Platform.operatingSystem}';
    }
    
    return deviceIdentifier;
  }
}