import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_storage.dart';
import '../services/config.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import 'package:http/http.dart' as http;

class CreateProjectController extends ChangeNotifier {
  // Form key
  final formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final justificationController = TextEditingController();
  final objectivesController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final costController = TextEditingController();
  final resourceSourceController = TextEditingController();

  // State variables
  String _selectedThematicAxis = '';
  String _selectedProjectId = '';
  String _selectedYear = '';
  String _selectedPriority = '';
  bool _mandatoryInclusion = false;
  bool _mandatorySustainability = false;
  bool _isLoading = false;

  String get selectedThematicAxis => _selectedThematicAxis;
  set selectedThematicAxis(String value) {
    _selectedThematicAxis = value;
    _filterTemasByEixo();
    notifyListeners();
  }

  String get selectedProjectId => _selectedProjectId;
  set selectedProjectId(String value) {
    _selectedProjectId = value;
    notifyListeners();
  }

  String get selectedYear => _selectedYear;
  set selectedYear(String value) {
    _selectedYear = value;
    notifyListeners();
  }

  String get selectedPriority => _selectedPriority;
  set selectedPriority(String value) {
    _selectedPriority = value;
    notifyListeners();
  }

  bool get mandatoryInclusion => _mandatoryInclusion;
  set mandatoryInclusion(bool value) {
    _mandatoryInclusion = value;
    notifyListeners();
  }

  bool get mandatorySustainability => _mandatorySustainability;
  set mandatorySustainability(bool value) {
    _mandatorySustainability = value;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Mappings
  final Map<String, int> eixoNameToId = {};
  final Map<String, int> temaNameToId = {};
  final Map<String, int> priorityNameToId = {};
  final List<String> pgaOptions = [];
  final Map<String, Map<String, dynamic>> pgaByYear = {};

  // Dynamic lists
  final List<Map<String, dynamic>> responsiblePeople = [];
  final List<Map<String, dynamic>> collaborators = [];
  final List<Map<String, dynamic>> projectSteps = [];
  final List<Map<String, dynamic>> problemSituations = [];

  // Options
  final List<String> thematicAxisOptions = [];
  final List<String> projectIdOptions = [];
  final List<String> priorityOptions = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> deliverables = [];
  List<Map<String, dynamic>> problemOptions = [];
  List<Map<String, dynamic>> workloadTypes = [];
  
  final List<Map<String, dynamic>> _allTemas = [];

  final LocalDB _localDb = LocalDB();
  String? draftLocalId;
  Timer? autosaveTimer;

  CreateProjectController() {
    _initialize();
  }

  double getCostValue() {
    final text = costController.text;
    final numbersOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numbersOnly.isEmpty) {
      return 0.0;
    }
    
    final number = int.parse(numbersOnly);
    return number / 100.0;
  }

