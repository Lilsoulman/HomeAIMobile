import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/env/build_config.dart';
import 'core/env/env_config.dart';
import 'core/settings/app_settings.dart';
import 'core/storage/token_storage.dart';
import 'core/ui/nexus_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/http_auth_repository.dart';
import 'features/smart_home/http_smart_home_repository.dart';
import 'features/smart_home/smart_home_repository.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BuildConfig.initialize(nativeFlavor: appFlavor);
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
    HomeMindApp(
      auth: auth,
      env: env,
      tokenStorage: tokenStorage,
      api: api,
      settings: settings,
    ),
  );
}

class HomeMindApp extends StatelessWidget {
  const HomeMindApp({
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
    final smartHomeRepository = HttpSmartHomeRepository(api);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EnvConfig>.value(value: env),
        ChangeNotifierProvider<AuthController>.value(value: auth),
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AppSettings>.value(value: settings),
        Provider<SmartHomeRepository>.value(value: smartHomeRepository),
      ],
      child: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  final Color _accent = NexusPalette.homeAccent;
  late final GoRouter _router;
  var _routerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routerInitialized) {
      _router = buildAppRouter(auth: context.read<AuthController>());
      _routerInitialized = true;
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final themeMode = settings.darkMode ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HomeMind',
      theme: NexusTheme.light(_accent),
      darkTheme: NexusTheme.dark(_accent),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

class HomeMindShell extends StatelessWidget {
  const HomeMindShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: navigationShell,
    floatingActionButton: FloatingActionButton(
      tooltip: '语音控制',
      onPressed: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('语音控制将在服务端契约发布后提供。'))),
      child: const Icon(Icons.mic_none_outlined),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: _FloatingBottomBar(
      index: navigationShell.currentIndex,
      onSelect: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
    ),
  );
}

class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_outlined, Icons.home, '首页'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, '场景'),
    (Icons.devices_other_outlined, Icons.devices_other, '设备'),
    (Icons.person_outline, Icons.person, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                item: _items[0],
                selected: index == 0,
                onTap: () => onSelect(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                item: _items[1],
                selected: index == 1,
                onTap: () => onSelect(1),
              ),
            ),
            const SizedBox(width: 72),
            Expanded(
              child: _NavItem(
                item: _items[2],
                selected: index == 2,
                onTap: () => onSelect(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                item: _items[3],
                selected: index == 3,
                onTap: () => onSelect(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final (IconData, IconData, String) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.$3,
      child: InkWell(
        borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? item.$2 : item.$1, color: color),
            const SizedBox(height: 4),
            Text(
              item.$3,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
