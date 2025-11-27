import 'package:flutter/material.dart';
import '../../controllers/create_project_controller.dart';

class ProjectStepsSection extends StatelessWidget {
  final CreateProjectController controller;

  const ProjectStepsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      'Etapas do Projeto/Processo',
      [
        const SizedBox(height: 16),
        ...controller.projectSteps.map((step) {
          return _buildProjectStepField(step, controller, context);
        }),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Builder(builder: (context) {
            final theme = Theme.of(context);
            return ElevatedButton.icon(
              onPressed: controller.addProjectStep,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar Etapa'),
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

  Widget _buildProjectStepField(
    Map<String, dynamic> step,
    CreateProjectController controller,
    BuildContext context,
  ) {
    final plannedDateController = TextEditingController(text: step['plannedDate'] ?? '');
    final actualDateController = TextEditingController(text: step['actualDate'] ?? '');

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
              const Text(
                'Etapa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => controller.removeProjectStep(step['id']),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: step['description'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Descrição da Etapa',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            onChanged: (value) {
              step['description'] = value;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: step['deliverable_id'],
            decoration: const InputDecoration(
              labelText: 'Entregável',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: controller.deliverables.map((deliverable) {
              return DropdownMenuItem<int>(
                value: deliverable['id'],
                child: Text(deliverable['titulo'] ?? 'Entregável'),
              );
            }).toList(),
            onChanged: (value) {
              step['deliverable_id'] = value;
              final selected = controller.deliverables.firstWhere(
                (d) => d['id'] == value,
                orElse: () => {},
              );
              step['deliverable'] = selected['titulo'] ?? '';
            },
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: step['referenceNumber'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Número de Referência',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              step['referenceNumber'] = value;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: plannedDateController,
                  decoration: InputDecoration(
                    labelText: 'Data Verificação Prevista',
                    hintText: 'dd/mm/aaaa',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (picked != null) {
                          final dateStr = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                          plannedDateController.text = dateStr;
                          controller.updateProjectStepDate(step['id'], 'plannedDate', dateStr);
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: actualDateController,
                  decoration: InputDecoration(
                    labelText: 'Data Verificação Realizada',
                    hintText: 'dd/mm/aaaa',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (picked != null) {
                          final dateStr = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                          actualDateController.text = dateStr;
                          controller.updateProjectStepDate(step['id'], 'actualDate', dateStr);
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Verificação:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('OK'),
                  value: step['verification'] == 'OK',
                  onChanged: (value) {
                    controller.updateProjectStepVerification(step['id'], value == true ? 'OK' : null);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Requer Ação'),
                  value: step['verification'] == 'RequerAcao',
                  onChanged: (value) {
                    controller.updateProjectStepVerification(step['id'], value == true ? 'RequerAcao' : null);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
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
