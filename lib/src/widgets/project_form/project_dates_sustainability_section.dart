import 'package:flutter/material.dart';
import '../../controllers/create_project_controller.dart';
import '../../theme/app_theme.dart';
import '../common/form_field_builder.dart';

class ProjectDatesAndSustainabilitySection extends StatelessWidget {
  final CreateProjectController controller;

  const ProjectDatesAndSustainabilitySection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      'Inclusão, Sustentabilidade e Datas',
      [
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: controller.mandatoryInclusion,
              onChanged: (value) {
                controller.mandatoryInclusion = value!;
              },
            ),
            const Expanded(
              child: Text('Marque se a ação/projeto promove inclusão.'),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: controller.mandatorySustainability,
              onChanged: (value) {
                controller.mandatorySustainability = value!;
              },
            ),
            const Expanded(
              child: Text('Marque se a ação/projeto promove sustentabilidade.'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomFormFields.buildDateField(
                'Início Previsto',
                controller.startDateController,
                context,
                (_) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomFormFields.buildDateField(
                'Final Previsto',
                controller.endDateController,
                context,
                (_) {},
              ),
            ),
          ],
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
