import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'experts/domain.dart';
import 'experts/expert_repository.dart';
import 'features/ai/ai_repository.dart';
import 'features/attachment/attachment_repository.dart';
import 'features/automation/automation_repository.dart';
import 'features/calendar/calendar_repository.dart';
import 'features/expert/expert_run_repository.dart';
import 'features/knowledge/knowledge_repository.dart';
import 'features/todo/todo_repository.dart';
import 'features/travel/travel_repository.dart';
import 'features/auth/auth_controller.dart';
import 'main.dart';
import 'pages/app_pages.dart';
import 'pages/dashboard_page.dart';
import 'pages/home_plus_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/calendar_workspace_page.dart';
import 'pages/confirmation_center_page.dart';
import 'pages/connector_center_page.dart';
import 'pages/daily_knowledge_page.dart';
import 'pages/expert_workbench_page.dart';
import 'pages/family/family_knowledge_page.dart';
import 'pages/family/family_members_page.dart';
import 'pages/plan_page.dart';
import 'pages/travel_page.dart';
import 'pages/todo_workspace_page.dart';

GoRouter buildAppRouter({
  required AuthController auth,
  required ThemeMode themeMode,
  required Color accent,
  required void Function(ThemeMode, Color) onThemeChanged,
}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.isInitialized) return null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!auth.isLoggedIn) return isAuthRoute ? null : '/login';
      return isAuthRoute ? '/' : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            NexusMindShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: NexusHomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai',
                pageBuilder: (context, _) => NoTransitionPage(
                  child: ExpertCatalogPage(
                    repository: context.read<ExpertRepository>(),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'travel',
                    builder: (context, _) => TravelPage(
                      travelRepository: context.read<TravelRepository>(),
                      expertRepository: context.read<ExpertRepository>(),
                      runRepository: context.read<ExpertRunRepository>(),
                      automationRepository: context
                          .read<AutomationRepository>(),
                    ),
                  ),
                  GoRoute(
                    path: 'knowledge',
                    builder: (context, _) => DailyKnowledgePage(
                      expertRepository: context.read<ExpertRepository>(),
                      runRepository: context.read<ExpertRunRepository>(),
                      knowledgeRepository: context.read<KnowledgeRepository>(),
                      automationRepository: context
                          .read<AutomationRepository>(),
                    ),
                  ),
                  GoRoute(
                    path: ':expertId',
                    builder: (context, state) {
                      final sourceType =
                          state.uri.queryParameters['type'] == 'group'
                          ? ExpertSourceType.group
                          : ExpertSourceType.expert;
                      return ExpertWorkspacePage(
                        repository: context.read<ExpertRepository>(),
                        runRepository: context.read<ExpertRunRepository>(),
                        attachmentRepository: context
                            .read<AttachmentRepository>(),
                        expertId: state.pathParameters['expertId']!,
                        sourceType: sourceType,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: PlanPage()),
                routes: [
                  GoRoute(
                    path: 'todos',
                    builder: (context, _) => TodoWorkspacePage(
                      repository: context.read<TodoRepository>(),
                      aiRepository: context.read<AiRepository>(),
                    ),
                  ),
                  GoRoute(
                    path: 'calendar',
                    builder: (context, _) => CalendarWorkspacePage(
                      repository: context.read<CalendarRepository>(),
                      todoRepository: context.read<TodoRepository>(),
                    ),
                  ),
                  GoRoute(
                    path: 'confirmations',
                    builder: (_, _) => const ConfirmationCenterPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home-plus',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: HomePlusPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                pageBuilder: (_, _) => NoTransitionPage(
                  child: ProfilePage(
                    themeMode: themeMode,
                    accent: accent,
                    onThemeChanged: onThemeChanged,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'connectors',
                    builder: (context, _) => const ConnectorCenterPage(),
                  ),
                  GoRoute(
                    path: 'family-members',
                    builder: (_, _) => const FamilyMembersPage(),
                  ),
                  GoRoute(
                    path: 'family-knowledge',
                    builder: (_, _) => const FamilyKnowledgePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
