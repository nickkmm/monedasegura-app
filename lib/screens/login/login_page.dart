import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';
import 'guilloche_painter.dart';

/// Sign-in page (Figma `6:2`): the hero and the form, side by side.
///
/// [error] shows under the password field. [loading] disables submitting.
/// [onSubmit] is called from the button and from Enter in the password field.
class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  static const double _heroWidth = 620;
  static const double _formWidth = 380;
  static const double _minWidth = _heroWidth + _formWidth;

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: _heroWidth, child: _Hero()),
              Expanded(child: _form()),
            ],
          );
          if (constraints.maxWidth >= _minWidth) return content;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _minWidth,
              height: constraints.maxHeight,
              child: content,
            ),
          );
        },
      ),
    );
  }

  Widget _form() {
    return ColoredBox(
      color: AppColors.bgCanvas,
      child: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: _formWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xl,
              children: [
                const Text('Iniciar sesión', style: AppTextStyles.title),
                AppTextField(
                  label: 'Correo',
                  controller: emailController,
                  hintText: 'nombre@monedasegura.co',
                  keyboardType: TextInputType.emailAddress,
                ),
                AppTextField(
                  label: 'Contraseña',
                  controller: passwordController,
                  obscureText: true,
                  errorText: error,
                  onSubmitted: loading ? null : (_) => onSubmit(),
                ),
                AppButton(
                  label: 'Entrar',
                  expand: true,
                  height: 44,
                  onPressed: loading ? null : onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  static const double _paddingX = 64;
  static const double _paddingY = 56;
  static const double _markSize = 32;
  static const double _guillocheLeft = 120;
  static const double _guillocheTop = 340;
  static const double _guillocheSize = 760;
  static const double _copyMaxWidth = 420;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navBg,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              left: _guillocheLeft,
              top: _guillocheTop,
              width: _guillocheSize,
              height: _guillocheSize,
              child: CustomPaint(painter: GuillochePainter()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _paddingX,
                vertical: _paddingY,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: AppSpacing.sm,
                    children: [
                      Container(
                        width: _markSize,
                        height: _markSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          AppIcons.shield,
                          size: AppIcons.size,
                          color: AppColors.navBg,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'MonedaSegura',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading.copyWith(
                            color: AppColors.textInverse,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.lg,
                    children: [
                      Text(
                        'Detén el fraude\nantes de que salga\nel dinero.',
                        style: AppTextStyles.hero.copyWith(
                          color: AppColors.textInverse,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _copyMaxWidth,
                        ),
                        child: Text(
                          'Revisa casos, ajusta reglas y sigue el modelo '
                          'desde un solo lugar.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.onInverseMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
