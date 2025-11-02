import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';
import '../widgets/bottom_navigation.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import '../services/config.dart';
import '../services/auth_storage.dart';
import 'package:http/http.dart' as http;

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';

  final LocalDB _localDb = LocalDB();
  final SyncService _sync = SyncService();
  List<Map<String, dynamic>> _projects = [];

  final List<Map<String, String>> _statusFilters = [
    {'label': 'Todos', 'value': 'all'},
    {'label': 'Em andamento', 'value': 'em andamento'},
    {'label': 'Concluído', 'value': 'concluído'},
    {'label': 'Atrasado', 'value': 'atrasado'},
  ];

  List<Map<String, dynamic>> get _filteredProjects {
    return _projects.where((project) {
      final matchesStatus = _selectedStatus == 'all' || 
                           project['status'].toLowerCase() == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty || 
                           project['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           project['responsible'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadLocalProjects();
    // Carregar projetos do backend ao iniciar
    _loadProjectsFromBackend();
  }

  Future<void> _loadProjectsFromBackend() async {
    try {
      // Buscar token de autenticação
      final token = await AuthStorage.readToken();
      if (token == null) {
        debugPrint('⚠️ Token não encontrado, usuário precisa fazer login');
        return;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/project1'),
        headers: headers,
      );
      
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        debugPrint('✅ Projetos carregados do backend: ${data.length} projetos');
        
        // Limpar projetos do servidor antes de salvar novos (evita duplicação)
        await _localDb.clearProjectsFromServer();
        
        // salvar cada projeto no local DB
        for (final p in data) {
          final serverId = p['acao_projeto_id'];
          final localId = p['codigo_projeto']?.toString();
          await _localDb.saveProject(
            jsonEncode(p), 
            localId: localId,
            serverId: serverId,
          );
        }
        await _loadLocalProjects();
      } else {
        debugPrint('❌ Erro ao buscar projetos: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      debugPrint('❌ Exceção ao buscar projetos: $e');
    }
  }

  Future<void> _loadLocalProjects() async {
    final rows = await _localDb.getProjects();
    setState(() {
      _projects = rows.map((r) {
        final data = r['data'] as String;
        try {
          final parsed = Map<String, dynamic>.from(jsonDecode(data));
          return _mapProjectFromBackend(parsed);
        } catch (_) {
          return {'id': r['local_id'] ?? r['id'].toString(), 'name': data, 'status': 'em andamento', 'progress': 0, 'deadline': 'N/A', 'responsible': 'N/A'};
        }
      }).toList();
    });
  }

  /// Mapeia os dados do backend para o formato esperado pelo ProjectCard
  Map<String, dynamic> _mapProjectFromBackend(Map<String, dynamic> backendData) {
    // Extrair dados do backend (AcaoProjeto)
    final codigoProjeto = backendData['codigo_projeto'] ?? '';
    final nomeProjeto = backendData['nome_projeto'] ?? 'Projeto sem nome';
    final dataFinal = backendData['data_final'];
    
    // Calcular progresso baseado nas etapas (se disponível)
    int progress = 0;
    if (backendData['etapas'] != null && backendData['etapas'] is List) {
      final etapas = backendData['etapas'] as List;
      if (etapas.isNotEmpty) {
        final concluidas = etapas.where((e) => e['concluido'] == true).length;
        progress = ((concluidas / etapas.length) * 100).round();
      }
    }
    
    // Determinar status baseado no progresso e datas
    String status = 'em andamento';
    if (progress == 100) {
      status = 'concluído';
    } else if (dataFinal != null) {
      try {
        final deadline = DateTime.parse(dataFinal);
        if (deadline.isBefore(DateTime.now())) {
          status = 'atrasado';
        }
      } catch (_) {}
    }
    
    // Formatar prazo
    String deadline = 'N/A';
    if (dataFinal != null) {
      try {
        final date = DateTime.parse(dataFinal);
        deadline = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {
        deadline = dataFinal.toString();
      }
    }
    
    // Pegar o responsável (primeira pessoa se houver)
    String responsible = 'Não atribuído';
    if (backendData['pessoas'] != null && backendData['pessoas'] is List) {
      final pessoas = backendData['pessoas'] as List;
      if (pessoas.isNotEmpty && pessoas.first['pessoa'] != null) {
        responsible = pessoas.first['pessoa']['nome'] ?? 'Não atribuído';
      }
    }
    
    return {
      'id': backendData['acao_projeto_id']?.toString() ?? codigoProjeto,
      'codigo_projeto': codigoProjeto,
      'name': nomeProjeto,
      'status': status,
      'progress': progress,
      'deadline': deadline,
      'responsible': responsible,
      // Manter dados originais para referência
      '_original': backendData,
    };
  }

  Future<void> _onRefresh() async {
    // tentar sync (enviar fila)
    await _sync.trySyncAll(AppConfig.baseUrl);

    // tentar buscar a lista atual do backend e atualizar cache local
    try {
      // Buscar token de autenticação
      final token = await AuthStorage.readToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/project1'),
        headers: headers,
      );
      
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        debugPrint('✅ Projetos carregados: ${data.length} projetos');
        
        // Limpar projetos do servidor antes de salvar novos (evita duplicação)
        await _localDb.clearProjectsFromServer();
        
        // salvar cada projeto no local DB (substituir cache simplificado)
        for (final p in data) {
          final serverId = p['acao_projeto_id'];
          final localId = p['codigo_projeto']?.toString();
          await _localDb.saveProject(
            jsonEncode(p), 
            localId: localId,
            serverId: serverId,
          );
        }
        await _loadLocalProjects();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data.length} projetos carregados com sucesso!')),
          );
        }
        return;
      } else {
        debugPrint('❌ Erro ao buscar projetos: ${resp.statusCode} - ${resp.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar projetos: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Exceção ao buscar projetos do backend: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e')),
        );
      }
    }

    // fallback: recarregar local
    await _loadLocalProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Projetos'),
      ),
      body: Column(
        children: [
          // Filtros e Busca
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barra de Busca
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar projetos...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                // Filtros de Status
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = filter['value'] == _selectedStatus;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = filter['value']!;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                          ),
                          side: isSelected ? null : BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Projetos
          Expanded(
            child: _filteredProjects.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum projeto encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = _filteredProjects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProjectCard(
                            project: project,
                            onTap: () {
                              // Navegar para detalhes do projeto
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),

      // Navegação inferior
      bottomNavigationBar: BottomNavigation(
        currentRoute: '/projects',
        onNavigate: (route) {
          if (route == '/projects') return;
          context.go(route);
        },
      ),
    );
  }
}
