import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'l10n/generated/app_localizations.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/service_locator.dart';
import 'core/services/focus_notification_service.dart';
import 'core/services/reading_reminder_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/remote_logger_service.dart';
import 'features/auth/cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize timezone data (used by all scheduled local notifications)
  tz_data.initializeTimeZones();
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

  // Register FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  setupServiceLocator();

  // Create FCM notification channel early so Android can display
  // push notifications even before the Flutter foreground listener starts.
  final flnp = FlutterLocalNotificationsPlugin();
  final androidPlugin = flnp
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'fcm_default',
        'Notifications',
        description: 'Push notifications from Bookpulse',
        importance: Importance.high,
      ),
    );
  }

  // Set up FCM foreground listener early so messages are always received
  await getIt<NotificationService>().setupForegroundListener();

  // Initialize local notifications for focus timer & reading reminders
  await getIt<FocusNotificationService>().init();
  await getIt<ReadingReminderService>().init();
  RemoteLoggerService.info('App started', screen: 'main');
  runApp(const BookpulseApp());
}

class BookpulseApp extends StatelessWidget {
  const BookpulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: BlocProvider(
        create: (_) => getIt<AuthCubit>(),
        child: MaterialApp.router(
          title: 'Bookpulse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('tr')],
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
