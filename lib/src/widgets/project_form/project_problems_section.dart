import 'package:flutter/material.dart';
import '../../controllers/create_project_controller.dart';
import '../common/form_field_builder.dart';

class ProjectProblemsSection extends StatelessWidget {
  final CreateProjectController controller;

  const ProjectProblemsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      'Situação Problema / Oportunidade de Melhoria Associada',
      [
        const SizedBox(height: 16),
        ...controller.problemSituations.asMap().entries.map((entry) {
          final index = entry.key;
          final situacao = entry.value;
          return _buildProblemSituationField(situacao, index, controller);
        }),
        
        const SizedBox(height: 16),
        
        Align(
          alignment: Alignment.centerRight,
          child: Builder(builder: (context) {
            final theme = Theme.of(context);
            return ElevatedButton.icon(
              onPressed: controller.addProblemSituation,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar Situação'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProblemSituationField(
    Map<String, dynamic> situacao,
    int index,
    CreateProjectController controller,
  ) {
    final situationId = situacao['problem_situation_id']?.toString() ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Situação Problema #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  final id = situacao['id'] as String?;
                  if (id != null) {
                    controller.removeProblemSituation(id);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomFormFields.buildDropdownFieldFromMaps(
            'Selecione uma situação',
            situationId.isNotEmpty ? situationId : null,
            controller.problemOptions,
            (value) {
              if (value != null) {
                controller.updateProblemSituation(index, value);
              }
            },
            getDisplayText: (p) {
              final codigoCategoria = (p['codigo_categoria'] ?? '').toString();
              final descricao = (p['descricao'] ?? p['titulo'] ?? p['nome'] ?? 'Situação').toString();
              return codigoCategoria.isNotEmpty 
                  ? '$codigoCategoria - $descricao' 
                  : descricao;
            },
            getValue: (p) {
              return (p['situacao_id'] ?? p['id'] ?? p['problem_situation_id'])?.toString() ?? '';
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
            ),
            ...children,
          ],
        ),
      );
    });
  }
}
