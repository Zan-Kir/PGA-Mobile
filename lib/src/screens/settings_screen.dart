import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_provider.dart';
import '../services/theme_provider.dart';
import '../widgets/bottom_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoSaveEnabled = true;
  String _selectedLanguage = 'Português';
  double _fontSize = 16.0;
  String _appVersion = '...';

  final List<String> _languageOptions = [
    'Português',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _fontSize = (themeProvider.fontScale) * 16.0;
      });
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Notificações',
              icon: Icons.notifications,
              children: [
                SwitchListTile(
                  title: const Text('Ativar notificações'),
                  subtitle: const Text('Receber alertas sobre projetos'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'Aparência',
              icon: Icons.palette,
              children: [
                SwitchListTile(
                  title: const Text('Modo escuro'),
                  subtitle: const Text('Usar tema escuro'),
                  value: themeProvider.isDark,
                  onChanged: (value) async {
                    await themeProvider.setDark(value);
                  },
                ),
                ListTile(
                  title: const Text('Tamanho da fonte'),
                  subtitle: Text('${_fontSize.round()}px'),
                  trailing: SizedBox(
                    width: 200,
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => Slider(
                        value: _fontSize,
                        min: 12,
                        max: 24,
                        divisions: 12,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (value) async {
                          setState(() {
                            _fontSize = value;
                          });
                          final scale = (value / 16.0);
                          await themeProvider.setFontScale(scale);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'Sistema',
              icon: Icons.settings,
              children: [
                SwitchListTile(
                  title: const Text('Salvamento automático'),
                  subtitle: const Text('Salvar alterações automaticamente'),
                  value: _autoSaveEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoSaveEnabled = value;
                    });
                  },
                ),
                ListTile(
                  title: const Text('Idioma'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'Conta',
              icon: Icons.account_circle,
              children: [
                ListTile(
                  title: const Text('Perfil'),
                  subtitle: const Text('Editar informações pessoais'),
                  leading: const Icon(Icons.person),
                  onTap: () {
                  },
                ),
                ListTile(
                  title: const Text('Alterar senha'),
                  subtitle: const Text('Modificar senha de acesso'),
                  leading: const Icon(Icons.lock),
                  onTap: () {
                  },
                ),
                ListTile(
                  title: const Text('Sair'),
                  subtitle: const Text('Fazer logout da aplicação'),
                  leading: const Icon(Icons.logout),
                  onTap: () {
                    _showLogoutDialog();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'Sobre',
              icon: Icons.info,
              children: [
                ListTile(
                  title: const Text('Versão'),
                  subtitle: Text(_appVersion),
                  leading: const Icon(Icons.info_outline),
                ),
                ListTile(
                  title: const Text('Política de Privacidade'),
                  subtitle: const Text('Ler política de privacidade'),
                  leading: const Icon(Icons.privacy_tip),
                  onTap: () {
                  },
                ),
                ListTile(
                  title: const Text('Termos de Uso'),
                  subtitle: const Text('Ler termos de uso'),
                  leading: const Icon(Icons.description),
                  onTap: () {
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'Instituição',
              icon: Icons.school,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Fatec Votorantim',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sistema de Gestão de Projetos Acadêmicos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lumina Team \n© 2025 Todos os direitos reservados',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigation(
        currentRoute: '/settings',
        onNavigate: (route) {
          if (route == '/settings') return;
          context.go(route);
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.surface,
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Selecionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languageOptions.map((language) {
            final isSelected = _selectedLanguage == language;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedLanguage = language;
                });
                Navigator.of(dialogContext).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      language,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLogoutDialog() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da aplicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await auth.logout();
      } catch (_) {}
      if (!mounted) return;
      context.go('/');
    }
  }
}
