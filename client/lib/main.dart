import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const ProviderScope(child: ClientPulseApp()));
}

class ClientPulseApp extends ConsumerStatefulWidget {
  const ClientPulseApp({super.key});

  @override
  ConsumerState<ClientPulseApp> createState() => _ClientPulseAppState();
}

class _ClientPulseAppState extends ConsumerState<ClientPulseApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = ref.read(routerProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClientPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: _router,
    );
  }
}
