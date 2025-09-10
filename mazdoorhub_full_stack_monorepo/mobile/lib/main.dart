import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/services.dart';
import 'screens/jobs_screen.dart';
import 'screens/job_post_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/wallet_screen.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(i18nProvider);
    return Directionality(
      textDirection: settings.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: MaterialApp(
        title: t['app_title']!,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: settings.rtl ? 1.1 : 1.0),
          useMaterial3: true,
        ),
        home: const JobsScreen(),
        routes: {
          JobsScreen.route: (_) => const JobsScreen(),
          JobPostScreen.route: (_) => const JobPostScreen(),
          ChatScreen.route: (_) => const ChatScreen(),
          WalletScreen.route: (_) => const WalletScreen(),
        },
      ),
    );
  }
}
