import 'dart:convert';
import 'package:http/http.dart' as http;

class RemoteLoggerService {
  static const String _lokiEndpoint =
      'https://logs.heymenu.org/loki/api/v1/push';
  static const String _appName = 'reado';
  static const bool _isEnabled = true;

  // Context (set after login)
  static String? _userId;
  static String? _userEmail;
  static String? _userName;
  static String? _currentScreen;

  /// Call after user logs in.
  static void setUserContext({
    required String userId,
    String? email,
    String? displayName,
  }) {
    _userId = userId;
    _userEmail = email;
    _userName = displayName;
  }

  /// Call on screen changes.
  static void setScreen(String screenName) {
    _currentScreen = screenName;
  }

  /// Call on logout.
  static void clearContext() {
    _userId = null;
    _userEmail = null;
    _userName = null;
    _currentScreen = null;
  }

  // =============================================
  // MAIN LOG METHOD
  // =============================================
  static Future<void> log({
    required String level,
    required String message,
    String? screen,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isEnabled || _lokiEndpoint.isEmpty) return;

    final timestamp = DateTime.now().microsecondsSinceEpoch * 1000;

    final effectiveScreen = screen ?? _currentScreen ?? 'unknown';

    final streamLabels = {
      'app': _appName,
      'level': level,
      'platform': 'flutter',
      'user_id': _userId ?? 'unknown',
      'user_email': _userEmail ?? 'unknown',
      'screen': effectiveScreen,
    };

    final logData = <String, dynamic>{
      'msg': message,
      if (_userId != null) 'user_id': _userId,
      if (_userEmail != null) 'user_email': _userEmail,
      if (_userName != null) 'user_name': _userName,
      'screen': effectiveScreen,
      ...?extra,
    };
    logData.removeWhere((key, value) => value == null);

    final payload = {
      'streams': [
        {
          'stream': streamLabels,
          'values': [
            [timestamp.toString(), jsonEncode(logData)]
          ],
        }
      ]
    };

    try {
      await http.post(
        Uri.parse(_lokiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Fire-and-forget: never block the app
    }
  }

  // =============================================
  // SHORTCUT METHODS
  // =============================================

  static void info(String msg, {String? screen, Map<String, dynamic>? extra}) =>
      log(level: 'info', message: msg, screen: screen, extra: extra);

  static void error(String msg,
          {String? screen, dynamic error, StackTrace? stackTrace}) =>
      log(
        level: 'error',
        message: msg,
        screen: screen,
        extra: {
          if (error != null) 'error': error.toString(),
          if (stackTrace != null) 'stack_trace': stackTrace.toString(),
        },
      );

  static void warning(String msg, {String? screen}) =>
      log(level: 'warning', message: msg, screen: screen);

  static void userAction(String action,
          {String? screen, Map<String, dynamic>? details}) =>
      log(
        level: 'info',
        message: action,
        screen: screen,
        extra: {'type': 'user_action', ...?details},
      );

  // =============================================
  // BOOKPULSE-SPECIFIC METHODS
  // =============================================

  /// Auth events (login, register, logout)
  static void auth(String event, {String? method, String? errorMsg}) =>
      log(
        level: errorMsg != null ? 'error' : 'info',
        message: event,
        screen: 'auth',
        extra: {
          'type': 'auth',
          if (method != null) 'method': method,
          if (errorMsg != null) 'error': errorMsg,
        },
      );

  /// Book events (search, add, edit, remove, status change)
  static void book(String event,
          {String? bookId, String? bookTitle, String? screen, Map<String, dynamic>? details}) =>
      log(
        level: 'info',
        message: event,
        screen: screen ?? 'library',
        extra: {
          'type': 'book',
          if (bookId != null) 'book_id': bookId,
          if (bookTitle != null) 'book_title': bookTitle,
          ...?details,
        },
      );

  /// Focus session events (start, pause, resume, stop, complete)
  static void focus(String event,
          {String? bookTitle, int? durationMinutes, int? pagesRead, int? xpEarned}) =>
      log(
        level: 'info',
        message: event,
        screen: 'focus',
        extra: {
          'type': 'focus',
          if (bookTitle != null) 'book_title': bookTitle,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (pagesRead != null) 'pages_read': pagesRead,
          if (xpEarned != null) 'xp_earned': xpEarned,
        },
      );

  /// Challenge events (join, leave, create, complete)
  static void challenge(String event,
          {String? challengeId, String? challengeTitle, String? challengeType}) =>
      log(
        level: 'info',
        message: event,
        screen: 'challenge',
        extra: {
          'type': 'challenge',
          if (challengeId != null) 'challenge_id': challengeId,
          if (challengeTitle != null) 'challenge_title': challengeTitle,
          if (challengeType != null) 'challenge_type': challengeType,
        },
      );

  /// Social events (friend request, accept, remove)
  static void social(String event, {Map<String, dynamic>? details}) =>
      log(
        level: 'info',
        message: event,
        screen: 'social',
        extra: {'type': 'social', ...?details},
      );

  /// Profile events (update goal, calm mode, etc.)
  static void profile(String event, {Map<String, dynamic>? details}) =>
      log(
        level: 'info',
        message: event,
        screen: 'profile',
        extra: {'type': 'profile', ...?details},
      );
}
