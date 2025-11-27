Resumo de integração local-sync (mobile)

Dependências adicionadas no pubspec.yaml:
- sqflite
- path
- flutter_secure_storage
- connectivity_plus

Arquivos criados (exemplos):
- lib/src/services/auth_storage.dart
  - salvar/ler/remover token com FlutterSecureStorage
- lib/src/services/local_db.dart
  - implementação básica de SQLite com tabelas: lookup, drafts, sync_queue
  - CRUD para lookups, drafts e fila de sincronização
- lib/src/services/sync_service.dart
  - lógica simples para iterar sobre a `sync_queue` e enviar requisições ao backend
- lib/src/services/app_init.dart
  - rotina de inicialização: valida token via `/auth/me`, listener de conectividade e tentativa de sync, fetch de lookups via `/sync/lookup`

Fluxo sugerido no app:
1) Após login bem-sucedido: salvar token com `AuthStorage.saveToken(token)`.
2) Ao iniciar o app: chamar `AppInit().initialize(baseUrl)` para validar token e começar listener de rede.
3) Ao usuário preencher um formulário parcialmente: salvar com `LocalDB.saveDraft(formType, jsonData, localId: optional)`.
4) Quando quiser enviar um formulário offline: enfileirar um sync (ex: `LocalDB.enqueueSync('create', '/project1', 'POST', jsonEncode(body), localRef: localId)`), e o `SyncService` tentará enviar quando houver conexão.
5) Para lookups (eixos, temas, unidades): prefetch via `/sync/lookup` e armazenar em `lookup` local para mostrar listas mesmo offline.

Observações importantes:
- `AppInit` supõe que exista um endpoint `/auth/me` para validar token. Se não existir, valide chamando um endpoint leve que exija autenticação (ex: `/users`) ou modifique o backend para expor `/auth/me`.
- `sync/lookup` e `/sync/batch` são endpoints recomendados no backend para facilitar sincronização; sem eles a lógica precisará mapear vários endpoints.
- A implementação criada é minimal e serve como ponto de partida; recomendo adicionar:
  - controle de retries e backoff no `sync_queue`;
  - campo de contador de tentativas e timestamps;
  - tratamento de conflitos e merge de dados.

Exemplo de uso rápido:

// salvar token após login
final token = responseJson['access_token'];
await AuthStorage.saveToken(token);

// salvar draft
await LocalDB().saveDraft('project_form', jsonEncode(formData), localId: 'local-123');

// enfileirar sync
await LocalDB().enqueueSync('create', '/project1', 'POST', jsonEncode(formData), localRef: 'local-123');

// tentar sync manualmente
await SyncService().trySyncAll('http://192.168.50.54:3000');

