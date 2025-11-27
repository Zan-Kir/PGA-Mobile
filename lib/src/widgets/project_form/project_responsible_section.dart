import 'package:flutter/material.dart';
import '../../controllers/create_project_controller.dart';

class ProjectResponsibleSection extends StatelessWidget {
  final CreateProjectController controller;

  const ProjectResponsibleSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      'Pessoas Envolvidas no Projeto',
      [
        const SizedBox(height: 16),
        const Text('Responsáveis', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...controller.responsiblePeople.map((person) {
          return _buildPersonField(
            person,
            controller,
            () => controller.removeResponsiblePerson(person['id']),
          );
        }),
        const SizedBox(height: 12),
        const Text('Colaboradores', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...controller.collaborators.map((person) {
          return _buildPersonField(
            person,
            controller,
            () => controller.removeCollaborator(person['id']),
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.addResponsiblePerson,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Adicionar Responsável'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.addCollaborator,
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('Adicionar Colaborador'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonField(
    Map<String, dynamic> person,
    CreateProjectController controller,
    VoidCallback onRemove,
  ) {
    final isResponsible = person['papel'] == 'Responsavel';

    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isResponsible
                      ? 'Responsável #${controller.responsiblePeople.indexOf(person) + 1}'
                      : 'Colaborador #${controller.collaborators.indexOf(person) + 1}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              initialValue: person['pessoa_id'],
              decoration: InputDecoration(
                labelText: 'Nome:',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
              ),
              items: controller.users.map((user) {
                final id = controller.toInt(user['pessoa_id'] ?? user['id']);
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(controller.userLabel(user)),
                );
              }).toList(),
              onChanged: (value) {
                person['pessoa_id'] = value;
                final selectedUser = controller.users.firstWhere(
                  (u) => controller.toInt(u['pessoa_id'] ?? u['id']) == value,
                  orElse: () => {},
                );
                person['name'] = controller.userLabel(selectedUser);
              },
              isExpanded: true,
            ),

            if (!isResponsible) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: person['carga_horaria_semanal']?.toString() ?? '',
                      decoration: InputDecoration(
                        labelText: 'Carga Horária Semanal (H):',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        person['carga_horaria_semanal'] = int.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: person['tipo_vinculo_hae_id'],
                      decoration: InputDecoration(
                        labelText: 'Tipo Vínculo HAE:',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor,
                      ),
                      items: controller.workloadTypes.map((type) {
                        final id = controller.toInt(type['id']);
                        final sigla = type['sigla'] ?? '';
                        final descricao = type['descricao'] ?? '';
                        final label = sigla.isNotEmpty ? '$sigla - $descricao' : descricao;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        person['tipo_vinculo_hae_id'] = value;
                      },
                      isExpanded: true,
                      hint: const Text('Selecione o tipo'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
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
