# PGA Mobile - Flutter

Sistema de Gestão de Projetos Acadêmicos da Fatec Votorantim convertido para Flutter.

## 🚀 **Uma nova forma de usar o sistema PGA**

Este projeto foi feito em **Flutter** para se adequar ao site do **PGA** mantendo:
- ✅ **Layout idêntico** - Mesma aparência visual
- ✅ **Funcionalidades** - Todas as funcionalidades principais implementadas
- ✅ **Navegação** - Mesma estrutura de menus
- ✅ **Tema** - Cores e estilos da Fatec Votorantim
- ✅ **Lógica de negócio** - Validações e comportamentos

## 📱 **Funcionalidades**

- **Login** - Autenticação com validação
- **Dashboard** - Visão geral com estatísticas
- **Projetos** - Lista com filtros e busca
- **Criar Projeto** - Formulário completo
- **Configurações** - Preferências do usuário
- **Navegação** - Barra inferior funcional

## 📋 **Pré-requisitos**

1. **Flutter SDK** instalado
2. **Android Studio** ou **VS Code**
3. **Emulador Android** ou **iOS Simulator**

## 🚀 **Como Executar**

Passos básicos para desenvolver, testar e empacotar o app.

1) Preparar o projeto

```bash
# instalar dependências
flutter pub get

# checar ambiente (Android SDK, Xcode quando aplicável)
flutter doctor
```

2) Gerar ícones (se alterar `assets/icons/app_icon.png`)

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

3) Atualizar nome nativo (opcional)

```powershell
# Windows (wrapper .bat)
.\tools\update_app_name.bat "Nome do App"

# Ou chamar o PowerShell script diretamente
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\update_app_name.ps1" -NewName "Nome do App"
```

4) Rodar em modo de desenvolvimento

- Emulador Android / dispositivo USB:
```bash
flutter run
```

- Para listar dispositivos e escolher um específico:
```bash
flutter devices
flutter run -d <deviceId>
```

- iOS Simulator / dispositivo (necessita macOS + Xcode):
```bash
flutter run -d ios
```

5) Build para produção

- Android APK (debug/release):
```bash
# build debug (rápido)
flutter build apk --debug

# build release (assinatura/keystore requerida para publicar)
flutter build apk --release
```

- Android App Bundle (recomendado para Play Store):
```bash
flutter build appbundle --release
```

- iOS (macOS + Xcode necesario):
```bash
flutter build ipa
```

6) Testes e lint

```bash
# rodar testes unitários/widget
flutter test

# checar lints
flutter analyze
```

7) Observações práticas

- Se atualizar dependências execute `flutter pub get` e rode um build para checar regressões.
- Para ver o novo nome no launcher Android, normalmente é necessário desinstalar a versão anterior do aparelho/emulador e instalar a nova APK.
- iOS só é testável em dispositivos/simula­dores quando estiver em macOS com Xcode instalado.
- Se sua configuração usar flavors ou builds customizados, ajuste os comandos de build conforme seus `build.gradle` e `xcconfig`.

## 📁 **Estrutura do Projeto**

```
lib/
├── main.dart                 # Ponto de entrada
├── src/
│   ├── theme/
│   │   └── app_theme.dart   # Tema da aplicação
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── projects_screen.dart
│   │   ├── create_project_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       ├── stats_card.dart
│       ├── project_card.dart
│       └── bottom_navigation.dart
```

## 🎨 **Tema e Cores**

- **Primária**: `#AE0F0A` (Vermelho Fatec)
- **Secundária**: `#8B0000` (Vermelho escuro)
- **Fundo**: `#F5F5F5` (Cinza claro)
- **Superfície**: `#FFFFFF` (Branco)
- **Texto**: `#1C1B1F` (Preto)

## 📱 **Telas Implementadas**

### **Login Screen**
- Imagem de fundo da Fatec
- Logo da instituição
- Formulário de login
- Validação de campos
- Overlay para legibilidade

### **Dashboard Screen**
- Cards de estatísticas
- Informações da instituição
- Projetos em destaque
- Tabs de navegação
- FAB para criar projeto

### **Projects Screen**
- Lista de projetos
- Filtros por status
- Busca por nome/responsável
- Cards de projeto detalhados

### **Create Project Screen**
- Formulário completo
- Seletor de data
- Slider de progresso
- Validações
- Feedback visual

