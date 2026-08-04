// 执行模式 27：main.dart 改为真实 API 入口。
// 启动顺序：EnvConfig → TokenStorage → ApiClient → AuthController → runApp。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/env/env_config.dart';
import 'core/settings/app_settings.dart';
import 'core/storage/token_storage.dart';
import 'core/ui/nexus_theme.dart';
import 'features/ai/ai_repository.dart';
import 'features/ai/local_ai_repository.dart';
import 'features/attachment/attachment_repository.dart';
import 'features/attachment/http_attachment_repository.dart';
import 'features/attachment/local_attachment_repository.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/http_auth_repository.dart';
import 'features/auth/local_auth_repository.dart';
import 'features/calendar/calendar_repository.dart';
import 'features/calendar/http_calendar_repository.dart';
import 'features/calendar/local_calendar_repository.dart';
import 'features/connector/connector_repository.dart';
import 'features/connector/local_connector_repository.dart';
import 'features/expert/expert_run_repository.dart';
import 'features/expert/http_expert_repository.dart';
import 'features/expert/http_expert_run_repository.dart';
import 'features/expert/local_expert_run_repository.dart';
import 'experts/expert_repository.dart';
import 'features/skill/http_skill_repository.dart';
import 'features/skill/local_skill_repository.dart';
import 'features/skill/skill_repository.dart';
import 'features/smart_home/http_smart_home_repository.dart';
import 'features/smart_home/local_smart_home_repository.dart';
import 'features/smart_home/smart_home_repository.dart';
import 'features/todo/http_todo_repository.dart';
import 'features/todo/local_todo_repository.dart';
import 'features/todo/todo_repository.dart';
import 'experts/mock_expert_repository.dart';
import 'router.dart';

const bool useLocalData = bool.fromEnvironment(
  'USE_LOCAL_DATA',
  defaultValue: true,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = await EnvConfig.init();
  final tokenStorage = await createTokenStorage();
  final settings = await AppSettings.load();
  final api = ApiClient(tokenStorage: tokenStorage, env: env);
  final AuthRepository authRepo = useLocalData
      ? LocalAuthRepository()
      : HttpAuthRepository(api);
  final auth = AuthController(
    apiClient: api,
    tokenStorage: tokenStorage,
    repository: authRepo,
  );
  await auth.bootstrap();

  runApp(
    NexusMindApp(
      auth: auth,
      env: env,
      tokenStorage: tokenStorage,
      api: api,
      settings: settings,
    ),
  );
}

class NexusMindApp extends StatelessWidget {
  const NexusMindApp({
    super.key,
    required this.auth,
    required this.env,
    required this.tokenStorage,
    required this.api,
    required this.settings,
  });

  final AuthController auth;
  final EnvConfig env;
  final TokenStorage tokenStorage;
  final ApiClient api;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final TodoRepository todoRepo = useLocalData
        ? LocalTodoRepository()
        : HttpTodoRepository(api);
    final CalendarRepository calendarRepo = useLocalData
        ? LocalCalendarRepository()
        : HttpCalendarRepository(api);
    final ExpertRepository expertRepo = useLocalData
        ? MockExpertRepository()
        : HttpExpertRepository(api);
    final ExpertRunRepository expertRunRepo = useLocalData
        ? LocalExpertRunRepository()
        : HttpExpertRunRepository(api);
    final SkillRepository skillRepo = useLocalData
        ? LocalSkillRepository()
        : HttpSkillRepository(api);
    final AiRepository aiRepo = useLocalData
        ? LocalAiRepository()
        : HttpAiRepository(api);
    final SmartHomeRepository smartHomeRepo = useLocalData
        ? LocalSmartHomeRepository()
        : HttpSmartHomeRepository(api);
    final ConnectorRepository connectorRepo = LocalConnectorRepository();
    final AttachmentRepository attachmentRepo = useLocalData
        ? LocalAttachmentRepository()
        : HttpAttachmentRepository(api);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EnvConfig>.value(value: env),
        ChangeNotifierProvider<AuthController>.value(value: auth),
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AppSettings>.value(value: settings),
        Provider<TodoRepository>.value(value: todoRepo),
        Provider<CalendarRepository>.value(value: calendarRepo),
        Provider<ExpertRepository>.value(value: expertRepo),
        Provider<ExpertRunRepository>.value(value: expertRunRepo),
        Provider<SkillRepository>.value(value: skillRepo),
        Provider<AiRepository>.value(value: aiRepo),
        Provider<SmartHomeRepository>.value(value: smartHomeRepo),
        Provider<ConnectorRepository>.value(value: connectorRepo),
        Provider<AttachmentRepository>.value(value: attachmentRepo),
      ],
      child: _Root(env: env),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.env});
  final EnvConfig env;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  Color _accent = NexusPalette.homeAccent;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final themeMode = settings.darkMode ? ThemeMode.dark : ThemeMode.light;
    final dark = NexusTheme.dark(_accent);
    final light = NexusTheme.light(_accent);

    final router = buildAppRouter(
      auth: context.read<AuthController>(),
      themeMode: themeMode,
      accent: _accent,
      onThemeChanged: (mode, accent) {
        _accent = accent;
        settings.setDarkMode(mode == ThemeMode.dark);
      },
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NexusMind',
      theme: light,
      darkTheme: dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class NexusMindShell extends StatelessWidget {
  const NexusMindShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _FloatingBottomBar(
        index: navigationShell.currentIndex,
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const items = [
    (Icons.home_outlined, 'Home'),
    (Icons.auto_awesome_outlined, 'AI'),
    (Icons.calendar_today_outlined, 'Plan'),
    (Icons.home_work_outlined, 'Home controls'),
    (Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final idleColor = theme.colorScheme.onSurfaceVariant;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = i == index;
            final item = items[i];
            return Tooltip(
              message: item.$2,
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? activeColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.$1,
                    size: 22,
                    color: selected ? activeColor : idleColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;
  static const items = [
    (Icons.home_rounded, '首页'),
    (Icons.auto_awesome_outlined, 'AI'),
    (Icons.calendar_today_outlined, '计划'),
    (Icons.home_work_outlined, '家庭'),
    (Icons.person_rounded, '我的'),
  ];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pillBg = isDark ? NexusPalette.homeAccent : NexusPalette.homeAccent;
    final pillFg = Colors.white;
    final idleColor = isDark
        ? const Color(0xffa4a2ad)
        : const Color(0xff6e6e73);
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == index;
          final item = items[i];
          return InkWell(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: selected ? pillBg : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, size: 21, color: selected ? pillFg : idleColor),
                  const SizedBox(height: 3),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? pillFg : idleColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
