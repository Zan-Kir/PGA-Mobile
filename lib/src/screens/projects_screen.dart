import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../widgets/project_card.dart';
import '../widgets/bottom_navigation.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import '../services/config.dart';
import '../services/auth_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/save_share_dialog.dart';


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
    _loadProjectsFromBackend();
  }

  Future<void> _loadProjectsFromBackend() async {
    try {
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

        await _localDb.clearProjectsFromServer();

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

  Map<String, dynamic> _mapProjectFromBackend(Map<String, dynamic> backendData) {
    final codigoProjeto = backendData['codigo_projeto'] ?? '';
    final nomeProjeto = backendData['nome_projeto'] ?? 'Projeto sem nome';
    final dataInicio = backendData['data_inicio'];
    final dataFinal = backendData['data_final'];

    int progressoEtapas = 0;
    bool todasEtapasConcluidas = false;

    if (backendData['etapas'] != null && backendData['etapas'] is List) {
      final etapas = backendData['etapas'] as List;
      if (etapas.isNotEmpty) {
        final concluidas = etapas.where((e) => e['status_verificacao'] == 'OK' || e['concluido'] == true).length;
        progressoEtapas = ((concluidas / etapas.length) * 100).round();
        todasEtapasConcluidas = concluidas == etapas.length;
      }
    }

    int progressoTempo = 0;
    if (dataInicio != null && dataFinal != null) {
      try {
        final inicio = DateTime.parse(dataInicio);
        final fim = DateTime.parse(dataFinal);
        final agora = DateTime.now();

        final tempoTotal = fim.difference(inicio).inDays;
        final tempoDecorrido = agora.difference(inicio).inDays;

        if (tempoTotal > 0) {
          progressoTempo = ((tempoDecorrido / tempoTotal) * 100).clamp(0, 100).round();
        } else if (tempoTotal == 0) {
          progressoTempo = agora.isAfter(fim) || agora.isAtSameMomentAs(fim) ? 100 : 0;
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao parsear datas do projeto "$nomeProjeto": $e');
      }
    }

    int progress = 0;
    if (progressoEtapas > 0 && progressoTempo > 0) {
      progress = ((progressoEtapas * 0.6) + (progressoTempo * 0.4)).round();
    } else if (progressoEtapas > 0) {
      progress = progressoEtapas;
    } else if (progressoTempo > 0) {
      progress = progressoTempo;
    }

    String status = 'em andamento';
    if (todasEtapasConcluidas) {
      status = 'concluído';
      progress = 100;
    } else if (dataFinal != null) {
      try {
        final deadlineDate = DateTime.parse(dataFinal);
        if (deadlineDate.isBefore(DateTime.now()) && progress < 100) {
          status = 'atrasado';
        }
      } catch (_) {}
    }

    String deadline = 'N/A';
    if (dataFinal != null) {
      try {
        final date = DateTime.parse(dataFinal);
        deadline = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {
        deadline = dataFinal.toString();
      }
    }

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
      '_original': backendData,
    };
  }

  Future<void> _onRefresh() async {
    final messenger = ScaffoldMessenger.of(context);
    await _sync.trySyncAll(AppConfig.baseUrl);

    try {
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
        
        await _localDb.clearProjectsFromServer();
        
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
          messenger.showSnackBar(
            SnackBar(content: Text('${data.length} projetos carregados com sucesso!')),
          );
        }
        return;
      } else {
        debugPrint('❌ Erro ao buscar projetos: ${resp.statusCode} - ${resp.body}');
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Erro ao carregar projetos: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Exceção ao buscar projetos do backend: $e');
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Erro de conexão: $e')),
          );
        }
    }

    await _loadLocalProjects();
  }

  Future<void> _openActionsSheet() async {
    List<Map<String, dynamic>> pgas = [];
    try {
      final token = await AuthStorage.readToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final resp = await http.get(Uri.parse('${AppConfig.baseUrl}/pga'), headers: headers);
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        pgas = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar PGAs para exportação: $e');
    }

    int? selectedId;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ações', style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Selecionar PGA:', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  if (pgas.isEmpty) Text('Nenhum PGA disponível', style: theme.textTheme.bodyMedium),
                  if (pgas.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: selectedId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: pgas.map((p) {
                        final id = p['pga_id'] ?? p['id'];
                        final intVal = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
                        final label = (p['ano']?.toString() ?? p['titulo']?.toString() ?? 'PGA ${intVal.toString()}');
                        return DropdownMenuItem<int>(value: intVal, child: Text(label));
                      }).toList(),
                      onChanged: (v) => setState(() => selectedId = v),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: selectedId == null ? null : () async {
                            Navigator.of(ctx).pop();
                            await _downloadPgaCsv(selectedId!);
                          },
                          icon: Icon(Icons.download, color: theme.colorScheme.onPrimary),
                          label: Text('Exportar CSV', style: TextStyle(color: theme.colorScheme.onPrimary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: selectedId == null ? null : () async {
                            Navigator.of(ctx).pop();
                            await _downloadPgaPdf(selectedId!);
                          },
                          icon: Icon(Icons.picture_as_pdf, color: theme.colorScheme.onPrimary),
                          label: Text('Exportar PDF', style: TextStyle(color: theme.colorScheme.onPrimary)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                      ),
                      onPressed: selectedId == null ? null : () async {
                        Navigator.of(ctx).pop();
                        await _openEditPga(selectedId!);
                      },
                      icon: Icon(Icons.flag, color: theme.colorScheme.onPrimary),
                      label: Text('PGA', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadPgaCsv(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await AuthStorage.readToken();
      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final resp = await http.get(Uri.parse('${AppConfig.baseUrl}/pga/$id/export/csv'), headers: headers);
      if (resp.statusCode == 200) {
        final content = resp.body;
        Directory? targetDir;
        try {
          final ext = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (ext != null && ext.isNotEmpty) {
            targetDir = ext.first;
          }
        } catch (_) {
          targetDir = null;
        }

        try {
          if (targetDir != null) {
            final file = File('${targetDir.path}/pga-$id.csv');
            await file.writeAsString(content, flush: true);
            if (mounted) messenger.showSnackBar(SnackBar(content: Text('CSV salvo em: ${file.path}')));
                  try {
                    if (!mounted) return;
                    final result = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => SaveShareDialog(bytes: Uint8List.fromList(utf8.encode(content)), fileName: 'pga-$id.csv'),
                    );
                    if (!mounted) return;
                    if (result != null) {
                      messenger.showSnackBar(SnackBar(content: Text('CSV salvo em: $result')));
                    } else {
                      messenger.showSnackBar(const SnackBar(content: Text('Exportação cancelada')));
                    }
                  } catch (e) {
                    debugPrint('Erro ao salvar/compartilhar CSV: $e');
                  }
            return;
          }
        } catch (e) {
          debugPrint('Não foi possível salvar em Downloads: $e');
        }

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/pga-$id.csv');
        await file.writeAsString(content, flush: true);
        if (mounted) messenger.showSnackBar(SnackBar(content: Text('CSV salvo em (aplicativo): ${file.path}')));
        try {
          // shareXFiles é marcado como deprecado em algumas versões do plugin.
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')], text: 'Exportação PGA #$id');
        } catch (e) {
          debugPrint('Erro ao abrir compartilhamento CSV (fallback): $e');
        }
      } else {
        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Erro ao exportar CSV: ${resp.statusCode}')));
      }
    } catch (e) {
      debugPrint('Erro exportar CSV: $e');
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Erro ao exportar CSV: $e')));
    }
  }

  Future<void> _downloadPgaPdf(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await AuthStorage.readToken();
      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final resp = await http.get(Uri.parse('${AppConfig.baseUrl}/pga/$id/export/pdf'), headers: headers);
      if (resp.statusCode == 200) {
        final bytes = resp.bodyBytes;
        Directory? targetDir;
        try {
          final ext = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (ext != null && ext.isNotEmpty) {
            targetDir = ext.first;
          }
        } catch (_) {
          targetDir = null;
        }

        File? savedFile;
        try {
          if (targetDir != null) {
            final file = File('${targetDir.path}/pga-$id.pdf');
            await file.writeAsBytes(bytes, flush: true);
            savedFile = file;
          }
        } catch (e) {
          debugPrint('Não foi possível salvar em Downloads: $e');
        }

          if (savedFile == null) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/pga-$id.pdf');
          await file.writeAsBytes(bytes, flush: true);
          savedFile = file;
          if (mounted) messenger.showSnackBar(SnackBar(content: Text('PDF salvo em (aplicativo): ${file.path}')));
        }

        try {
          if (!mounted) return;
          final result = await showDialog<String?>(
            context: context,
            builder: (ctx) => SaveShareDialog(bytes: bytes, fileName: 'pga-$id.pdf'),
          );
          if (!mounted) return;
          if (result != null) {
            messenger.showSnackBar(SnackBar(content: Text('PDF salvo em: $result')));
          } else {
            messenger.showSnackBar(const SnackBar(content: Text('Exportação cancelada')));
          }
        } catch (e) {
          debugPrint('Erro ao salvar PDF: $e');
        }
      } else {
        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Erro ao exportar PDF: ${resp.statusCode}')));
      }
    } catch (e) {
      debugPrint('Erro exportar PDF: $e');
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Erro ao exportar PDF: $e')));
    }
  }

  Future<void> _openEditPga(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await AuthStorage.readToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final resp = await http.get(Uri.parse('${AppConfig.baseUrl}/pga/$id'), headers: headers);
      if (resp.statusCode == 200) {
        final Map<String, dynamic> pga = jsonDecode(resp.body) as Map<String, dynamic>;

        final anoCtrl = TextEditingController(text: pga['ano']?.toString() ?? '');
        final versaoCtrl = TextEditingController(text: pga['versao']?.toString() ?? '');
        final analiseCtrl = TextEditingController(text: pga['analise_cenario']?.toString() ?? '');
        final dataElabCtrl = TextEditingController(text: pga['data_elaboracao']?.toString() ?? '');
        final dataParecerGprCtrl = TextEditingController(text: pga['data_parecer_gpr']?.toString() ?? '');
        String statusValue = pga['status']?.toString() ?? 'EmElaboracao';

        Future<void> pickDate(TextEditingController ctrl) async {
          try {
            final initial = ctrl.text.isNotEmpty ? DateTime.tryParse(ctrl.text) ?? DateTime.now() : DateTime.now();
            final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (picked != null) ctrl.text = picked.toIso8601String().split('T').first;
          } catch (_) {}
        }

        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Editar PGA'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: anoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ano')),
                  const SizedBox(height: 8),
                  TextField(controller: versaoCtrl, decoration: const InputDecoration(labelText: 'Versão')),
                  const SizedBox(height: 8),
                  TextField(controller: analiseCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Análise do cenário')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dataElabCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Data elaboração'),
                          onTap: () => pickDate(dataElabCtrl),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: dataParecerGprCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Data parecer GPR'),
                          onTap: () => pickDate(dataParecerGprCtrl),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: statusValue,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: <String>['EmElaboracao', 'Publicado', 'Finalizado', 'EmAnalise']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => statusValue = v ?? statusValue,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  final body = {
                    'ano': int.tryParse(anoCtrl.text) ?? pga['ano'],
                    'versao': versaoCtrl.text.isNotEmpty ? versaoCtrl.text : null,
                    'analise_cenario': analiseCtrl.text.isNotEmpty ? analiseCtrl.text : null,
                    'data_elaboracao': dataElabCtrl.text.isNotEmpty ? dataElabCtrl.text : null,
                    'data_parecer_gpr': dataParecerGprCtrl.text.isNotEmpty ? dataParecerGprCtrl.text : null,
                    'status': statusValue,
                  };
                  final filtered = Map<String, dynamic>.from(body)..removeWhere((k, v) => v == null);
                  try {
                    final putRes = await http.put(Uri.parse('${AppConfig.baseUrl}/pga/$id'), headers: headers, body: jsonEncode(filtered));
                    if (putRes.statusCode == 200) {
                      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('PGA atualizado')));
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    } else {
                      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Erro ao atualizar PGA: ${putRes.statusCode}')));
                    }
                  } catch (e) {
                    if (mounted) messenger.showSnackBar(SnackBar(content: Text('Erro ao atualizar PGA: $e')));
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar PGA: ${resp.statusCode}')));
      }
    } catch (e) {
      debugPrint('Erro abrir edição PGA: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir edição PGA: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Projetos'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                          backgroundColor: theme.colorScheme.surface,
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
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

          Expanded(
            child: _filteredProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum projeto encontrado',
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, color: theme.disabledColor),
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
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () => _openActionsSheet(),
          backgroundColor: theme.colorScheme.primary,
          tooltip: 'PGA',
          shape: const CircleBorder(),
          elevation: 6,
          child: Text('PGA', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),

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
