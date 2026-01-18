import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCallPermissions({
    required bool isVideoCall,
  }) async {
    print('🔐 Requesting call permissions...');
    print('   Video call: $isVideoCall');

    // Request microphone permission (required for both audio and video)
    final micStatus = await Permission.microphone.request();
    
    if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
      print('❌ Microphone permission denied');
      return false;
    }

    // If video call, also request camera permission
    if (isVideoCall) {
      final cameraStatus = await Permission.camera.request();
      
      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        print('❌ Camera permission denied');
        return false;
      }
    }

    print('✅ All required permissions granted');
    return true;
  }

  static Future<bool> checkCallPermissions({
    required bool isVideoCall,
  }) async {
    final micStatus = await Permission.microphone.status;
    
    if (!micStatus.isGranted) return false;
    
    if (isVideoCall) {
      final cameraStatus = await Permission.camera.status;
      return cameraStatus.isGranted;
    }
    
    return true;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}