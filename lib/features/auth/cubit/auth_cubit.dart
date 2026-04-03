import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/reading_reminder_service.dart';
import '../../../core/services/remote_logger_service.dart';
import '../../../core/services/user_profile_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final UserProfileService _profileService;
  final NotificationService _notificationService;
  final ReadingReminderService _readingReminderService;
  StreamSubscription<User?>? _authSubscription;
  AppLifecycleListener? _lifecycleListener;

  AuthCubit({
    required AuthService authService,
    required UserProfileService profileService,
    required NotificationService notificationService,
    required ReadingReminderService readingReminderService,
  })  : _authService = authService,
        _profileService = profileService,
        _notificationService = notificationService,
        _readingReminderService = readingReminderService,
        super(const AuthState()) {
    _listenToAuthChanges();
    _setupLifecycleListener();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (user != null) {
        RemoteLoggerService.setUserContext(
          userId: user.uid,
          email: user.email,
          displayName: user.displayName,
        );
        emit(AuthState(status: AuthStatus.authenticated, user: user));
        // Request permission and save FCM token after authentication
        await _notificationService.requestPermissionAndSetup();
        // Request local notification permissions (actual scheduling is done
        // from ShellScreen with correct locale strings on every app resume)
        await _readingReminderService.requestPermissions();
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        // Cancel reminders on sign-out
        await _readingReminderService.cancelAll();
      }
    });
  }


  void _setupLifecycleListener() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        // Refresh FCM token every time app comes to foreground
        if (state.status == AuthStatus.authenticated) {
          _notificationService.refreshFcmToken();
        }
      },
    );
  }

  Future<void> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      await _profileService.createProfile();
      RemoteLoggerService.auth('User registered', method: 'email');
    } on FirebaseAuthException catch (e) {
      RemoteLoggerService.auth('Register failed', method: 'email', errorMsg: e.code);
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.code,
      ));
    } catch (e) {
      RemoteLoggerService.auth('Register failed', method: 'email', errorMsg: e.toString());
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      await _profileService.createProfile();
      RemoteLoggerService.auth('User signed in', method: 'email');
    } on FirebaseAuthException catch (e) {
      RemoteLoggerService.auth('Sign in failed', method: 'email', errorMsg: e.code);
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.code,
      ));
    } catch (e) {
      RemoteLoggerService.auth('Sign in failed', method: 'email', errorMsg: e.toString());
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authService.signInWithGoogle();
      await _profileService.createProfile();
      RemoteLoggerService.auth('User signed in', method: 'google');
    } on SignInCancelledException {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } on FirebaseAuthException catch (e) {
      RemoteLoggerService.auth('Sign in failed', method: 'google', errorMsg: e.code);
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.code,
      ));
    } catch (e) {
      RemoteLoggerService.auth('Sign in failed', method: 'google', errorMsg: e.toString());
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signInWithApple() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authService.signInWithApple();
      await _profileService.createProfile();
      RemoteLoggerService.auth('User signed in', method: 'apple');
    } on SignInWithAppleAuthorizationException {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } on FirebaseAuthException catch (e) {
      RemoteLoggerService.auth('Sign in failed', method: 'apple', errorMsg: e.code);
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.code,
      ));
    } catch (e) {
      RemoteLoggerService.auth('Sign in failed', method: 'apple', errorMsg: e.toString());
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.code,
      ));
    }
  }

  Future<void> signOut() async {
    RemoteLoggerService.auth('User signed out');
    RemoteLoggerService.clearContext();
    await _authService.signOut();
  }

  void clearError() {
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    ));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _lifecycleListener?.dispose();
    return super.close();
  }
}