### **Settings Screen**
- Configurações de notificação
- Preferências de aparência
- Configurações do sistema
- Gerenciamento de conta
- Informações sobre o app

## 🔧 **Configurações**

### **Android**
- `android/app/build.gradle` - Configurações de build
- `android/app/src/main/AndroidManifest.xml` - Permissões

### **iOS**
- `ios/Runner/Info.plist` - Configurações do iOS
- `ios/Runner.xcodeproj` - Projeto Xcode

### **Atualizar icone**
- `flutter pub run flutter_launcher_icons:main` - Atualiza o icone do Aplicativo

## 🧰 Comandos úteis (Windows)

Se você precisar atualizar o nome nativo do aplicativo (Android/iOS) a partir do projeto Flutter, use o script fornecido em `tools/`.

- Usando o wrapper `.bat` (PowerShell ou cmd, a partir da raiz do projeto):
```powershell
.\tools\update_app_name.bat "Meu App PGA"
# ou usando a flag -NewName
.\tools\update_app_name.bat -NewName "Meu App PGA"
```

- Chamando o PowerShell script diretamente (caso prefira evitar o .bat):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "c:\Users\muril\Documents\PGA-Mobile\tools\update_app_name.ps1" -NewName "Meu App PGA"
```

Notas:
- Sempre rode o comando a partir da raiz do projeto (paths relativos esperados).
- Coloque o nome entre aspas se ele contiver espaços ou caracteres especiais.
- O script atualiza todos os arquivos `android/app/src/main/res/values*/strings.xml` e o `ios/Runner/Info.plist`.
- Depois de alterar `strings.xml`, desinstale e reinstale (uninstall/reinstall) o app no dispositivo/emulador para ver o novo nome no launcher.

Atualizar ícones:
```powershell
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## 📊 **Dados Mockados**

O projeto inclui dados de exemplo para demonstração:
- **12 projetos** com diferentes status
- **Estatísticas** realistas
- **Usuários** fictícios
- **Datas** futuras

## 🛠️ **Tecnologias e bibliotecas principais**

- **Flutter**(SDK) — framework UI para construir a aplicação mobile.
- **Dart** (linguagem) — linguagem usada pelo Flutter.
- **Go Router** (^12.1.3) — roteamento declarativo e gerenciamento de rotas.
- **Provider** (^6.1.1) — injeção de dependência e gerenciamento simples de estado.
- **Flutter Localizations** (SDK) — suporte a internacionalização/localização da UI.
- **Cupertino Icons** (^1.0.2) — ícones estilo iOS.
- **Shared Preferences** (^2.2.2) — armazenamento simples de preferências locais.
- **Flutter Secure Storage** (^8.0.0) — armazenamento seguro para tokens/segredos.
- **Sqflite** (^2.2.8+4) — banco de dados SQLite local para persistência estruturada.
- **Connectivity Plus** (^4.0.2) — detecção de conectividade de rede.
- **http** (^1.1.0) — cliente HTTP para chamadas à API.
- **Image Picker** (^1.0.4) — seleção de imagens da galeria ou câmera.
- **Path Provider** (^2.1.1) & path (^1.8.3) — resolver paths do sistema e utilitários de caminho.
- **Flutter SVG** (^2.0.9) — renderização de imagens SVG.
- **FL Chart** (^0.65.0) — gráficos e visualizações (charts).

- **Dev**: 
- **Flutter Test** (SDK) — testes unitários/widget;
- **Flutter Lints** (^3.0.0) — regras de lint; 
- **Flutter Launcher Icons** (^0.14.4) — geração de ícones nativos.

## 🚀 **Em Desenvolvimento**
1. **Integração Backend** - API REST
2. **Sistema de Autenticação com refresh token** - JWT
3. **Banco de dados local para uso offline** - SQLite

## 🚀 **Próximos Passos**

Próximas implementações:
1. **CI/CD** - GitHub Actions, Fastlane
2. **Notificações push** - Firebase Cloud Messaging
3. **Testes** - Unit, Widget, Integration

## 🤝 **Contribuição**

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 **Licença**

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 **Desenvolvido por**
Lumina Team
Sistema de Gestão de Projetos Acadêmicos - Fatec Votorantim
© 2025 Todos os direitos reservados
