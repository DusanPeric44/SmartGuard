import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_error.dart';
import '../application/auth_controller.dart';
import '../auth_constants.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final TextEditingController _emailController;
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;
  bool _passwordVisible = false;
  String? _emailError;
  String? _tokenError;
  String? _passwordError;
  String? _confirmError;
  String? _globalError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    String? emailError;
    String? tokenError;
    String? passwordError;
    String? confirmError;

    if (email.isEmpty) {
      emailError = AppStrings.validationRequired;
    } else if (!_emailRegExp.hasMatch(email)) {
      emailError = AppStrings.validationInvalidEmail;
    }

    if (token.isEmpty) {
      tokenError = AppStrings.validationRequired;
    }

    if (password.isEmpty) {
      passwordError = AppStrings.validationRequired;
    } else if (password.length < AuthConstraints.minPasswordLength ||
        password.length > AuthConstraints.maxPasswordLength) {
      passwordError = AppStrings.validationPasswordTooShort;
    }

    if (confirm != password) {
      confirmError = AppStrings.validationPasswordsDoNotMatch;
    }

    setState(() {
      _emailError = emailError;
      _tokenError = tokenError;
      _passwordError = passwordError;
      _confirmError = confirmError;
    });

    return emailError == null &&
        tokenError == null &&
        passwordError == null &&
        confirmError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() {
      _globalError = null;
      _submitting = true;
    });

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailController.text.trim(),
            token: _tokenController.text.trim(),
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.resetPasswordSuccess)),
      );
      router.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _globalError = e is ApiError ? e.message : AppStrings.errorUnknown;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.resetPasswordTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: AppDimens.pagePadding.copyWith(
              bottom: AppDimens.spaceM + bottomInset,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimens.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_globalError != null) ...[
                    Text(
                      _globalError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: AppDimens.spaceM),
                  ],
                  const Text(AppStrings.resetPasswordInstructions),
                  const SizedBox(height: AppDimens.spaceL),
                  TextField(
                    controller: _emailController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: AppStrings.emailLabel,
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextField(
                    controller: _tokenController,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: AppStrings.resetCodeLabel,
                      errorText: _tokenError,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextField(
                    controller: _passwordController,
                    enabled: !_submitting,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: AppStrings.newPasswordLabel,
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextField(
                    controller: _confirmController,
                    enabled: !_submitting,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: AppStrings.confirmNewPasswordLabel,
                      errorText: _confirmError,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceL),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.resetPasswordSubmit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