  void _initialize() {
    loadSelectOptions();
    loadPeopleAndDeliverables();
    loadDraft();
    
    autosaveTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      saveDraft();
    });

    if (responsiblePeople.isEmpty) addResponsiblePerson();
  }

  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  String userLabel(Map<String, dynamic> u) {
    final roleRaw = (u['tipo_usuario'] ?? u['tipoUsuario'] ?? u['cargo']);
    final role = roleRaw?.toString();
    final name = (u['nome'] ?? u['name'] ?? u['email'] ?? 'Usuário').toString();
    return role != null && role.isNotEmpty ? '$name ($role)' : name;
  }

  String? toIsoDate(String? ddmmyyyy) {
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

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorage.readToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<void> loadDraft() async {
    try {
      final drafts = await _localDb.getDrafts('create_project');
      if (drafts.isNotEmpty) {
        final row = drafts.last;
        final dataStr = row['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final Map<String, dynamic> doc = jsonDecode(dataStr);
          
          nameController.text = doc['nome'] ?? '';
          descriptionController.text = doc['descricao'] ?? '';
          justificationController.text = doc['justificativa'] ?? '';
          objectivesController.text = doc['objetivos'] ?? '';
          startDateController.text = doc['data_inicio'] ?? '';
          endDateController.text = doc['data_fim'] ?? '';
          costController.text = doc['custo'] ?? 'R\$ 0,00';
          resourceSourceController.text = doc['fonte_recursos'] ?? '';
          selectedThematicAxis = doc['eixo'] ?? '';
          selectedProjectId = doc['tema'] ?? '';
          selectedYear = doc['ano'] ?? '';
          selectedPriority = doc['prioridade'] ?? '';
          mandatoryInclusion = doc['obrigatorio_inclusao'] ?? false;
          mandatorySustainability = doc['obrigatorio_sustentabilidade'] ?? false;
          
          if (doc['responsaveis'] != null) {
            responsiblePeople.clear();
            responsiblePeople.addAll(List<Map<String, dynamic>>.from(doc['responsaveis']));
          }
          if (doc['colaboradores'] != null) {
            collaborators.clear();
            collaborators.addAll(List<Map<String, dynamic>>.from(doc['colaboradores']));
          }
          if (doc['etapas'] != null) {
            projectSteps.clear();
            projectSteps.addAll(List<Map<String, dynamic>>.from(doc['etapas']));
          }
          if (doc['problemas'] != null) {
            problemSituations.clear();
            problemSituations.addAll(List<Map<String, dynamic>>.from(doc['problemas']));
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar rascunho: $e');
    }
  }

  Future<void> saveDraft() async {
    try {
      final draft = {
        'nome': nameController.text,
        'descricao': descriptionController.text,
        'justificativa': justificationController.text,
        'objetivos': objectivesController.text,
        'data_inicio': startDateController.text,
        'data_fim': endDateController.text,
        'custo': costController.text,
        'fonte_recursos': resourceSourceController.text,
        'eixo': selectedThematicAxis,
        'tema': selectedProjectId,
        'ano': selectedYear,
        'prioridade': selectedPriority,
        'obrigatorio_inclusao': mandatoryInclusion,
        'obrigatorio_sustentabilidade': mandatorySustainability,
        'responsaveis': responsiblePeople,
        'colaboradores': collaborators,
        'etapas': projectSteps,
        'problemas': problemSituations,
      };
      final jsonStr = jsonEncode(draft);
      await _localDb.saveDraft('create_project', jsonStr, localId: draftLocalId);
      draftLocalId ??= DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      debugPrint('Erro ao salvar rascunho: $e');
    }
  }

  Future<void> loadSelectOptions() async {
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
        final List data = jsonDecode(res.body);
        final List<String> opts = [];
        for (final item in data) {
          final numero = item['numero']?.toString() ?? '';
          final nome = item['nome'] ?? item['descricao'] ?? 'Eixo';
          final display = numero.isNotEmpty ? '${numero.padLeft(2, '0')} - $nome' : nome;
          opts.add(display);
          final eixoId = toInt(item['eixo_id']) ?? toInt(item['id']);
          if (eixoId != null) eixoNameToId[display] = eixoId;
        }
        thematicAxisOptions.clear();
        thematicAxisOptions.addAll(opts);
        if (opts.isNotEmpty) {
          _selectedThematicAxis = opts.first;
          _filterTemasByEixo();
        }
        notifyListeners();
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
        final List data = jsonDecode(res.body);
        
        _allTemas.clear();
        temaNameToId.clear();
        
        for (final item in data) {
          final Map<String, dynamic> temaData = Map<String, dynamic>.from(item);
          final nome = temaData['nome'] ?? temaData['descricao'] ?? 'Tema';
          final eixoId = toInt(temaData['eixo_id']) ?? 
                         (temaData['eixo'] != null ? toInt(temaData['eixo']['eixo_id']) : null);
          final eixoNumero = temaData['eixo'] != null ? (temaData['eixo']['numero']?.toString() ?? '') : (temaData['eixo_numero']?.toString() ?? '');
          final temaNumero = temaData['numero']?.toString() ?? temaData['tema_numero']?.toString() ?? '';
          final display = (eixoNumero.isNotEmpty && temaNumero.isNotEmpty)
              ? '$eixoNumero.${temaNumero.padLeft(2, '0')} - $nome'
              : nome;
          
          final temaId = toInt(temaData['tema_id']) ?? toInt(temaData['id']);
          
          _allTemas.add({
            'display': display,
            'eixo_id': eixoId,
            'tema_id': temaId,
            'original': temaData,
          });
          
          if (temaId != null) {
            temaNameToId[display] = temaId;
          }
        }

        _filterTemasByEixo();
      }
    } catch (e) {
      debugPrint('Erro ao carregar temas: $e');
    }
  }
  
  void _filterTemasByEixo() {
    if (_allTemas.isEmpty) {
      projectIdOptions.clear();
      notifyListeners();
      return;
    }
    
    final selectedEixoId = eixoNameToId[_selectedThematicAxis];
    
    if (selectedEixoId == null) {
      projectIdOptions.clear();
      projectIdOptions.addAll(_allTemas.map((t) => t['display'] as String));
      if (projectIdOptions.isNotEmpty) {
        selectedProjectId = projectIdOptions.first;
      }
    } else {
      final filtered = _allTemas.where((tema) {
        final temaEixoId = tema['eixo_id'];
        return temaEixoId == selectedEixoId;
      }).map((t) => t['display'] as String).toList();
      
      projectIdOptions.clear();
      projectIdOptions.addAll(filtered);
      
      if (projectIdOptions.isNotEmpty && !projectIdOptions.contains(_selectedProjectId)) {
        selectedProjectId = projectIdOptions.first;
      } else if (projectIdOptions.isEmpty) {
        selectedProjectId = '';
      }
    }
    
    notifyListeners();
  }

  Future<void> _loadPriorities() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/priority-action'), headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final List<String> opts = [];
        for (final item in data) {
          final nome = item['nome'] ?? item['descricao'] ?? 'Prioridade';
          opts.add(nome);
          final prId = toInt(item['prioridade_id']) ?? toInt(item['id']);
          if (prId != null) priorityNameToId[nome] = prId;
        }
        priorityOptions.clear();
        priorityOptions.addAll(opts);
        if (opts.isNotEmpty) selectedPriority = opts.first;
        notifyListeners();
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
        final List data = jsonDecode(res.body);
        final List<String> opts = [];
        pgaByYear.clear();
        
        for (final raw in data) {
          final item = Map<String, dynamic>.from(raw);
          final ano = item['ano']?.toString() ?? '';
          final titulo = ano.isNotEmpty ? ano : (item['titulo']?.toString() ?? 'PGA');
          if (!opts.contains(titulo)) opts.add(titulo);
          pgaByYear[titulo] = item;
        }
        
        pgaOptions.clear();
        pgaOptions.addAll(opts);
        if (opts.isNotEmpty) selectedYear = opts.first;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar PGAs: $e');
    }
  }

  Future<void> loadPeopleAndDeliverables() async {
    try {
      final headers = await _authHeaders();
      
      final usersRes = await http.get(Uri.parse('${AppConfig.baseUrl}/users'), headers: headers);
      if (usersRes.statusCode == 200) {
        final List data = jsonDecode(usersRes.body);
        users = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      final deliversRes = await http.get(Uri.parse('${AppConfig.baseUrl}/deliverable'), headers: headers);
      if (deliversRes.statusCode == 200) {
        final List data = jsonDecode(deliversRes.body);
        deliverables = data.map((raw) {
          final Map<String, dynamic> item = Map<String, dynamic>.from(raw);
          final dynamic idVal = item['entregavel_id'] ?? item['id'] ?? item['deliverable_id'];
          final int? id = toInt(idVal);
          final String titulo = (item['descricao'] ?? item['detalhes'] ?? item['titulo'] ?? item['nome'] ?? '').toString();
          return {
            'id': id,
            'titulo': titulo,
          };
        }).toList();
      }

      final problemsRes = await http.get(Uri.parse('${AppConfig.baseUrl}/problem-situation'), headers: headers);
      if (problemsRes.statusCode == 200) {
        final List data = jsonDecode(problemsRes.body);
        problemOptions = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      final workloadRes = await http.get(Uri.parse('${AppConfig.baseUrl}/workload-hae'), headers: headers);
      if (workloadRes.statusCode == 200) {
        final List data = jsonDecode(workloadRes.body);
        workloadTypes = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar pessoas/entregaveis/problemas: $e');
    }
  }

  void addResponsiblePerson() {
    responsiblePeople.add({
      'name': '',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'pessoa_id': null,
      'papel': 'Responsavel',
    });
    notifyListeners();
  }

  void removeResponsiblePerson(String id) {
    responsiblePeople.removeWhere((person) => person['id'] == id);
    notifyListeners();
  }

  void addCollaborator() {
    collaborators.add({
      'name': '',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'pessoa_id': null,
      'papel': 'Colaborador',
      'carga_horaria_semanal': null,
      'tipo_vinculo_hae_id': null,
    });
    notifyListeners();
  }

  void removeCollaborator(String id) {
    collaborators.removeWhere((c) => c['id'] == id);
    notifyListeners();
  }

  void addProjectStep() {
    projectSteps.add({
      'description': '',
      'deliverable': '',
      'deliverable_id': null,
      'referenceNumber': '',
      'plannedDate': '',
      'actualDate': '',
      'verification': null,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    notifyListeners();
  }

  void removeProjectStep(String id) {
    projectSteps.removeWhere((step) => step['id'] == id);
    notifyListeners();
  }

  void updateProjectStepDate(String stepId, String dateField, String date) {
    final step = projectSteps.firstWhere(
      (s) => s['id'] == stepId,
      orElse: () => {},
    );
    if (step.isNotEmpty) {
      step[dateField] = date;
      notifyListeners();
    }
  }

  void updateProjectStepVerification(String stepId, String? verification) {
    final step = projectSteps.firstWhere(
      (s) => s['id'] == stepId,
      orElse: () => {},
    );
    if (step.isNotEmpty) {
      step['verification'] = verification;
      notifyListeners();
    }
  }

  void addProblemSituation() {
    problemSituations.add({
      'situation': '',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    notifyListeners();
  }

  void removeProblemSituation(String id) {
    problemSituations.removeWhere((p) => p['id'] == id);
    notifyListeners();
  }

  void updateProblemSituation(int index, String problemSituationId) {
    if (index >= 0 && index < problemSituations.length) {
      final sel = problemOptions.firstWhere(
        (p) => (p['situacao_id']?.toString() == problemSituationId || 
               p['id']?.toString() == problemSituationId ||
               p['problem_situation_id']?.toString() == problemSituationId),
        orElse: () => {},
      );
      
      if (sel.isNotEmpty) {
        problemSituations[index] = {
          'situation': sel['descricao'] ?? sel['titulo'] ?? sel['nome'] ?? problemSituationId,
          'id': problemSituations[index]['id'],
          'problem_situation_id': sel['situacao_id'] ?? sel['id'],
        };
        notifyListeners();
      }
    }
  }

  Future<void> clearForm() async {
    if (draftLocalId != null) {
      try {
        await _localDb.deleteDraftByLocalId(draftLocalId!);
        debugPrint('✅ Rascunho removido com sucesso');
      } catch (e) {
        debugPrint('❌ Erro ao remover rascunho: $e');
      }
    }

    nameController.clear();
    descriptionController.clear();
    justificationController.clear();
    objectivesController.clear();
    startDateController.clear();
    endDateController.clear();
    costController.text = 'R\$ 0,00';
    resourceSourceController.clear();

    mandatoryInclusion = false;
    mandatorySustainability = false;

    responsiblePeople.clear();
    collaborators.clear();
    projectSteps.clear();
    problemSituations.clear();

    draftLocalId = null;

    if (thematicAxisOptions.isNotEmpty) {
      selectedThematicAxis = thematicAxisOptions.first;
    }
    if (projectIdOptions.isNotEmpty) {
      selectedProjectId = projectIdOptions.first;
    }
    if (pgaOptions.isNotEmpty) {
      selectedYear = pgaOptions.first;
    }
    if (priorityOptions.isNotEmpty) {
      selectedPriority = priorityOptions.first;
    }

    addResponsiblePerson();
    notifyListeners();
    debugPrint('✅ Formulário limpo com sucesso');
  }

  Future<bool> submitProject() async {
    if (!formKey.currentState!.validate()) return false;

    isLoading = true;
    notifyListeners();

    try {
      final project = {
        'nome': nameController.text,
        'descricao': descriptionController.text,
        'justificativa': justificationController.text,
        'objetivos': objectivesController.text,
        'data_inicio': startDateController.text,
        'data_fim': endDateController.text,
        'custo': costController.text,
        'eixo': selectedThematicAxis,
        'tema': selectedProjectId,
        'ano': selectedYear,
        'prioridade': selectedPriority,
        'responsaveis': responsiblePeople,
        'colaboradores': collaborators,
        'etapas': projectSteps,
        'problemas': problemSituations,
      };

      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      await _localDb.saveProject(jsonEncode(project), localId: localId);

      int? mappedPgaId;
      final selectedObj = pgaByYear[selectedYear];
      if (selectedObj != null) {
        final idVal = selectedObj['pga_id'] ?? selectedObj['id'];
        mappedPgaId = toInt(idVal);
      }

      final int? mappedEixoId = eixoNameToId[selectedThematicAxis];
      final int? mappedTemaId = temaNameToId[selectedProjectId];
      final int? mappedPrioridadeId = priorityNameToId[selectedPriority];

      if (mappedPgaId == null) debugPrint('⚠️ PGA ID não encontrado para ano "$selectedYear"');
      if (mappedEixoId == null) debugPrint('⚠️ Eixo ID não encontrado para "$selectedThematicAxis"');
      if (mappedTemaId == null) debugPrint('⚠️ Tema ID não encontrado para "$selectedProjectId"');
      if (mappedPrioridadeId == null) debugPrint('⚠️ Prioridade ID não encontrado para "$selectedPriority"');

      final payload = {
        'codigo_projeto': 'LOCAL-$localId',
        'nome_projeto': nameController.text,
        'pga_id': mappedPgaId,
        'eixo_id': mappedEixoId,
        'prioridade_id': mappedPrioridadeId,
        'tema_id': mappedTemaId,
        'o_que_sera_feito': descriptionController.text,
        'por_que_sera_feito': justificationController.text,
        'data_inicio': toIsoDate(startDateController.text),
        'data_final': toIsoDate(endDateController.text),
        'objetivos_institucionais_referenciados': objectivesController.text,
        'obrigatorio_inclusao': mandatoryInclusion,
        'obrigatorio_sustentabilidade': mandatorySustainability,
        'custo_total_estimado': double.tryParse(costController.text.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0.0,
        'fonte_recursos': resourceSourceController.text,
      };

      await _localDb.enqueueSync('create_project', '/project1', 'POST', jsonEncode(payload), localRef: localId);

      for (final person in responsiblePeople) {
        final pessoaId = toInt(person['pessoa_id']);
        if (pessoaId != null) {
          final personPayload = {
            'acao_projeto_local_ref': localId,
            'pessoa_id': pessoaId,
            'papel': 'Responsavel',
          };
          await _localDb.enqueueSync('attach_person', '/project-person', 'POST', jsonEncode(personPayload), localRef: localId);
        }
      }

      for (final collab in collaborators) {
        final pessoaId = toInt(collab['pessoa_id']);
        if (pessoaId != null) {
          final collabPayload = {
            'acao_projeto_local_ref': localId,
            'pessoa_id': pessoaId,
            'papel': 'Colaborador',
            if (collab['carga_horaria_semanal'] != null) 
              'carga_horaria_semanal': collab['carga_horaria_semanal'],
            if (collab['tipo_vinculo_hae_id'] != null) 
              'tipo_vinculo_hae_id': collab['tipo_vinculo_hae_id'],
          };
          await _localDb.enqueueSync('attach_collab', '/project-person', 'POST', jsonEncode(collabPayload), localRef: localId);
        }
      }

      for (final step in projectSteps) {
        final stepPayload = {
          'acao_projeto_local_ref': localId,
          'descricao': step['description'] ?? '',
          if (step['deliverable_id'] != null) 'entregavel_id': step['deliverable_id'],
          if (step['referenceNumber'] != null && (step['referenceNumber'] as String).isNotEmpty)
            'numero_ref': step['referenceNumber'],
          if (toIsoDate(step['plannedDate']?.toString()) != null)
            'data_verificacao_prevista': toIsoDate(step['plannedDate']?.toString()),
          if (toIsoDate(step['actualDate']?.toString()) != null)
            'data_verificacao_realizada': toIsoDate(step['actualDate']?.toString()),
        };
        await _localDb.enqueueSync('create_step', '/process-step', 'POST', jsonEncode(stepPayload), localRef: localId);
      }

      for (final problema in problemSituations) {
        final probPayload = {
          'acao_projeto_local_ref': localId,
          'situacao': problema['situation'] ?? '',
        };
        await _localDb.enqueueSync('create_problem', '/problem-situation', 'POST', jsonEncode(probPayload), localRef: localId);
      }

      final sync = SyncService();
      await sync.trySyncAll(AppConfig.baseUrl);

      await clearForm();

      return true;
    } catch (e) {
      debugPrint('Erro ao salvar projeto localmente: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    saveDraft();
    autosaveTimer?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    justificationController.dispose();
    objectivesController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    costController.dispose();
    resourceSourceController.dispose();
    super.dispose();
  }
}
