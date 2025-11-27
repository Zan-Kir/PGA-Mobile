# Formulário de Criação de Projeto - Arquitetura Refatorada

## Estrutura de Arquivos

```
lib/
  src/
    controllers/
      create_project_controller.dart    # Controlador principal com toda lógica de negócio
    
    screens/
      create_project_screen_new.dart    # Tela principal (apenas coordenação de UI)
      create_project_screen.dart        # Tela antiga (manter para referência)
    
    widgets/
      common/
        form_field_builder.dart         # Campos de formulário reutilizáveis
      
      project_form/
        project_form_sections.dart                # Index para exportação de todos os widgets
        project_identification_section.dart       # Seção: Identificação do Projeto
        project_descriptions_section.dart         # Seção: Descrições (O que/Por que)
        project_dates_sustainability_section.dart # Seção: Inclusão, Sustentabilidade e Datas
        project_responsible_section.dart          # Seção: Pessoas Responsáveis
        project_steps_section.dart                # Seção: Etapas do Projeto
        project_costs_section.dart                # Seção: Informações de Custos
        project_problems_section.dart             # Seção: Situações Problema
```

## Responsabilidades

### CreateProjectController (`create_project_controller.dart`)
**Responsabilidade:** Toda a lógica de negócio e estado do formulário

- Gerenciamento de estado (usando `ChangeNotifier`)
- Comunicação com API (carregar opções, usuários, entregáveis, etc.)
- Validação de dados
- Persistência de rascunhos (autosave)
- Submissão do projeto
- Manipulação de listas dinâmicas (pessoas, etapas, problemas)

### CreateProjectScreen (`create_project_screen.dart`)
**Responsabilidade:** Coordenação da UI e navegação

- Inicialização do controller
- Navegação entre telas
- Exibição de mensagens (SnackBars)
- Composição dos widgets de seção
- Barra de navegação e AppBar

### Widgets de Seção (`project_form/`)
**Responsabilidade:** UI específica de cada seção do formulário

Cada widget de seção:
- Recebe o `CreateProjectController` como parâmetro
- Renderiza uma parte específica do formulário
- Delega ações ao controller
- Mantém estrutura visual consistente

#### Seções Disponíveis:

1. **ProjectIdentificationSection**
   - Nome do Projeto
   - Eixo Temático
   - Tema
   - Ano (PGA)
   - Prioridade

2. **ProjectDescriptionsSection**
   - O que será feito?
   - Por que será feito?
   - Objetivos Institucionais

3. **ProjectDatesAndSustainabilitySection**
   - Checkbox: Promove Inclusão
   - Checkbox: Promove Sustentabilidade
   - Data de Início Previsto
   - Data de Final Previsto

4. **ProjectResponsibleSection**
   - **Responsáveis**: seleção de pessoa (sem campos adicionais)
   - **Colaboradores**: nome, carga horária semanal e tipo vínculo HAE
   - Botões separados para adicionar cada tipo

5. **ProjectStepsSection**
   - Lista de etapas do projeto
   - Descrição, entregável, número de referência
   - Datas prevista e realizada
   - Status de verificação

6. **ProjectCostsSection**
   - Custo Estimado (R$)
   - Fonte(s) dos Recursos

7. **ProjectProblemsSection**
   - Lista de situações problema
   - Descrição de cada problema

### CustomFormFields (`common/form_field_builder.dart`)
**Responsabilidade:** Componentes de formulário reutilizáveis

- `buildTextField()` - Campo de texto customizado
- `buildDropdownField()` - Dropdown com formatação padrão
- `buildDateField()` - Campo de data com DatePicker

## Padrões Utilizados

### 1. **Separation of Concerns**
- Controller: Lógica de negócio
- Screen: Coordenação de UI
- Widgets: Componentes visuais isolados

### 2. **Single Responsibility**
Cada widget/classe tem uma única responsabilidade bem definida

### 3. **Reusabilidade**
- Componentes de formulário extraídos para reutilização
- Widgets de seção podem ser facilmente reorganizados

### 4. **Manutenibilidade**
- Código organizado por funcionalidade
- Fácil localização de bugs
- Simples adicionar novas seções

## Como Adicionar uma Nova Seção

1. Criar novo arquivo em `widgets/project_form/`
2. Criar classe que estende `StatelessWidget`
3. Receber `CreateProjectController` no construtor
4. Implementar UI usando `_buildSectionCard()`
5. Exportar no `project_form_sections.dart`
6. Adicionar na tela principal (`create_project_screen_new.dart`)

### Exemplo:

```dart
import 'package:flutter/material.dart';
import '../../controllers/create_project_controller.dart';
import '../common/form_field_builder.dart';

class ProjectNewSection extends StatelessWidget {
  final CreateProjectController controller;

  const ProjectNewSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      'Título da Nova Seção',
      [
        const SizedBox(height: 12),
        CustomFormFields.buildTextField(
          'Campo Exemplo',
          controller.exampleController,
          hintText: 'Digite algo...',
        ),
        // ... mais campos
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
            color: Colors.black.withOpacity(0.05),
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
              color: Color(0xFF1E3A8A),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
```

## Benefícios da Refatoração

### ✅ Manutenibilidade
- Código organizado e fácil de navegar
- Responsabilidades claras
- Bugs isolados em componentes específicos

### ✅ Testabilidade
- Controller pode ser testado isoladamente
- Widgets podem ser testados com controllers mockados
- Lógica de negócio separada da UI

### ✅ Reusabilidade
- Componentes podem ser reutilizados
- Seções podem ser reorganizadas facilmente
- Campos de formulário consistentes

### ✅ Escalabilidade
- Fácil adicionar novas seções
- Simples modificar comportamentos
- Estrutura preparada para crescimento

### ✅ Colaboração
- Diferentes desenvolvedores podem trabalhar em seções diferentes
- Menos conflitos de merge
- Código auto-documentado

## Próximos Passos

- [ ] Adicionar testes unitários para o controller
- [ ] Adicionar testes de widget para cada seção
- [ ] Implementar validações mais robustas
- [ ] Adicionar feedback visual para estados de loading
- [ ] Implementar undo/redo para rascunhos
- [ ] Adicionar tour/onboarding para novos usuários
