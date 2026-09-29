import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'config/constants.dart';
import 'models/models.dart';
import 'providers/providers.dart';
import 'services/services.dart';
import 'ui/screens/screens.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/widgets.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }

  // Ensure ApiService uses the loaded AppConfig.apiUrl
  ApiService().updateBaseUrl(AppConfig.apiUrl);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FCMService().initialize();
  } catch (e) {
    debugPrint("Firebase init: $e");
  }

  runApp(const NexoraApp());
}

class NexoraApp extends StatefulWidget {
  const NexoraApp({super.key});

  @override
  State<NexoraApp> createState() => _NexoraAppState();
}

class _NexoraAppState extends State<NexoraApp> {
  final CallProvider _callProvider = CallProvider();

  @override
  void initState() {
    super.initState();
    FCMService().processPendingNotification((data, actionId) {
      final type = data['type'];
      if (type == 'CALL_INCOMING') {
        final autoAnswer = actionId == 'answer_call';
        _callProvider.handleIncomingCallFromPush(data, autoAnswer: autoAnswer);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => SocketProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider.value(value: _callProvider),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'Nexora Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          return Consumer<CallProvider>(
            builder: (context, call, _) {
              return Stack(
                children: [
                  ?child,
                  if (call.callStatus == CallStatus.incoming)
                    const IncomingCallDialog(),
                ],
              );
            },
          );
        },
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading && !auth.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Nexora',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const HomeScreen();
    }

    return const LandingScreen();
  }
}
