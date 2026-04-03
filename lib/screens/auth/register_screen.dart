// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'dart:async';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Formulaire principal
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _siretController = TextEditingController();
  final _companyController = TextEditingController();

  // Code de vérification
  final _codeController = TextEditingController();
  final List<FocusNode> _codeFocusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _codeControllers = List.generate(6, (index) => TextEditingController());

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String? _userType = 'commercant';

  Map<String, dynamic>? _fieldErrors;

  // État de vérification
  bool _showVerification = false;
  String? _currentEmail;
  int _resendSeconds = 60;
  Timer? _resendTimer;
  bool _canResend = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _siretController.dispose();
    _companyController.dispose();
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

    // Vérifier si tous les champs sont remplis
    if (_codeControllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _sendVerificationCode() async {
    final localizations = AppLocalizations.of(context)!;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.acceptTermsError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
        'user_type': _userType,
        'phone': _phoneController.text.trim(),
        'company_name': _companyController.text.trim(),
        'accept_terms': true,
      };

      // ✅ Ajouter siret UNIQUEMENT pour commerçant
      if (_userType == 'commercant') {
        userData['siret'] = _siretController.text.trim();
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.sendVerificationCode(userData);

      if (result['success'] && mounted) {
        setState(() {
          _showVerification = true;
          _currentEmail = _emailController.text;
        });

        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.codeSentTo} ${_emailController.text}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _fieldErrors = result['errors'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? localizations.error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    final localizations = AppLocalizations.of(context)!;
    final code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.verifyCodeAndRegister(_currentEmail!, code);

    if (result['success'] && mounted) {
      // ✅ Message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.registrationSuccess),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      // ✅ Rediriger vers la page de connexion au lieu du dashboard
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Revenir à la page de connexion
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false, // Supprime toutes les routes précédentes
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? localizations.invalidCode),
          backgroundColor: AppColors.error,
        ),
      );

      // Vider les champs de code
      for (var controller in _codeControllers) {
        controller.clear();
      }
      FocusScope.of(context).requestFocus(_codeFocusNodes[0]);
    }
  }

  Future<void> _resendCode() async {
    final localizations = AppLocalizations.of(context)!;

    if (!_canResend) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.resendCode(_currentEmail!);

    if (result['success']) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.newCodeSent),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? localizations.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _goBackToForm() {
    setState(() {
      _showVerification = false;
    });
    _resendTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final languageService = Provider.of<LanguageService>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _showVerification ? Icons.arrow_back : Icons.arrow_back,
            color: AppColors.textDark,
          ),
          onPressed: _showVerification ? _goBackToForm : () => Navigator.pop(context),
        ),
        title: Text(
          _showVerification ? localizations.verification : localizations.registerButton,
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _showVerification ? _buildVerificationSection(context, localizations) : _buildRegistrationForm(context, authService, languageService, localizations),
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context, AuthService authService, LanguageService languageService, AppLocalizations localizations) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 250,
              height: 150,
              child: Image.asset(
                'assets/icons/logo.png',
                width: 250,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'CD',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              localizations.registerButton,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 30),

          if (_fieldErrors != null && _fieldErrors!.containsKey('general'))
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fieldErrors!['general'][0],
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            localizations.company,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(localizations.merchant),
                  selected: _userType == 'commercant',
                  onSelected: (selected) {
                    setState(() {
                      _userType = 'commercant';
                    });
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _userType == 'commercant' ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: Text(localizations.supplier),
                  selected: _userType == 'fournisseur',
                  onSelected: (selected) {
                    setState(() {
                      _userType = 'fournisseur';
                    });
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _userType == 'fournisseur' ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildLabel(localizations.fullName),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: localizations.fullName,
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return localizations.fieldRequired;
              }
              return null;
            },
          ),
          if (_fieldErrors?.containsKey('name') ?? false)
            _buildErrorText(_fieldErrors!['name'][0]),
          const SizedBox(height: 16),

          _buildLabel(localizations.email),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: localizations.emailHint,
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return localizations.emailRequired;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return localizations.invalidEmail;
              }
              return null;
            },
          ),
          if (_fieldErrors?.containsKey('email') ?? false)
            _buildErrorText(_fieldErrors!['email'][0]),
          const SizedBox(height: 16),

          _buildLabel(localizations.phone),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: localizations.phone,
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return localizations.fieldRequired;
              }
              return null;
            },
          ),
          if (_fieldErrors?.containsKey('phone') ?? false)
            _buildErrorText(_fieldErrors!['phone'][0]),
          const SizedBox(height: 16),

          _buildLabel(localizations.companyName),
          const SizedBox(height: 8),
          TextFormField(
            controller: _companyController,
            textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: localizations.companyName,
              prefixIcon: Icon(Icons.business_outlined, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return localizations.fieldRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          if (_userType == 'commercant') ...[
            _buildLabel('${localizations.siret} *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _siretController,
              keyboardType: TextInputType.number,
              maxLength: 14,
              textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: localizations.siretHint,
                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
              validator: (value) {
                if (_userType == 'commercant' && (value == null || value.isEmpty)) {
                  return localizations.fieldRequired;
                }
                if (value != null && value.isNotEmpty && value.length != 14) {
                  return localizations.siretInvalid;
                }
                return null;
              },
            ),
            if (_fieldErrors?.containsKey('siret') ?? false)
              _buildErrorText(_fieldErrors!['siret'][0]),
            const SizedBox(height: 16),
          ],

          _buildLabel(localizations.password),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: localizations.passwordHint,
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return localizations.passwordRequired;
              }
              if (value.length < 8) {
                return localizations.passwordMinLength;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildLabel(localizations.confirm),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: localizations.confirm,
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return localizations.passwordRequired;
              }
              if (value != _passwordController.text) {
                return localizations.passwordsDoNotMatch;
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _acceptTerms = !_acceptTerms;
                    });
                  },
                  child: Text(
                    localizations.acceptTerms,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          CustomButton(
            text: localizations.continueText,
            onPressed: _sendVerificationCode,
            isLoading: authService.isLoading,
          ),

          const SizedBox(height: 20),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizations.alreadyHaveAccount,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    localizations.login,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVerificationSection(BuildContext context, AppLocalizations localizations) {
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
          child: Icon(
            Icons.mark_email_read,
            size: 50,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          localizations.checkYourEmail,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          localizations.codeSentDescription,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          _currentEmail ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 32),

        // Champs de code
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) => _onCodeChanged(index, value),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        CustomButton(
          text: localizations.verify,
          onPressed: _verifyCode,
          isLoading: Provider.of<AuthService>(context).isLoading,
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.codeNotReceived,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            GestureDetector(
              onTap: _canResend ? _resendCode : null,
              child: Text(
                _canResend
                    ? localizations.resendCode
                    : '${localizations.resendIn} $_resendSeconds ${localizations.seconds}',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12),
      child: Text(
        error,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),
    );
  }
}