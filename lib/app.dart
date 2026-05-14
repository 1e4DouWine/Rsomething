import 'dart:async';

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

/// 应用根组件
///
/// 负责：
/// 1. 配置 Provider 状态管理（MemoryProvider、ExpenseProvider、TodoProvider、AIProvider）
/// 2. 设置 Material 3 主题（亮色/暗色自适应）
/// 3. 监听系统分享事件，自动导航到分享处理页面
/// 4. 处理应用启动时的初始分享内容
class MyApp extends StatefulWidget {
  /// 设置服务实例
  final SettingsService settingsService;

  /// 应用启动时通过系统分享传入的媒体内容（可选）
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
  StreamSubscription<SharedMedia>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _setupShareListener();
  }

  /// 设置系统分享监听器
  /// 监听运行时的分享事件（非冷启动），收到分享内容后导航到处理页面
  void _setupShareListener() {
    ShareHandlerPlatform.instance.resetInitialSharedMedia();
    _shareSubscription = ShareHandlerPlatform.instance.sharedMediaStream.listen(
      (media) {
        if (!mounted) return;
        final text = media.content;
        final images = _extractAttachmentPaths(media);
        if (text != null || images.isNotEmpty) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) =>
                  ShareReceiverScreen(sharedText: text, sharedImages: images),
            ),
          );
        }
      },
    );
  }

  /// 提取系统分享附件中的本地文件路径。
  ///
  /// `share_handler` 的附件项和路径都可能为空，统一在这里过滤，避免页面构建处使用非空断言。
  List<String> _extractAttachmentPaths(SharedMedia media) {
    return media.attachments
            ?.map((attachment) => attachment?.path)
            .whereType<String>()
            .toList() ??
        const <String>[];
  }

  /// 根据冷启动分享内容决定首页。
  Widget _buildHome() {
    final initialMedia = widget.initialSharedMedia;
    if (initialMedia == null) return const MainScreen();

    return ShareReceiverScreen(
      sharedText: initialMedia.content,
      sharedImages: _extractAttachmentPaths(initialMedia),
    );
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  /// 全局 Navigator Key，用于在监听器中进行页面导航
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(
          create: (_) => AIProvider(widget.settingsService),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'RS 智能助手',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // 如果有初始分享内容，直接显示分享处理页面；否则显示主页面
        home: _buildHome(),
      ),
    );
  }
}

/// 主页面（底部导航栏容器）
///
/// 包含四个标签页：记忆流、账本、待办、我的
/// 使用 IndexedStack 保持各页面状态
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// 当前选中的标签页索引
  int _currentIndex = 0;

  /// 标签页列表
  final List<Widget> _screens = const [
    MemoryFlowScreen(),
    ExpenseScreen(),
    TodoScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 IndexedStack 保持所有页面状态，避免切换时重建
      body: IndexedStack(index: _currentIndex, children: _screens),
      // Material 3 底部导航栏
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
