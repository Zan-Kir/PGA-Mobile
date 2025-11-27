import 'package:flutter/material.dart';

/// Widget que exibe um card de projeto com status, progresso e informações básicas.
/// 
/// O progresso é calculado automaticamente no ProjectsScreen baseado em:
/// - Etapas concluídas (peso 60%)
/// - Tempo decorrido do projeto (peso 40%)
/// 
/// Se todas as etapas estiverem concluídas, o status é automaticamente "Concluído".
class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project['name'] ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Builder(builder: (bCtx) {
                    final status = (project['status'] ?? '').toString();
                    final style = _statusStyle(status, theme);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: style.background,
                        borderRadius: BorderRadius.circular(20),
                        border: style.borderColor == null ? null : Border.all(color: style.borderColor!, width: 1.4),
                      ),
                      child: Text(
                        project['status'] ?? '',
                        style: theme.textTheme.labelSmall?.copyWith(color: style.textColor, fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progresso', style: theme.textTheme.bodySmall),
                      Text('${project['progress'] ?? 0}%', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (project['progress'] ?? 0) / 100.0,
                      backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(_statusStyle((project['status'] ?? '').toString(), theme).progressColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prazo', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(project['deadline'] ?? 'N/A', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Responsável', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(project['responsible'] ?? '—', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String status, ThemeData theme) {
    final s = status.toLowerCase();
    const blue = Color(0xFF2196F3);
    const green = Color(0xFF4CAF50);
    const orange = Color(0xFFFF9800);

    final isDark = theme.brightness == Brightness.dark;

    if (s.contains('andam')) {
      return _StatusStyle(
        background: theme.colorScheme.surface,
        borderColor: blue,
        textColor: blue,
        progressColor: blue,
      );
    }

    if (s.contains('concl')) {
      return _StatusStyle(
        background: green.withValues(alpha: isDark ? 0.22 : 0.20),
        borderColor: null,
        textColor: isDark ? theme.colorScheme.onPrimary : const Color(0xFF1B5E20),
        progressColor: green,
      );
    }

    if (s.contains('atr')) {
      return _StatusStyle(
        background: orange.withValues(alpha: isDark ? 0.22 : 0.18),
        borderColor: null,
        textColor: isDark ? theme.colorScheme.onPrimary : const Color(0xFFBF360C),
        progressColor: orange,
      );
    }

    return _StatusStyle(
      background: theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
      borderColor: null,
      textColor: theme.colorScheme.onPrimary,
      progressColor: theme.colorScheme.primary,
    );
  }

}

class _StatusStyle {
  final Color background;
  final Color? borderColor;
  final Color textColor;
  final Color progressColor;

  const _StatusStyle({required this.background, this.borderColor, required this.textColor, required this.progressColor});
}
