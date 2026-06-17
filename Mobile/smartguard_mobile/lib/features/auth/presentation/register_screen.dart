import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _didSetMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didSetMode) return;
      _didSetMode = true;
      ref.read(authControllerProvider.notifier).setMode(AuthMode.register);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final justSucceeded =
          previous?.status != AuthStatus.success &&
          next.status == AuthStatus.success &&
          next.mode == AuthMode.register;
      if (justSucceeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.registerSuccess)),
        );
      }
    });

    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.registerTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: AppDimens.pagePadding.copyWith(
            bottom: AppDimens.spaceM + bottomInset,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimens.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.globalErrorMessage != null) ...[
                    _ErrorBanner(message: state.globalErrorMessage!),
                    const SizedBox(height: AppDimens.spaceM),
                  ],
                  TextField(
                    controller: _firstNameController,
                    focusNode: _firstNameFocus,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setFirstName,
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: AppStrings.firstNameLabel,
                      errorText: _fieldErrorText(
                        state.fieldErrors[AuthField.firstName],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextField(
                    controller: _lastNameController,
                    focusNode: _lastNameFocus,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setLastName,
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: AppStrings.lastNameLabel,
                      errorText: _fieldErrorText(
                        state.fieldErrors[AuthField.lastName],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setEmail,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: AppStrings.emailLabel,
                      errorText: _fieldErrorText(
                        state.fieldErrors[AuthField.email],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    autofillHints: const [AutofillHints.newPassword],
                    obscureText: !state.passwordVisible,
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setPassword,
                    onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: AppStrings.passwordLabel,
                      errorText: _fieldErrorText(
                        state.fieldErrors[AuthField.password],
                      ),
                      suffixIcon: IconButton(
                        onPressed: controller.togglePasswordVisible,
                        icon: Icon(
                          state.passwordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    autofillHints: const [AutofillHints.newPassword],
                    obscureText: !state.confirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onChanged: controller.setConfirmPassword,
                    onSubmitted: (_) => controller.submit(),
                    decoration: InputDecoration(
                      labelText: AppStrings.confirmPasswordLabel,
                      errorText: _fieldErrorText(
                        state.fieldErrors[AuthField.confirmPassword],
                      ),
                      suffixIcon: IconButton(
                        onPressed: controller.toggleConfirmPasswordVisible,
                        icon: Icon(
                          state.confirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceL),
                  FilledButton(
                    onPressed: state.canSubmit && !state.isSubmitting
                        ? controller.submit
                        : null,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.actionRegister),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  OutlinedButton(
                    onPressed: !state.isSubmitting
                        ? controller.signInWithGoogle
                        : null,
                    child: const Text(AppStrings.actionContinueWithGoogle),
                  ),
                  const SizedBox(height: AppDimens.spaceM),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text(AppStrings.actionGoToLogin),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: AppDimens.cardRadius,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

String? _fieldErrorText(AuthFieldError? error) {
  return switch (error) {
    null => null,
    AuthFieldError.requiredField => AppStrings.validationRequired,
    AuthFieldError.invalidEmail => AppStrings.validationInvalidEmail,
    AuthFieldError.passwordTooShort => AppStrings.validationPasswordTooShort,
    AuthFieldError.passwordTooLong => AppStrings.validationPasswordTooLong,
    AuthFieldError.passwordsDoNotMatch =>
      AppStrings.validationPasswordsDoNotMatch,
  };
}
