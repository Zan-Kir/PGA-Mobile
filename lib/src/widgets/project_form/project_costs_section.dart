import 'package:flutter/material.dart';
import '../../controllers/create_project_controller.dart';
import '../../theme/app_theme.dart';
import '../common/form_field_builder.dart';

class ProjectCostsSection extends StatelessWidget {
  final CreateProjectController controller;

  const ProjectCostsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      'Informações de Custos',
      [
        const SizedBox(height: 16),
        CustomFormFields.buildCurrencyField(
          'Custo Estimado (R\$)',
          controller.costController,
          hintText: 'R\$ 0,00',
        ),
        const SizedBox(height: 16),
        CustomFormFields.buildTextField(
          'Fonte(s) dos Recursos',
          controller.resourceSourceController,
          hintText: 'Ex: Orçamento Institucional, Projeto Específico, etc.',
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
