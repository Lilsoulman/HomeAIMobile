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
import 'features/attachment/attachment_repository.dart';
import 'features/attachment/http_attachment_repository.dart';
import 'features/automation/automation_repository.dart';
import 'features/automation/http_automation_repository.dart';
import 'features/knowledge/http_knowledge_repository.dart';
import 'features/knowledge/knowledge_repository.dart';
import 'features/travel/http_travel_repository.dart';
import 'features/travel/travel_repository.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/http_auth_repository.dart';
import 'features/calendar/calendar_repository.dart';
import 'features/calendar/http_calendar_repository.dart';
import 'features/connector/connector_repository.dart';
import 'features/connector/http_connector_repository.dart';
import 'features/dashboard/dashboard_repository.dart';
import 'features/dashboard/http_dashboard_repository.dart';
import 'features/family/family_repository.dart';
import 'features/family/http_family_repository.dart';
import 'features/favorite/favorite_repository.dart';
import 'features/favorite/http_favorite_repository.dart';
import 'features/life/http_life_expert_repository.dart';
import 'features/life/life_expert_repository.dart';
import 'features/expert/expert_run_repository.dart';
import 'features/expert/http_expert_repository.dart';
import 'features/expert/http_expert_run_repository.dart';
import 'experts/expert_repository.dart';
import 'features/skill/http_skill_repository.dart';
import 'features/skill/skill_repository.dart';
import 'features/steward/http_steward_repository.dart';
import 'features/steward/steward_repository.dart';
import 'features/smart_home/http_smart_home_repository.dart';
import 'features/smart_home/smart_home_repository.dart';
import 'features/todo/http_todo_repository.dart';
import 'features/todo/todo_repository.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = await EnvConfig.init();
  final tokenStorage = await createTokenStorage();
  final settings = await AppSettings.load();
  final api = ApiClient(tokenStorage: tokenStorage, env: env);
  final auth = AuthController(
    apiClient: api,
    tokenStorage: tokenStorage,
    repository: HttpAuthRepository(api),
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
    final todoRepo = HttpTodoRepository(api);
    final calendarRepo = HttpCalendarRepository(api);
    final expertRepo = HttpExpertRepository(api);
    final expertRunRepo = HttpExpertRunRepository(api);
    final skillRepo = HttpSkillRepository(api);
    final aiRepo = HttpAiRepository(api);
    final smartHomeRepo = HttpSmartHomeRepository(api);
    final connectorRepo = HttpConnectorRepository(api);
    final attachmentRepo = HttpAttachmentRepository(api);
    final knowledgeRepo = HttpKnowledgeRepository(api);
    final automationRepo = HttpAutomationRepository(api);
    final travelRepo = HttpTravelRepository(api);
    final familyRepo = HttpFamilyRepository(
      api,
      homeIdOf: () => auth.tenantId ?? 0,
    );
    final stewardRepo = HttpStewardRepository(
      api,
      homeIdOf: () => auth.tenantId ?? 0,
    );
    final dashboardRepo = HttpDashboardRepository(api);
    final favoriteRepo = HttpFavoriteRepository(api);
    final lifeExpertRepo = HttpLifeExpertRepository(api);

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
        Provider<KnowledgeRepository>.value(value: knowledgeRepo),
        Provider<AutomationRepository>.value(value: automationRepo),
        Provider<TravelRepository>.value(value: travelRepo),
        Provider<FamilyRepository>.value(value: familyRepo),
        Provider<StewardRepository>.value(value: stewardRepo),
        Provider<DashboardRepository>.value(value: dashboardRepo),
        Provider<FavoriteRepository>.value(value: favoriteRepo),
        Provider<LifeExpertRepository>.value(value: lifeExpertRepo),
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
