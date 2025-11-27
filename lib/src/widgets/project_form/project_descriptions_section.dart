import 'package:flutter/material.dart';
import '../../controllers/create_project_controller.dart';
import '../common/form_field_builder.dart';

class ProjectDescriptionsSection extends StatelessWidget {
  final CreateProjectController controller;

  const ProjectDescriptionsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      'Descrições',
      [
        const SizedBox(height: 16),
        CustomFormFields.buildTextField(
          'O que será feito (Descrição da Ação/Projeto)',
          controller.descriptionController,
          maxLines: 4,
          hintText: 'Descreva detalhadamente o que será feito',
        ),
        const SizedBox(height: 16),
        CustomFormFields.buildTextField(
          'Por que será feito (Justificativa da Ação/Projeto)',
          controller.justificationController,
          maxLines: 4,
          hintText: 'Explique a justificativa para esta ação/projeto',
        ),
        const SizedBox(height: 16),
        CustomFormFields.buildTextField(
          'Objetivos Institucionais Referenciados',
          controller.objectivesController,
          maxLines: 4,
          hintText: 'Descreva os objetivos institucionais relacionados',
        ),
      ],
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
