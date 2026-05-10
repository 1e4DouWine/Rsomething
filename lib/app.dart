import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_handler/share_handler.dart';
import 'providers/providers.dart';
import 'services/settings_service.dart';
import 'screens/memory_flow/memory_flow_screen.dart';
import 'screens/expense/expense_screen.dart';
import 'screens/todo/todo_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/share_receiver_screen.dart';
import 'theme/app_theme.dart';

class MyApp extends StatefulWidget {
  final SettingsService settingsService;
  final SharedMedia? initialSharedMedia;

  const MyApp({
    super.key,
    required this.settingsService,
    this.initialSharedMedia,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupShareListener();
  }

  void _setupShareListener() {
    ShareHandlerPlatform.instance.resetInitialSharedMedia();
    ShareHandlerPlatform.instance.sharedMediaStream.listen((media) {
      if (!mounted) return;
      final text = media.content;
      final images = media.attachments
              ?.where((a) => a?.path != null)
              .map((a) => a!.path)
              .toList() ??
          [];
      if (text != null || images.isNotEmpty) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ShareReceiverScreen(
              sharedText: text,
              sharedImages: images,
            ),
          ),
        );
      }
    });
  }

  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider(widget.settingsService)),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'RS 智能助手',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: widget.initialSharedMedia != null
            ? ShareReceiverScreen(
                sharedText: widget.initialSharedMedia!.content,
                sharedImages: widget.initialSharedMedia!.attachments
                        ?.where((a) => a?.path != null)
                        .map((a) => a!.path)
                        .toList() ??
                    [],
              )
            : const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MemoryFlowScreen(),
    ExpenseScreen(),
    TodoScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '记忆流',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '账本',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
