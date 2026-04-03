import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<FocusNode> _codeFocusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _codeControllers = List.generate(6, (index) => TextEditingController());

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _step = 1; // 1: email, 2: code, 3: nouveau mot de passe
  int _resendSeconds = 60;
  Timer? _resendTimer;
  bool _canResend = false;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendSeconds = 60;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_codeFocusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_codeFocusNodes[index - 1]);
    }

    if (_codeControllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _sendResetCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.forgotPassword(_emailController.text);

      if (result['success']) {
        setState(() => _step = 2);
        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code envoyé à ${_emailController.text}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    // Récupérer le code des 6 cases
    String code = '';
    for (var controller in _codeControllers) {
      code += controller.text;
    }

    if (code.length != 6) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.verifyResetCode(_emailController.text, code);

    if (result['success']) {
      setState(() {
        _step = 3;  // Passer à l'étape 3 (nouveau mot de passe)
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Code invalide'),
          backgroundColor: Colors.red,
        ),
      );

      // Vider les cases
      for (var controller in _codeControllers) {
        controller.clear();
      }
    }
  }

  Future<void> _resetPassword() async {
    // Vérifier que le mot de passe est valide
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 8 caractères'), backgroundColor: Colors.red),
      );
      return;
    }

    // Vérifier que les mots de passe correspondent
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: Colors.red),
      );
      return;
    }

    // Récupérer le code depuis les 6 cases
    String code = '';
    for (var controller in _codeControllers) {
      code += controller.text;
    }

    // Appeler l'API
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.resetPassword(
      email: _emailController.text,
      code: code,  // ← On utilise le code, pas le token
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mot de passe modifié avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.forgotPassword(_emailController.text);

    if (result['success']) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nouveau code envoyé'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => _step == 1 ? Navigator.pop(context) : setState(() => _step--),
        ),
        title: Text(
          _step == 1 ? localizations.forgotPassword :
          _step == 2 ? 'Vérification' : 'Nouveau mot de passe',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: authService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _step == 1 ? _buildEmailStep(localizations) :
        _step == 2 ? _buildCodeStep() :
        _buildPasswordStep(localizations),
      ),
    );
  }

  Widget _buildEmailStep(AppLocalizations localizations) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 30),
          Image.asset('assets/images/forgetPWD.png', height: 120),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(localizations.email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: localizations.emailHint,
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return localizations.emailRequired;
              if (!value.contains('@')) return localizations.invalidEmail;
              return null;
            },
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: localizations.sendCode,
            onPressed: _sendResetCode,
            isLoading: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mark_email_read, size: 50, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text('Vérification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('Code envoyé à', style: TextStyle(color: Colors.grey.shade600)),
        Text(_emailController.text, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => SizedBox(
            width: 45,
            height: 55,
            child: TextFormField(
              controller: _codeControllers[index],
              focusNode: _codeFocusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => _onCodeChanged(index, value),
            ),
          )),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Code non reçu ? '),
            GestureDetector(
              onTap: _canResend ? _resendCode : null,
              child: Text(
                _canResend ? 'Renvoyer' : 'Renvoyer dans $_resendSeconds s',
                style: TextStyle(
                  color: _canResend ? AppColors.primary : Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep(AppLocalizations localizations) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_outline, size: 50, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        Text('Nouveau mot de passe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),

        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: localizations.passwordHint,
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: localizations.confirm,
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 30),

        CustomButton(
          text: 'Confirmer',
          onPressed: _resetPassword,
          isLoading: false,
        ),
      ],
    );
  }
}