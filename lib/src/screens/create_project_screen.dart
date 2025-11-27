import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/create_project_controller.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/project_form/project_identification_section.dart';
import '../widgets/project_form/project_descriptions_section.dart';
import '../widgets/project_form/project_dates_sustainability_section.dart';
import '../widgets/project_form/project_responsible_section.dart';
import '../widgets/project_form/project_steps_section.dart';
import '../widgets/project_form/project_costs_section.dart';
import '../widgets/project_form/project_problems_section.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  late CreateProjectController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateProjectController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await _controller.submitProject();
    
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Projeto criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/projects');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erro ao criar projeto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar formulário'),
        content: const Text('Tem certeza que deseja limpar todos os campos? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formulário limpo com sucesso!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color ?? theme.iconTheme.color),
          onPressed: () => context.go('/projects'),
        ),
        title: Text(
          'Criar Novo Projeto',
          style: theme.appBarTheme.titleTextStyle ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all, color: theme.iconTheme.color),
            tooltip: 'Limpar formulário',
            onPressed: _handleClear,
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                'A',
                style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      spreadRadius: 0,
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar Novo Projeto',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _controller.selectedThematicAxis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              ProjectIdentificationSection(controller: _controller),
              const SizedBox(height: 20),
              ProjectDescriptionsSection(controller: _controller),
              const SizedBox(height: 20),
              ProjectDatesAndSustainabilitySection(controller: _controller),
              const SizedBox(height: 20),
              ProjectResponsibleSection(controller: _controller),
              const SizedBox(height: 20),
              ProjectStepsSection(controller: _controller),
              const SizedBox(height: 20),
              ProjectCostsSection(controller: _controller),
              const SizedBox(height: 20),
              ProjectProblemsSection(controller: _controller),
              
              const SizedBox(height: 32),
              
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                        onPressed: _controller.isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      child: _controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Registrar Ação/Projeto',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        await _controller.saveDraft();
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Rascunho salvo localmente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Salvar Rascunho'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentRoute: '/create-project',
        onNavigate: (route) {
          context.go(route);
        },
      ),
    );
  }
}
