import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../widgets/stats_card.dart';
import '../widgets/project_card.dart';
import '../widgets/bottom_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeTab = 'overview';

  final List<Map<String, dynamic>> _mockStats = [
    {'title': 'Total de Projetos', 'value': '12', 'icon': '📊', 'color': const Color(0xFF4CAF50)},
    {'title': 'Em Andamento', 'value': '8', 'icon': '🚀', 'color': const Color(0xFF2196F3)},
    {'title': 'Concluídos', 'value': '3', 'icon': '✅', 'color': const Color(0xFF4CAF50)},
    {'title': 'Atrasados', 'value': '1', 'icon': '⚠️', 'color': const Color(0xFFFF9800)},
  ];

  final List<Map<String, dynamic>> _mockProjects = [
    {
      'id': '1',
      'name': 'Sistema de Gestão Acadêmica',
      'progress': 75,
      'status': 'Em andamento',
      'deadline': '15/03/2025',
      'responsible': 'Ana Silva',
    },
    {
      'id': '2',
      'name': 'Modernização Laboratórios',
      'progress': 45,
      'status': 'Em andamento',
      'deadline': '28/02/2025',
      'responsible': 'Carlos Santos',
    },
    {
      'id': '3',
      'name': 'Portal de Comunicação',
      'progress': 20,
      'status': 'Em andamento',
      'deadline': '10/02/2025',
      'responsible': 'Maria Oliveira',
    },
  ];

  Widget _buildOverview() {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final effectiveScale = math.min(1.0, textScale);
    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;

          final crossAxisCount = width > 1100 ? 4 : 2;
          final baseRatio = width > 600 ? 1.05 : 1.0;
          final scaleFactor = 1.0 + (1.0 - textScale ) * 2;
          final childAspectRatio = (baseRatio * scaleFactor).clamp(1.0, 2.0);
          final gridSpacing = (12 * effectiveScale).clamp(4.0, 18.0);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _mockStats.length,
            itemBuilder: (context, index) {
              final stat = _mockStats[index];
              return StatsCard(
                title: stat['title'],
                value: stat['value'],
                icon: stat['icon'],
                color: stat['color'],
              );
            },
          );
        }),

        SizedBox(height: (24 * effectiveScale).clamp(6.0, 40.0)),

        Builder(builder: (ctx) {
          final theme = Theme.of(ctx);
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(20 * effectiveScale),
              child: LayoutBuilder(builder: (c2, cons) {
                final maxW = cons.maxWidth;
                final itemWidth = math.min((maxW - 32) / 3, 260.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IDENTIFICAÇÃO DA UNIDADE',
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 20 * effectiveScale),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        SizedBox(width: itemWidth, child: const _InfoItem(label: 'Código', value: 'F301')),
                        SizedBox(width: itemWidth, child: const _InfoItem(label: 'Unidade', value: 'Fatec Votorantim')),
                        SizedBox(width: itemWidth, child: const _InfoItem(label: 'Diretor(a)', value: 'Prof. Dr. Mauro Tomazela')),
                      ],
                    ),
                  ],
                );
              }),
            ),
          );
        }),

        SizedBox(height: (24 * effectiveScale).clamp(6.0, 40.0)),

        Align(
          alignment: Alignment.centerLeft,
          child: Text('Projetos em Destaque', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),

        SizedBox(height: (16 * effectiveScale).clamp(6.0, 24.0)),

        ..._mockProjects.take(2).map((project) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProjectCard(
            project: project,
            onTap: () => context.go('/projects'),
          ),
        )),
      ],
    );
  }

  Widget _buildProjects() {
    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: Text('Todos os Projetos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),

        const SizedBox(height: 16),

        ..._mockProjects.map((project) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProjectCard(
            project: project,
            onTap: () => context.go('/projects'),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard PGA 2025'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _activeTab = 'overview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeTab == 'overview' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                      foregroundColor: _activeTab == 'overview' ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Visão Geral'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _activeTab = 'projects'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeTab == 'projects' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                      foregroundColor: _activeTab == 'projects' ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Projetos'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _activeTab == 'overview' ? _buildOverview() : _buildProjects(),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigation(
        currentRoute: '/dashboard',
        onNavigate: (route) {
          if (route == '/dashboard') return;
          context.go(route);
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
          textAlign: TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      ],
    );
  }
}
