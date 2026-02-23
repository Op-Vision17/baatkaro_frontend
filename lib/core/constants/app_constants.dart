import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Base URLs (from .env; fallback for production)
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://api.visiontrix.me';
  static String get socketUrl =>
      dotenv.env['SOCKET_URL'] ?? 'https://api.visiontrix.me';

  static String get agoraAppId => dotenv.env['AGORA_APP_ID'] ?? '';

  // Auth API Endpoints
  static const String sendOtpEndpoint = '/api/auth/send-otp';
  static const String verifyOtpEndpoint = '/api/auth/verify-otp';
  static const String completeOnboardingEndpoint =
      '/api/auth/complete-onboarding';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token';
  static const String profileEndpoint = '/api/auth/profile';
  static const String logoutEndpoint = '/api/auth/logout';

  // Room API Endpoints
  static const String createRoomEndpoint = '/api/room/create';
  static const String joinRoomEndpoint = '/api/room/join';
  static const String myRoomsEndpoint = '/api/room/my-rooms';

  /// Room-scoped paths (use with roomId)
  static String roomDetailEndpoint(String roomId) => '/api/room/$roomId';
  static String roomMessagesEndpoint(String roomId) =>
      '/api/room/$roomId/messages';
  static String roomLeaveEndpoint(String roomId) => '/api/room/$roomId/leave';

  // Upload API Endpoints
  static const String uploadImageEndpoint = '/api/upload/image';
  static const String uploadVoiceEndpoint = '/api/upload/voice';
  static const String uploadProfilePhotoEndpoint = '/api/upload/profile-photo';
  static const String uploadRoomPhotoEndpoint = '/api/upload/room-photo';

  // ✅ NEW: Call API Endpoints
  static const String generateAgoraTokenEndpoint = '/api/agora/generate-token';
  static const String callHistoryEndpoint = '/api/calls/history';

  // Notification API Endpoints
  static const String registerFcmTokenEndpoint =
      '/api/notifications/register-token';
  static const String unregisterFcmTokenEndpoint =
      '/api/notifications/remove-token';

  // SharedPreferences Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'userId';
  static const String userNameKey = 'userName';
  static const String userEmailKey = 'userEmail';
  static const String needsOnboardingKey = 'needs_onboarding';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // Socket Events (Existing)
  static const String joinRoomEvent = 'joinRoom';
  static const String sendMessageEvent = 'sendMessage';
  static const String receiveMessageEvent = 'receiveMessage';
  static const String onlineUsersEvent = 'onlineUsers';

  // ✅ NEW: Socket Events for Delete & Typing
  static const String deleteMessageEvent = 'deleteMessage';
  static const String messageDeletedEvent = 'messageDeleted';
  static const String typingEvent = 'typing';
  static const String typingUpdateEvent = 'typingUpdate';

  // ✅ NEW: Call Socket Events
  static const String startCallEvent = 'start_call';
  static const String joinCallEvent = 'join_call';
  static const String leaveCallEvent = 'leave_call';
  static const String rejectCallEvent = 'reject_call';
  static const String toggleAudioEvent = 'toggle_audio';
  static const String toggleVideoEvent = 'toggle_video';

  // ✅ NEW: Call Socket Listeners
  static const String incomingCallEvent = 'incoming_call';
  static const String callStartedEvent = 'call_started';
  static const String userJoinedCallEvent = 'user_joined_call';
  static const String userLeftCallEvent = 'user_left_call';
  static const String callParticipantsEvent = 'call_participants';
  static const String callRejectedEvent = 'call_rejected';
  static const String callEndedEvent = 'call_ended';
  static const String callErrorEvent = 'call_error';
  static const String userAudioChangedEvent = 'user_audio_changed';
  static const String userVideoChangedEvent = 'user_video_changed';
}
