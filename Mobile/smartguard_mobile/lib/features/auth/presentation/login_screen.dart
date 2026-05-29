import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  final _loginFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _didSetMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didSetMode) return;
      _didSetMode = true;
      ref.read(authControllerProvider.notifier).setMode(AuthMode.login);
    });
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: AppDimens.pagePadding.copyWith(
              bottom: AppDimens.spaceM + bottomInset,
            ),
            child: Column(
              children: [
                if (state.globalErrorMessage != null) ...[
                  _ErrorBanner(message: state.globalErrorMessage!),
                  const SizedBox(height: AppDimens.spaceM),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimens.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppDimens.spaceM),
                      Image.asset(
                        'assets/images/smartguard-landscape.png',
                        width: 200,
                      ),
                      const SizedBox(height: AppDimens.spaceM),
                      TextField(
                        controller: _loginController,
                        focusNode: _loginFocus,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: controller.setLogin,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        decoration: InputDecoration(
                          labelText: AppStrings.emailOrUsernameLabel,
                          errorText: _fieldErrorText(
                            state.fieldErrors[AuthField.login],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.spaceM),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        autofillHints: const [AutofillHints.password],
                        obscureText: !state.passwordVisible,
                        textInputAction: TextInputAction.done,
                        onChanged: controller.setPassword,
                        onSubmitted: (_) => controller.submit(),
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
                      const SizedBox(height: AppDimens.spaceL),
                      FilledButton(
                        onPressed: state.canSubmit && !state.isSubmitting
                            ? controller.submit
                            : null,
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(AppStrings.actionLogin),
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
                        onPressed: () => context.push(AppRoutes.register),
                        child: const Text(AppStrings.actionGoToRegister),
                      ),
                    ],
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
