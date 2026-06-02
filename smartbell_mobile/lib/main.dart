import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'core/network/api_client.dart';
import 'core/network/app_router.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/jwt_interceptor.dart';
import 'core/storage/hive_service.dart';
import 'core/services/device_token_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/adherent/training/providers/training_provider.dart';

// Gérer les notifications reçues quand l'app est en arrière-plan/fermée
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('fr_TN', null);
  await HiveService.initHive();

  // Initialiser Firebase (mobile uniquement — pas Windows ni Web)
  final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  if (isMobile) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {
      // Firebase non configuré — l'app continue sans FCM
    }
  }

  DioClient.instance.init();
  ApiClient().init();
  runApp(
    const ProviderScope(
      child: SmartBellApp(),
    ),
  );
}

class SmartBellApp extends StatefulWidget {
  const SmartBellApp({super.key});

  @override
  State<SmartBellApp> createState() => _SmartBellAppState();
}

class _SmartBellAppState extends State<SmartBellApp> {
  late final AuthProvider _auth;
  late final GoRouter _router;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    JwtInterceptor.onUnauthorized = () => _auth.logout();
    _initApp();
  }

  Future<void> _initApp() async {
    const bool showOnboarding = false;
    
    await _auth.tryAutoLogin();

    // Enregistrer le token FCM si l'user est connecté
    if (_auth.isAuth) {
      await DeviceTokenService.registerToken();
    }

    if (mounted) {
      _router = createAppRouter(_auth, showOnboarding);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    if (_isInitialized) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF111111),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFEF9F27)),
          ),
        ),
      );
    }
    
    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        legacy_provider.ChangeNotifierProvider(create: (_) => TrainingProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp.router(
        title: 'SmartBell Gym',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
