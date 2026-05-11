import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/providers/dio_provider.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to initialize other things, do it here.
  // For now we just log the background message.
  print('Handling a background message: ${message.messageId}');
}

class PushNotificationService {
  final Dio _dio;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Navigation key for deep linking
  final GlobalKey<NavigatorState> navigatorKey;

  PushNotificationService(this._dio, this.navigatorKey);

  Future<void> initialize() async {
    // 1. Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // 2. Setup local notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _handleDeepLink(response.payload!);
        }
      },
    );

    // Create Android channel
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      
      final notification = message.notification;
      final android = message.notification?.android;
      
      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
      
      // If it's a silent data message to trigger sync
      if (message.data['action'] == 'sync') {
        // Trigger sync here
        print('Triggering background sync from FCM data message');
      }
    });

    // 4. Handle notification taps when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background via notification tap');
      _handleDeepLink(jsonEncode(message.data));
    });

    // 5. Handle notification taps when app is terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state via notification tap');
      // Delay slightly to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleDeepLink(jsonEncode(initialMessage.data));
      });
    }

    // 6. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleDeepLink(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      if (data.containsKey('job_id')) {
        final jobId = data['job_id'];
        final context = navigatorKey.currentContext;
        if (context != null) {
          context.push('/jobs/$jobId');
        }
      }
    } catch (e) {
      print('Error parsing deep link payload: $e');
    }
  }

  Future<void> sendDeviceTokenToBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Assuming your backend has an endpoint for updating the token
        // e.g. POST /api/auth/fcm-token/ with fcm_token
        await _dio.post('/auth/fcm-token/', data: {
          'fcm_token': token,
        });
      }
    } catch (e) {
      print('Failed to send FCM token to backend: $e');
    }
  }
}

// Global navigator key to be used in router and notification service
final rootNavigatorKey = GlobalKey<NavigatorState>();

final pushNotificationServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return PushNotificationService(dio, rootNavigatorKey);
});
