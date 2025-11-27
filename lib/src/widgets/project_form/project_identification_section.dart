import 'package:flutter/material.dart';
import '../../controllers/create_project_controller.dart';
import '../common/form_field_builder.dart';

class ProjectIdentificationSection extends StatelessWidget {
  final CreateProjectController controller;

  const ProjectIdentificationSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      'Identificação do Projeto',
      [
        const SizedBox(height: 16),
        CustomFormFields.buildDropdownField(
          'Eixo Temático',
          controller.selectedThematicAxis,
          controller.thematicAxisOptions,
          (value) {
            controller.selectedThematicAxis = value ?? '';
          },
          enabled: true,
        ),
        const SizedBox(height: 16),
        CustomFormFields.buildDropdownField(
          'ID/Tema do Projeto (Conforme PGA)',
          controller.selectedProjectId,
          controller.projectIdOptions,
          (value) {
            controller.selectedProjectId = value ?? '';
          },
          enabled: true,
        ),
        const SizedBox(height: 16),
        CustomFormFields.buildTextField(
          'Nome do Projeto',
          controller.nameController,
          hintText: 'Digite o nome do projeto',
        ),
        const SizedBox(height: 16),
        CustomFormFields.buildDropdownField(
          'Ano (PGA)',
          controller.selectedYear,
          controller.pgaOptions,
          (value) {
            controller.selectedYear = value ?? '';
          },
          hintText: 'Selecione o ano do PGA',
        ),
        const SizedBox(height: 16),
        CustomFormFields.buildDropdownField(
          'Prioridade/Origem da Ação',
          controller.selectedPriority,
          controller.priorityOptions,
          (value) {
            controller.selectedPriority = value ?? '';
          },
          hintText: 'Selecione a Prioridade/Origem',
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
