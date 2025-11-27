import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const BottomNavigation({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final routes = [
      {
        'key': '/dashboard',
        'title': 'Dashboard',
        'icon': Icons.dashboard,
        'activeIcon': Icons.dashboard,
      },
      {
        'key': '/projects',
        'title': 'Projetos',
        'icon': Icons.folder,
        'activeIcon': Icons.folder,
      },
      {
        'key': '/create-project',
        'title': 'Criar',
        'icon': Icons.add_circle,
        'activeIcon': Icons.add_circle,
      },
      {
        'key': '/settings',
        'title': 'Config',
        'icon': Icons.settings,
        'activeIcon': Icons.settings,
      },
    ];

    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: routes.map((route) {
              final isActive = route['key'] == currentRoute;
              return Expanded(
                child: InkWell(
                  onTap: () => onNavigate(route['key'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? route['activeIcon'] as IconData : route['icon'] as IconData,
                          size: 24,
                          color: isActive ? theme.colorScheme.primary : theme.iconTheme.color?.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          route['title'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
