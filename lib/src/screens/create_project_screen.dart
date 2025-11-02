import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../services/auth_storage.dart';
import '../services/config.dart';
import '../widgets/bottom_navigation.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para os campos do formulário
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _justificationController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _costController = TextEditingController();
  final _resourceSourceController = TextEditingController();
  
  // Variáveis de estado
  String _selectedThematicAxis = '';
  String _selectedProjectId = '';
  String _selectedYear = '';
  String _selectedPriority = '';
  bool _mandatoryInclusion = false;
  bool _mandatorySustainability = false;
  bool _isLoading = false;

  // Mapeamentos de nome -> id (populados do servidor)
  final Map<String, int> _eixoNameToId = {};
  final Map<String, int> _temaNameToId = {};
  final Map<String, int> _priorityNameToId = {};
  
  // Opções de PGA e mapeamento direto ano -> objeto completo
  final List<String> _pgaOptions = [];
  final Map<String, Map<String, dynamic>> _pgaByYear = {};
  
  // Listas dinâmicas (pessoas, etapas, problemas)
  final List<Map<String, dynamic>> _responsiblePeople = [];
  final List<Map<String, dynamic>> _collaborators = [];
  final List<Map<String, dynamic>> _projectSteps = [];
  final List<Map<String, dynamic>> _problemSituations = [];
  
  // Opções carregadas do backend
  final List<String> _thematicAxisOptions = [];
  final List<String> _projectIdOptions = [];
  final List<String> _priorityOptions = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _deliverables = [];
  List<Map<String, dynamic>> _problemOptions = [];
  List<Map<String, dynamic>> _workloadTypes = [];
  
  // Database local e autosave
  final LocalDB _localDb = LocalDB();
  String? _draftLocalId;
  Timer? _autosaveTimer;

  // helper: safely convert dynamic id (num or string) to int
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  // helper: build user label 'Nome (Cargo)' with fallback
  String _userLabel(Map<String, dynamic> u) {
    final roleRaw = (u['tipo_usuario'] ?? u['tipoUsuario'] ?? u['cargo']);
    final role = roleRaw?.toString();
    final name = (u['nome'] ?? u['name'] ?? u['email'] ?? 'Usuário').toString();
    return role != null && role.isNotEmpty ? '$name ($role)' : name;
  }

  // helper: convert dd/mm/yyyy to ISO YYYY-MM-DD, returns null if invalid/empty
  String? _toIsoDate(String? ddmmyyyy) {
    if (ddmmyyyy == null) return null;
    final parts = ddmmyyyy.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    try {
      final dt = DateTime(y, m, d);
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _costController.text = 'R\$ 0,00';
    // carregar opções do backend
    _loadSelectOptions();
    _loadPeopleAndDeliverables();
    // carregar rascunho salvo (se existir)
    _loadDraft();
    // iniciar autosave periódico (a cada 30 segundos)
    _autosaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveDraft();
    });
    // ensure there's always one responsible entry so UI and state match
    if (_responsiblePeople.isEmpty) _addResponsiblePerson();
  }

  Future<void> _loadDraft() async {
    try {
      final drafts = await _localDb.getDrafts('create_project');
      if (drafts.isNotEmpty) {
        // use the most recent draft
        final row = drafts.last;
        final dataStr = row['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final Map<String, dynamic> doc = jsonDecode(dataStr) as Map<String, dynamic>;
          setState(() {
            _draftLocalId = row['local_id'] as String?;
            _nameController.text = doc['nome'] ?? '';
            _descriptionController.text = doc['descricao'] ?? '';
            _justificationController.text = doc['justificativa'] ?? '';
            _objectivesController.text = doc['objetivos'] ?? '';
            _startDateController.text = doc['data_inicio'] ?? '';
            _endDateController.text = doc['data_fim'] ?? '';
            _costController.text = doc['custo'] ?? _costController.text;
            _resourceSourceController.text = doc['fonte_recursos'] ?? '';
            _selectedThematicAxis = doc['eixo'] ?? _selectedThematicAxis;
            _selectedProjectId = doc['tema'] ?? _selectedProjectId;
            _selectedYear = doc['ano'] ?? _selectedYear;
            _selectedPriority = doc['prioridade'] ?? _selectedPriority;
            // checkboxes
            _mandatoryInclusion = doc['obrigatorio_inclusao'] ?? false;
            _mandatorySustainability = doc['obrigatorio_sustentabilidade'] ?? false;
            // lists
            final rp = doc['responsaveis'] as List?;
            if (rp != null) {
              _responsiblePeople.clear();
              _responsiblePeople.addAll(rp.map((e) => Map<String, dynamic>.from(e as Map)).toList());
            }
            final col = doc['colaboradores'] as List?;
            if (col != null) {
              _collaborators.clear();
              _collaborators.addAll(col.map((e) => Map<String, dynamic>.from(e as Map)).toList());
            }
            final steps = doc['etapas'] as List?;
            if (steps != null) {
              _projectSteps.clear();
              // normalize verification values from saved draft
              _projectSteps.addAll(steps.map((raw) {
                final Map<String, dynamic> e = Map<String, dynamic>.from(raw as Map);
                final v = e['verification'] ?? e['status_verificacao'] ?? e['statusVerificacao'];
                if (v == null) {
                  e['verification'] = null;
                } else {
                  final sv = v.toString();
                  if (sv.toLowerCase().contains('requer')) e['verification'] = 'RequerAcao';
                  else if (sv.toLowerCase().contains('ok')) e['verification'] = 'OK';
                  else e['verification'] = null;
                }
                return e;
              }).toList());
            }
            final probs = doc['problemas'] as List?;
            if (probs != null) {
              _problemSituations.clear();
              _problemSituations.addAll(probs.map((e) => Map<String, dynamic>.from(e as Map)).toList());
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar rascunho: $e');
    }
  }

  Future<void> _saveDraft() async {
    try {
      final draft = {
        'nome': _nameController.text,
        'descricao': _descriptionController.text,
        'justificativa': _justificationController.text,
        'objetivos': _objectivesController.text,
        'data_inicio': _startDateController.text,
        'data_fim': _endDateController.text,
        'custo': _costController.text,
        'fonte_recursos': _resourceSourceController.text,
        'eixo': _selectedThematicAxis,
        'tema': _selectedProjectId,
        'ano': _selectedYear,
        'prioridade': _selectedPriority,
        'obrigatorio_inclusao': _mandatoryInclusion,
        'obrigatorio_sustentabilidade': _mandatorySustainability,
        'responsaveis': _responsiblePeople,
        'colaboradores': _collaborators,
        'etapas': _projectSteps,
        'problemas': _problemSituations,
      };
      final jsonStr = jsonEncode(draft);
      // save (insert or update)
      await _localDb.saveDraft('create_project', jsonStr, localId: _draftLocalId);
      if (_draftLocalId == null) {
        // create a local id placeholder so subsequent updates target the same logical draft
        _draftLocalId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rascunho salvo localmente'), backgroundColor: Colors.green));
    } catch (e) {
      debugPrint('Erro ao salvar rascunho: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao salvar rascunho'), backgroundColor: Colors.red));
    }
  }

  Future<void> _loadPeopleAndDeliverables() async {
    try {
      final headers = await _authHeaders();
      final usersRes = await http.get(Uri.parse('${AppConfig.baseUrl}/users'), headers: headers);
      if (usersRes.statusCode == 200) {
        final List data = jsonDecode(usersRes.body) as List;
        _users = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // entregáveis - backend expõe rota '/deliverable' e os objetos usam campos como entregavel_id/entregavel_numero/descricao
      final deliversRes = await http.get(Uri.parse('${AppConfig.baseUrl}/deliverable'), headers: headers);
      if (deliversRes.statusCode == 200) {
        final List data = jsonDecode(deliversRes.body) as List;
        // normalize objects so the mobile UI can use 'id' and 'titulo' keys
        _deliverables = data.map((raw) {
          final Map<String, dynamic> item = Map<String, dynamic>.from(raw as Map);
          // possible id fields
          final dynamic idVal = item['entregavel_id'] ?? item['id'] ?? item['deliverable_id'];
          final int? id = _toInt(idVal);
          // possible title/description fields
          final String titulo = (item['descricao'] ?? item['detalhes'] ?? item['titulo'] ?? item['nome'] ?? '').toString();
          return {
            'id': id,
            'titulo': titulo,
            // keep original data for fallback
            ...item,
          };
        }).toList();
      }

      final problemsRes = await http.get(Uri.parse('${AppConfig.baseUrl}/problem-situation'), headers: headers);
      if (problemsRes.statusCode == 200) {
        final List data = jsonDecode(problemsRes.body) as List;
        _problemOptions = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // workload HAE (tipos de vínculo) - usado para colaboradores
      final workloadRes = await http.get(Uri.parse('${AppConfig.baseUrl}/workload-hae'), headers: headers);
      if (workloadRes.statusCode == 200) {
        final List data = jsonDecode(workloadRes.body) as List;
        _workloadTypes = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      setState(() {});
    } catch (e) {
      debugPrint('Erro ao carregar pessoas/entregaveis/problemas: $e');
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorage.readToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<void> _loadSelectOptions() async {
    await Future.wait([
      _loadEixos(),
      _loadTemas(),
      _loadPriorities(),
      _loadPgas(),
    ]);
  }

  Future<void> _loadEixos() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/thematic-axis'), headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final List<String> opts = [];
        for (final item in data) {
          final numero = item['numero']?.toString() ?? '';
          final nome = item['nome'] ?? item['descricao'] ?? 'Eixo';
          final display = numero.isNotEmpty ? '${numero.padLeft(2, '0')} - $nome' : nome;
          opts.add(display);
          final eixoId = _toInt(item['eixo_id']) ?? _toInt(item['id']);
          if (eixoId != null) _eixoNameToId[display] = eixoId;
        }
        setState(() {
          _thematicAxisOptions.clear();
          _thematicAxisOptions.addAll(opts);
          if (opts.isNotEmpty) _selectedThematicAxis = opts.first;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar eixos: $e');
    }
  }

  Future<void> _loadTemas() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/themes'), headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final List<String> opts = [];
        for (final item in data) {
          final nome = item['nome'] ?? item['descricao'] ?? 'Tema';
          // try build cat code if available
          final eixoNumero = item['eixo'] != null ? (item['eixo']['numero']?.toString() ?? '') : (item['eixo_numero']?.toString() ?? '');
          final temaNumero = item['numero']?.toString() ?? item['tema_numero']?.toString() ?? '';
          final display = (eixoNumero.isNotEmpty && temaNumero.isNotEmpty)
              ? 'cat $eixoNumero.${temaNumero.padLeft(2, '0')} - $nome'
              : nome;
          opts.add(display);
          final temaId = _toInt(item['tema_id']) ?? _toInt(item['id']);
          if (temaId != null) _temaNameToId[display] = temaId;
        }
        setState(() {
          _projectIdOptions.clear();
          _projectIdOptions.addAll(opts);
          if (opts.isNotEmpty) _selectedProjectId = opts.first;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar temas: $e');
    }
  }

  Future<void> _loadPriorities() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/priority-action'), headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final List<String> opts = [];
        for (final item in data) {
          final nome = item['nome'] ?? item['descricao'] ?? 'Prioridade';
          opts.add(nome);
          final prId = _toInt(item['prioridade_id']) ?? _toInt(item['id']);
          if (prId != null) _priorityNameToId[nome] = prId;
        }
        setState(() {
          _priorityOptions.clear();
          _priorityOptions.addAll(opts);
          if (opts.isNotEmpty) _selectedPriority = opts.first;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar prioridades: $e');
    }
  }

  Future<void> _loadPgas() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/pga'), headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final List<String> opts = [];
        _pgaByYear.clear();
        
        for (final raw in data) {
          final item = Map<String, dynamic>.from(raw);
          final ano = item['ano']?.toString() ?? '';
          final titulo = ano.isNotEmpty ? ano : (item['titulo']?.toString() ?? 'PGA');
          if (!opts.contains(titulo)) opts.add(titulo);
          _pgaByYear[titulo] = item;
        }
        
        setState(() {
          _pgaOptions
            ..clear()
            ..addAll(opts);
          if (opts.isNotEmpty) _selectedYear = opts.first;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar PGAs: $e');
    }
  }

  /// Limpa todos os campos do formulário e rascunhos
  Future<void> _clearForm() async {
    // Remover rascunho do banco de dados primeiro
    if (_draftLocalId != null) {
      try {
        await _localDb.deleteDraftByLocalId(_draftLocalId!);
        debugPrint('✅ Rascunho removido com sucesso');
      } catch (e) {
        debugPrint('❌ Erro ao remover rascunho: $e');
      }
    }
    
    setState(() {
      // Limpar controladores de texto
      _nameController.clear();
      _descriptionController.clear();
      _justificationController.clear();
      _objectivesController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _costController.text = 'R\$ 0,00';
      _resourceSourceController.clear();
      
      // Resetar checkboxes
      _mandatoryInclusion = false;
      _mandatorySustainability = false;
      
      // Limpar listas de pessoas, etapas e problemas
      _responsiblePeople.clear();
      _collaborators.clear();
      _projectSteps.clear();
      _problemSituations.clear();
      
      // Resetar ID do rascunho
      _draftLocalId = null;
      
      // Resetar selects para primeira opção (se disponível)
      if (_thematicAxisOptions.isNotEmpty) {
        _selectedThematicAxis = _thematicAxisOptions.first;
      }
      if (_projectIdOptions.isNotEmpty) {
        _selectedProjectId = _projectIdOptions.first;
      }
      if (_pgaOptions.isNotEmpty) {
        _selectedYear = _pgaOptions.first;
      }
      if (_priorityOptions.isNotEmpty) {
        _selectedPriority = _priorityOptions.first;
      }
    });
    
    // Adicionar pelo menos um responsável vazio após limpar o state
    _addResponsiblePerson();
    
    debugPrint('✅ Formulário limpo com sucesso');
  }

  @override
  void dispose() {
    _saveDraft();
    _autosaveTimer?.cancel();
    
    // Dispose de todos os controladores
    _nameController.dispose();
    _descriptionController.dispose();
    _justificationController.dispose();
    _objectivesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _costController.dispose();
    _resourceSourceController.dispose();
    
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _addResponsiblePerson() {
    setState(() {
      _responsiblePeople.add({
        'name': '',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'pessoa_id': null,
        'papel': 'Coordenador',
      });
    });
  }

  void _removeResponsiblePerson(String id) {
    setState(() {
      _responsiblePeople.removeWhere((person) => person['id'] == id);
    });
  }

  void _addCollaborator() {
    setState(() {
      _collaborators.add({
        'name': '',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'pessoa_id': null,
        'papel': 'Colaborador',
      });
    });
  }

  void _removeCollaborator(String id) {
    setState(() {
      _collaborators.removeWhere((c) => c['id'] == id);
    });
  }

  void _addProjectStep() {
    setState(() {
      _projectSteps.add({
        'description': '',
        'deliverable': '',
        'deliverable_id': null,
        'referenceNumber': '',
        'plannedDate': '',
        'actualDate': '',
        // use canonical values for status_verificacao (backend enum): 'Pendente', 'OK', 'RequerAcao'
        'verification': null,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    });
  }

  void _removeProjectStep(String id) {
    setState(() {
      _projectSteps.removeWhere((step) => step['id'] == id);
    });
  }

  void _addProblemSituation() {
    setState(() {
      _problemSituations.add({
        'situation': '',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    });
  }

  void _removeProblemSituation(String id) {
    setState(() {
      _problemSituations.removeWhere((p) => p['id'] == id);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
    try {
      // Construir objeto do projeto a partir do formulário
      final project = {
        'nome': _nameController.text,
        'descricao': _descriptionController.text,
        'justificativa': _justificationController.text,
        'objetivos': _objectivesController.text,
        'data_inicio': _startDateController.text,
        'data_fim': _endDateController.text,
        'custo': _costController.text,
        'eixo': _selectedThematicAxis,
        'tema': _selectedProjectId,
        'ano': _selectedYear,
        'prioridade': _selectedPriority,
        'responsaveis': _responsiblePeople,
        'colaboradores': _collaborators,
        'etapas': _projectSteps,
        'problemas': _problemSituations,
      };

      // gerar localId
      final localId = DateTime.now().millisecondsSinceEpoch.toString();

      final db = LocalDB();
      // salvar no SQLite local com local_id
      await db.saveProject(jsonEncode(project), localId: localId);

      // Mapear valores selecionados para IDs do backend
      int? mappedPgaId;
      final selectedObj = _pgaByYear[_selectedYear];
      if (selectedObj != null) {
        final idVal = selectedObj['pga_id'] ?? selectedObj['id'];
        mappedPgaId = _toInt(idVal);
      }
      
      final int? mappedEixoId = _eixoNameToId[_selectedThematicAxis];
      final int? mappedTemaId = _temaNameToId[_selectedProjectId];
      final int? mappedPrioridadeId = _priorityNameToId[_selectedPriority];

      // Avisos se IDs não encontrados
      if (mappedPgaId == null) debugPrint('⚠️ PGA ID não encontrado para ano "$_selectedYear"');
      if (mappedEixoId == null) debugPrint('⚠️ Eixo ID não encontrado para "$_selectedThematicAxis"');
      if (mappedTemaId == null) debugPrint('⚠️ Tema ID não encontrado para "$_selectedProjectId"');
      if (mappedPrioridadeId == null) debugPrint('⚠️ Prioridade ID não encontrado para "$_selectedPriority"');

      // Montar payload para o backend
      final payload = {
        'codigo_projeto': 'LOCAL-$localId',
        'nome_projeto': _nameController.text,
        'pga_id': mappedPgaId,
        'eixo_id': mappedEixoId,
        'prioridade_id': mappedPrioridadeId,
        'tema_id': mappedTemaId,
        'o_que_sera_feito': _descriptionController.text,
        'por_que_sera_feito': _justificationController.text,
        'data_inicio': _toIsoDate(_startDateController.text),
        'data_final': _toIsoDate(_endDateController.text),
        'objetivos_institucionais_referenciados': _objectivesController.text,
        'obrigatorio_inclusao': _mandatoryInclusion,
        'obrigatorio_sustentabilidade': _mandatorySustainability,
        'custo_total_estimado': double.tryParse(_costController.text.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0.0,
        'fonte_recursos': _resourceSourceController.text,
      };

      // enfileirar sync (POST /project1) com referência local
      await db.enqueueSync('create_project', '/project1', 'POST', jsonEncode(payload), localRef: localId);

      // Enfileirar pessoas responsáveis
      for (final person in _responsiblePeople) {
        final pessoaId = _toInt(person['pessoa_id']);
        final personPayload = {
          'acao_projeto_local_ref': localId,
          if (pessoaId != null) 'pessoa_id': pessoaId,
          'papel': person['papel'] ?? 'Coordenador',
        };
        await db.enqueueSync('attach_person', '/project-person', 'POST', jsonEncode(personPayload), localRef: localId);
      }

      // Enfileirar etapas do projeto
      for (final step in _projectSteps) {
        final stepPayload = {
          'acao_projeto_local_ref': localId,
          'descricao': step['description'] ?? '',
          if (step['deliverable_id'] != null) 'entregavel_id': step['deliverable_id'],
          if (step['referenceNumber'] != null && (step['referenceNumber'] as String).isNotEmpty) 
            'numero_ref': step['referenceNumber'],
          if (_toIsoDate(step['plannedDate']?.toString()) != null) 
            'data_verificacao_prevista': _toIsoDate(step['plannedDate']?.toString()),
          if (_toIsoDate(step['actualDate']?.toString()) != null) 
            'data_verificacao_realizada': _toIsoDate(step['actualDate']?.toString()),
          if (step['verification'] != null && (step['verification'] as String).isNotEmpty) 
            'status_verificacao': step['verification'],
        };
        await db.enqueueSync('create_step', '/process-step', 'POST', jsonEncode(stepPayload), localRef: localId);
      }

      // Enfileirar situações problema
      for (final problema in _problemSituations) {
        final probPayload = {
          'acao_projeto_local_ref': localId,
          'titulo': problema['situation'] ?? '',
        };
        await db.enqueueSync('create_problem', '/problem-situation', 'POST', jsonEncode(probPayload), localRef: localId);
      }

      // tentar sincronizar agora (se online)
      final sync = SyncService();
      await sync.trySyncAll(AppConfig.baseUrl);

      // Limpar formulário e rascunhos após sucesso
      await _clearForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projeto criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/projects');
      }
    } catch (e) {
      debugPrint('Erro ao salvar projeto localmente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar projeto. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/projects'),
        ),
        title: const Text(
          'Criar Novo Projeto',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.black),
            tooltip: 'Limpar formulário',
            onPressed: () async {
              // Confirmar antes de limpar
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
                await _clearForm();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formulário limpo com sucesso!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              }
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Text(
                'A',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título principal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Criar Novo Projeto',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedThematicAxis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Seção 1: Identificação do Projeto
              _buildSectionCard(
                'Identificação do Projeto',
                [
                  _buildDropdownField(
                    'Eixo Temático',
                    _selectedThematicAxis,
                    _thematicAxisOptions,
                    (value) => setState(() => _selectedThematicAxis = value!),
                    enabled: true,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    'ID/Tema do Projeto (Conforme PGA)',
                    _selectedProjectId,
                    _projectIdOptions,
                    (value) => setState(() => _selectedProjectId = value!),
                    enabled: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Nome do Projeto',
                    _nameController,
                    hintText: 'Digite o nome do projeto',
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    'Ano (PGA)',
                    _selectedYear,
                    _pgaOptions,
                    (value) => setState(() => _selectedYear = value!),
                    hintText: 'Selecione o ano do PGA',
                  ),
                    const SizedBox(height: 16),
                  _buildDropdownField(
                    'Prioridade/Origem da Ação',
                    _selectedPriority,
                    _priorityOptions,
                    (value) => setState(() => _selectedPriority = value!),
                    hintText: 'Selecione a Prioridade/Origem',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Seção 2: Descrições
              _buildSectionCard(
                'Descrições',
                [
                  _buildTextField(
                    'O que será feito (Descrição da Ação/Projeto)',
                    _descriptionController,
                    maxLines: 4,
                    hintText: 'Descreva detalhadamente o que será feito',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Por que será feito (Justificativa da Ação/Projeto)',
                    _justificationController,
                    maxLines: 4,
                    hintText: 'Explique a justificativa para esta ação/projeto',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Objetivos Institucionais Referenciados',
                    _objectivesController,
                    maxLines: 4,
                    hintText: 'Descreva os objetivos institucionais relacionados',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Seção 3: Inclusão, Sustentabilidade e Datas
              _buildSectionCard(
                'Inclusão, Sustentabilidade e Datas',
                [
                  Row(
                    children: [
                      Checkbox(
                        value: _mandatoryInclusion,
                        onChanged: (value) => setState(() => _mandatoryInclusion = value!),
                      ),
                      const Expanded(
                        child: Text('Marque se a ação/projeto promove inclusão.'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _mandatorySustainability,
                        onChanged: (value) => setState(() => _mandatorySustainability = value!),
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
                        child: _buildDateField(
                          'Início Previsto',
                          _startDateController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                           'Final Previsto',
                          _endDateController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Seção 4: Pessoas Envolvidas
              _buildSectionCard(
                'Pessoas Envolvidas no Projeto',
                [
                  const Text('Responsáveis', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._responsiblePeople.map((person) => _buildPersonField(
                    'Responsável',
                    person,
                    _removeResponsiblePerson,
                  )),
                  const SizedBox(height: 12),
                  const Text('Colaboradores', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._collaborators.map((person) => _buildPersonField(
                    'Colaborador',
                    person,
                    _removeCollaborator,
                  )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addResponsiblePerson,
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Adicionar Responsável'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addCollaborator,
                          icon: const Icon(Icons.group_add, size: 18),
                          label: const Text('Adicionar Colaborador'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Seção 5: Etapas do Projeto
              _buildSectionCard(
                'Etapas do Projeto/Processo',
                [
                  ..._projectSteps.map((step) => _buildProjectStepField(step)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addProjectStep,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar Etapa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Seção 6: Custos
              _buildSectionCard(
                'Informações de Custos',
                [
                  _buildTextField(
                    'Custo Estimado (R\$)',
                    _costController,
                    keyboardType: TextInputType.number,
                  ),
                    const SizedBox(height: 16),
                  _buildTextField(
                    'Fonte(s) dos Recursos',
                    _resourceSourceController,
                    hintText: 'Ex: Orçamento Institucional, Projeto Específico, etc.',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Seção 7: Situações Problema
              _buildSectionCard(
                'Situação Problema / Oportunidade de Melhoria Associada',
                [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Selecionar situação problema...',
                      border: OutlineInputBorder(),
                    ),
                    items: _problemOptions.map<DropdownMenuItem<String>>((p) {
                      final id = p['id'] ?? p['problem_situation_id'];
                      final title = (p['titulo'] ?? p['nome'] ?? p['descricao'] ?? 'Situação').toString();
                      final val = id != null ? id.toString() : title;
                      return DropdownMenuItem<String>(value: val, child: Text(title));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        // find object
                        final sel = _problemOptions.firstWhere((p) => (p['id']?.toString() == value) || (p['titulo'] == value), orElse: () => {});
                        if (sel.isNotEmpty) {
                          _problemSituations.add({'situation': sel['titulo'] ?? sel['nome'] ?? value, 'id': DateTime.now().millisecondsSinceEpoch.toString(), 'problem_situation_id': sel['id']});
                        }
                      });
                    },
                    isExpanded: true,
                    menuMaxHeight: 200,
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconEnabledColor: Colors.grey[600],
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    hint: const Text('Selecione uma situação'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addProblemSituation,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Adicionar Situação'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_problemSituations.isNotEmpty) {
                              final lastId = _problemSituations.last['id'] as String?;
                              if (lastId != null) _removeProblemSituation(lastId);
                            }
                          },
                          icon: const Icon(Icons.remove, size: 18),
                          label: const Text('Remover'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            
                    const SizedBox(height: 32),

              // Botões: Salvar Rascunho + Registrar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saveDraft,
                      child: const Text('Salvar Rascunho'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
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
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
            ),
        ),
      ),

      // Navegação inferior
      bottomNavigationBar: BottomNavigation(
        currentRoute: '/create-project',
        onNavigate: (route) {
          if (route == '/create-project') return;
          context.go(route);
        },
      ),
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
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
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
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged, {
    bool enabled = true,
    String? hintText,
  }) {
    // remove duplicate entries while preserving order
    final List<String> uniqueItems = [];
    for (final it in items) {
      if (!uniqueItems.contains(it)) uniqueItems.add(it);
    }
    final effectiveValue = (value.isEmpty ? null : (uniqueItems.contains(value) ? value : null));

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: uniqueItems.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      menuMaxHeight: 200,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down),
      iconEnabledColor: enabled ? Colors.grey[600] : Colors.grey[400],
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey[600],
        fontSize: 16,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/mm/aaaa',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(controller),
        ),
      ),
      readOnly: true,
    );
  }

  Widget _buildPersonField(
    String label,
    Map<String, dynamic> person,
    Function(String) onRemove,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Builder(builder: (ctx) {
                  // build set of used pessoa_ids except this one
                  final used = <int>{};
                  for (final p in _responsiblePeople) {
                    final id = _toInt(p['pessoa_id']);
                    if (id != null) used.add(id);
                  }
                  for (final p in _collaborators) {
                    final id = _toInt(p['pessoa_id']);
                    if (id != null) used.add(id);
                  }
                  final currentId = _toInt(person['pessoa_id']);
                  if (currentId != null) used.remove(currentId);

                  final items = <DropdownMenuItem<int>>[];
                  for (final u in _users) {
                    final idVal = u['pessoa_id'] ?? u['id'];
                    final id = _toInt(idVal);
                    if (id == null) continue;
                    if (used.contains(id)) continue; // prevent duplicates
                    final labelText = _userLabel(u);
                    items.add(DropdownMenuItem<int>(value: id, child: Text(labelText)));
                  }

                  return DropdownButtonFormField<int>(
                    value: currentId,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: items,
                    onChanged: (value) {
                      setState(() {
                        person['pessoa_id'] = value;
                        final match = _users.firstWhere((u) => _toInt(u['pessoa_id'] ?? u['id']) == value, orElse: () => {});
                        if (match.isNotEmpty) {
                          final role = (match['tipo_usuario'] ?? match['tipoUsuario'] ?? match['cargo'])?.toString();
                          person['name'] = match['nome'] ?? match['name'] ?? '';
                          person['role_label'] = role;
                        } else {
                          person['name'] = '';
                          person['role_label'] = null;
                        }
                      });
                    },
                    isExpanded: true,
                    menuMaxHeight: 200,
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconEnabledColor: Colors.grey[600],
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    hint: const Text('Selecione uma pessoa'),
                  );
                }),
              ),
              Builder(builder: (_) {
                final isFirstResponsible = _responsiblePeople.isNotEmpty && _responsiblePeople.first['id'] == person['id'];
                if (isFirstResponsible) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => onRemove(person['id']),
                );
              }),
            ],
          ),

          // se for colaborador, mostrar campos de carga horária e tipo vínculo
          if (person['papel'] == 'Colaborador' || person['papel'] == 'colaborador')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: person['carga_horaria_semanal']?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carga Horária Semanal (h)'),
                      onChanged: (v) => person['carga_horaria_semanal'] = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _toInt(person['tipo_vinculo_hae_id']),
                      decoration: const InputDecoration(labelText: 'Tipo Vínculo HAE'),
                      items: _workloadTypes.map<DropdownMenuItem<int>>((w) {
                        final idVal = w['id'] ?? w['workload_hae_id'];
                        final id = _toInt(idVal);
                        final label = (w['sigla'] ?? w['descricao'] ?? w['titulo'] ?? '').toString();
                        return id != null ? DropdownMenuItem<int>(value: id, child: Text(label)) : DropdownMenuItem<int>(value: -1, child: Text(label));
                      }).where((it) => it.value != -1).toList(),
                      onChanged: (v) => person['tipo_vinculo_hae_id'] = v,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectStepField(Map<String, dynamic> step) {
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
              Text(
                'Etapa #${_projectSteps.indexOf(step) + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _removeProjectStep(step['id']),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: step['description'],
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descrição da Etapa',
              hintText: 'Descreva a etapa do projeto',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            onChanged: (value) {
              step['description'] = value;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: step['deliverable_id'] as int?,
            decoration: const InputDecoration(
              labelText: 'Entregável (link/SEI)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: _deliverables.map((d) {
              final did = _toInt(d['id']);
              return did != null
                  ? DropdownMenuItem<int>(value: did, child: Text(d['titulo'] ?? d['nome'] ?? d['descricao'] ?? 'Entregável'))
                  : null;
            }).where((it) => it != null).cast<DropdownMenuItem<int>>().toList(),
            onChanged: (value) {
              setState(() {
                step['deliverable_id'] = value;
                final match = _deliverables.firstWhere((d) => _toInt(d['id']) == value, orElse: () => {});
                step['deliverable'] = match.isNotEmpty ? (match['titulo'] ?? match['nome'] ?? '') : '';
              });
            },
            isExpanded: true,
            menuMaxHeight: 200,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down),
            iconEnabledColor: Colors.grey[600],
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
            hint: const Text('Selecione o entregável'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: step['referenceNumber'],
            decoration: const InputDecoration(
              labelText: 'Número de Referência',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            onChanged: (value) {
              step['referenceNumber'] = value;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('planned_${step['id']}_${step['plannedDate']}'),
            initialValue: step['plannedDate']?.toString() ?? '',
            decoration: InputDecoration(
              labelText: 'Data Verificação Prevista',
              hintText: 'dd/mm/aaaa',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    setState(() {
                      step['plannedDate'] = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    });
                  }
                },
              ),
            ),
            readOnly: true,
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: const Locale('pt', 'BR'),
              );
              if (picked != null) {
                setState(() {
                  step['plannedDate'] = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('actual_${step['id']}_${step['actualDate']}'),
            initialValue: step['actualDate']?.toString() ?? '',
            decoration: InputDecoration(
              labelText: 'Data Verificação Realizada',
              hintText: 'dd/mm/aaaa',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    setState(() {
                      step['actualDate'] = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    });
                  }
                },
              ),
            ),
            readOnly: true,
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: const Locale('pt', 'BR'),
              );
              if (picked != null) {
                setState(() {
                  step['actualDate'] = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Verificação:'),
              const SizedBox(width: 8),
              Row(
                children: [
                  Radio<String>(
                    value: 'OK',
                    groupValue: step['verification'] as String?,
                    onChanged: (value) {
                      setState(() {
                        step['verification'] = value;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text('OK'),
                ],
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Radio<String>(
                    value: 'RequerAcao',
                    groupValue: step['verification'] as String?,
                    onChanged: (value) {
                      setState(() {
                        step['verification'] = value;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text('Requer Ação'),
                ],
              ),
            ],
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}
