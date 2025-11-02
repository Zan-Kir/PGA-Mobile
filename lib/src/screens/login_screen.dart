import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ...existing imports...
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final url = Uri.parse(AppConfig.loginEndpoint);
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': password}),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
        final token = body != null && body['access_token'] != null ? body['access_token'] : body?['token'];
        final refresh = body != null && body['refresh_token'] != null ? body['refresh_token'] : null;
        if (token != null) {
          // use AuthProvider to persist tokens and fetch user
          await auth.setToken(token as String, refresh: refresh as String?);
          try {
            final meRes = await http.get(Uri.parse(AppConfig.meEndpoint), headers: {'Authorization': 'Bearer $token'});
            if (meRes.statusCode == 200) {
              final userObj = jsonDecode(meRes.body) as Map<String, dynamic>;
              await auth.setToken(token, refresh: refresh, userData: userObj);
            }
          } catch (_) {}

          if (!mounted) return;
          setState(() => _isLoading = false);
          context.go('/dashboard');
          return;
        }
      }
      
      if (!mounted) return;
      final startOffline = await _showOfflinePrompt('Nome de usuário ou senha inválidos');
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      if (startOffline) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      final startOffline = await _showOfflinePrompt(
          'Não foi possível conectar ao servidor');
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      if (startOffline) {
        context.go('/dashboard');
      }
    }
  }

  Future<bool> _showOfflinePrompt(String reason) async {
    if (!mounted) return false;
    
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Iniciar modo offline?'),
            content: Text(
                '$reason. Deseja iniciar no modo offline?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Iniciar offline'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/votorantim_inaugura-1047641.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Logo e Título
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/fatec-votorantim1.png',
                          width: 200,
                          height: 70,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'PGA 2025',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Fatec Votorantim',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Card de Login
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text(
                              'Bem-vindo!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Faça login para acessar o sistema',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Campo Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira seu email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Campo Senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira sua senha';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Botão de Login
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Entrar'),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Link Esqueceu Senha
                            TextButton(
                              onPressed: () {},
                              child: const Text('Esqueceu sua senha?'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 90),

                    // Footer
                    const Column(
                      children: [
                        Text(
                          'Sistema de Gestão de Projetos Acadêmicos',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '© 2025 Fatec Votorantim',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
