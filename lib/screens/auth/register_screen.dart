import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _obscure = true;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = AppUser(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _selectedRole,
      studentId: _selectedRole == UserRole.student
          ? (_studentIdCtrl.text.trim().isEmpty
              ? null
              : _studentIdCtrl.text.trim())
          : null,
      university: _universityCtrl.text.trim().isEmpty
          ? null
          : _universityCtrl.text.trim(),
    );

    final provider = context.read<AppProvider>();
    final success = await provider.register(user);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      switch (_selectedRole) {
        case UserRole.student:
          Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
        case UserRole.driver:
          Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard);
        case UserRole.admin:
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Registration failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                const SizedBox(height: 24),

                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Join UniRide today',
                  style: TextStyle(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 32),

                // Role selector
                const Text(
                  'I am a...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: UserRole.values
                      .where((r) => r != UserRole.admin)
                      .map((role) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 8),
                              child: _RoleCard(
                                role: role,
                                isSelected: _selectedRole == role,
                                onTap: () =>
                                    setState(() => _selectedRole = role),
                              ),
                            ),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 32),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppColors.textMuted),
                        ),
                        validator: (v) => v == null || v.length < 2
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppColors.textMuted),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6
                            ? 'At least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _universityCtrl,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'University (optional)',
                          prefixIcon: Icon(Icons.school_outlined,
                              color: AppColors.textMuted),
                        ),
                      ),
                      if (_selectedRole == UserRole.student) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _studentIdCtrl,
                          style: const TextStyle(
                              color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Student ID (optional)',
                            prefixIcon: Icon(Icons.badge_outlined,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                GradientButton(
                  label: 'Create Account',
                  onPressed: _isLoading ? null : _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style:
                            TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon => role == UserRole.student
      ? Icons.school_rounded
      : Icons.directions_bus_rounded;

  String get _label =>
      role == UserRole.student ? 'Student' : 'Driver';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.darkBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _icon,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              _label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
