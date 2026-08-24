import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/settings/app_settings.dart';
import '../core/ui/nexus_theme.dart';
import '../features/auth/auth_controller.dart';

class HomeOverviewPage extends StatelessWidget {
  const HomeOverviewPage({super.key});

  @override
  Widget build(BuildContext context) => _PageFrame(
    children: const [
      _HomeGreeting(),
      SizedBox(height: NexusLayout.sectionGap),
      _HomeStatusCard(),
      SizedBox(height: NexusLayout.sectionGap),
      _SectionTitle(title: '今日建议'),
      SizedBox(height: NexusLayout.controlGap),
      _UnavailableCard(
        icon: Icons.auto_awesome_outlined,
        title: '暂无可执行动作',
        message: '不会在缺少服务端确认时推荐或执行场景。',
      ),
      SizedBox(height: NexusLayout.sectionGap),
      _SectionTitle(title: '最近场景'),
      SizedBox(height: NexusLayout.controlGap),
      _UnavailableCard(
        icon: Icons.history_outlined,
        title: '暂无记录',
        message: '已发布的场景结果会在执行完成后显示。',
      ),
    ],
  );
}

class ScenesPage extends StatelessWidget {
  const ScenesPage({super.key});

  @override
  Widget build(BuildContext context) => _PageFrame(
    children: const [
      NexusPageHeader(title: '场景', description: '用已确认的动作管理家中日常。'),
      SizedBox(height: NexusLayout.sectionGap),
      _CapabilityHero(
        icon: Icons.auto_awesome_outlined,
        eyebrow: '日常场景',
        title: '场景正在等待接入',
        message: '场景列表、影响范围和执行结果会在已发布接口接入后加载。',
      ),
    ],
  );
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) => _PageFrame(
    children: const [
      NexusPageHeader(title: '设备', description: '按空间查看已授权的家庭设备。'),
      SizedBox(height: NexusLayout.sectionGap),
      _CapabilityHero(
        icon: Icons.devices_other_outlined,
        eyebrow: '家庭设备',
        title: '尚无可显示设备',
        message: '已授权设备将在标准化设备接口可用后按空间显示。',
      ),
    ],
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final settings = context.watch<AppSettings>();
    final theme = Theme.of(context);
    final displayName = profile?.displayName ?? 'HomeMind 用户';
    return _PageFrame(
      children: [
        const NexusPageHeader(title: '我的', description: '管理你的使用偏好。'),
        const SizedBox(height: NexusLayout.sectionGap),
        NexusSurface(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.person_outline, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: theme.textTheme.titleLarge),
                    if ((profile?.timezone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile!.timezone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NexusLayout.sectionGap),
        const _SectionTitle(title: '偏好设置'),
        const SizedBox(height: NexusLayout.controlGap),
        NexusSurface(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('深色模式'),
                value: settings.darkMode,
                onChanged: settings.setDarkMode,
              ),
              Divider(height: 1, color: theme.dividerColor),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('语言'),
                trailing: DropdownButton<String>(
                  value: settings.language,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'zh-CN', child: Text('简体中文')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setLanguage(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NexusLayout.sectionGap),
        FilledButton.icon(
          onPressed: () async {
            await context.read<AuthController>().logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('退出登录'),
        ),
      ],
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: NexusLayout.pagePadding.copyWith(
          bottom: NexusLayout.bottomContentPadding + 24,
        ),
        children: children,
      ),
    ),
  );
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('你好', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                '从这里了解家中的状态。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _VisualIconTile(icon: Icons.home_outlined, size: 48),
      ],
    );
  }
}

class _HomeStatusCard extends StatelessWidget {
  const _HomeStatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '家庭状态尚未可用',
      child: Container(
        key: const ValueKey('home-status-card'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.home_outlined,
              color: theme.colorScheme.onInverseSurface,
              size: 28,
            ),
            const SizedBox(height: 28),
            Text(
              '等待家庭状态',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onInverseSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '服务端状态契约发布后，将在这里呈现家庭环境与设备摘要。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onInverseSurface.withValues(
                  alpha: 0.72,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityHero extends StatelessWidget {
  const _CapabilityHero({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NexusSurface(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisualIconTile(icon: icon, size: 52),
          const SizedBox(height: 24),
          Text(
            eyebrow,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisualIconTile(icon: icon, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualIconTile extends StatelessWidget {
  const _VisualIconTile({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.onPrimaryContainer,
        size: size * 0.48,
      ),
    );
  }
}
