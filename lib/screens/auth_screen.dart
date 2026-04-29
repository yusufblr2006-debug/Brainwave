import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../widgets/neu_card.dart';
import '../widgets/pill_input.dart';
import '../widgets/grad_button.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;

  // Sign In Controllers
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();

  // Register Controllers
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  Future<void> _handleLogin() async {
    if (_loginEmail.text.isEmpty || _loginPass.text.isEmpty) return;
    if (mounted) setState(() => _loading = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.login(
        const Uuid().v4(), // Mock ID
        'John Doe', 
        _loginEmail.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_regName.text.isEmpty || _regEmail.text.isEmpty || _regPass.text.isEmpty) return;
    if (mounted) setState(() => _loading = true);
    try {
      final userId = const Uuid().v4();
      final data = {
        'user_id': userId,
        'name': _regName.text,
        'email': _regEmail.text,
        'phone': _regPhone.text,
        'password': _regPass.text,
      };
      await ApiService.registerUser(data);
      
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      await provider.login(userId, _regName.text, _regEmail.text, _regPhone.text);
      
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.balance, color: Colors.white, size: 48),
                        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 16),
                        Text('JudisAI', style: AppTextStyles.displayLarge.copyWith(color: Colors.white)),
                        Text('Your Private Legal Shield', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                        const SizedBox(height: 40),
                        
                        NeuCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              TabBar(
                                controller: _tabCtrl,
                                indicatorColor: AppColors.gradBlue,
                                labelColor: AppColors.gradBlue,
                                unselectedLabelColor: AppColors.textMid,
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Register'),
                                ],
                              ),
                              SizedBox(
                                height: 400,
                                child: TabBarView(
                                  controller: _tabCtrl,
                                  children: [
                                    _buildSignIn(),
                                    _buildRegister(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          PillInput(hintText: 'Email', controller: _loginEmail, prefixIcon: Icons.email_outlined),
          const SizedBox(height: 16),
          PillInput(hintText: 'Password', controller: _loginPass, prefixIcon: Icons.lock_outline, isPassword: true),
          const Spacer(),
          GradButton(text: 'Sign In', onPressed: _handleLogin, isLoading: _loading),
        ],
      ),
    );
  }

  Widget _buildRegister() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          PillInput(hintText: 'Full Name', controller: _regName, prefixIcon: Icons.person_outline),
          const SizedBox(height: 12),
          PillInput(hintText: 'Email', controller: _regEmail, prefixIcon: Icons.email_outlined),
          const SizedBox(height: 12),
          PillInput(hintText: 'Phone (optional)', controller: _regPhone, prefixIcon: Icons.phone_outlined),
          const SizedBox(height: 12),
          PillInput(hintText: 'Password', controller: _regPass, prefixIcon: Icons.lock_outline, isPassword: true),
          const Spacer(),
          GradButton(text: 'Create Account', onPressed: _handleRegister, isLoading: _loading),
        ],
      ),
    );
  }
}
