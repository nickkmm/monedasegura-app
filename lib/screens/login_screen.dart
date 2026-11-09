import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_text_field.dart';
import '../widgets/sidebar.dart';

/// Sign-in screen: dark hero on the left (wide windows only) and the form.
///
/// [onSignIn] receives the typed credentials and returns a Spanish error
/// message, or null when the sign-in worked.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignIn});

  final String? Function(String email, String password) onSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    final error = widget.onSignIn(_email.text.trim(), _password.text);
    // On success the app replaces this screen, so only errors need a rebuild.
    if (error != null && mounted) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    if (wide) {
      return Scaffold(
        backgroundColor: MsColors.bgCanvas,
        body: Row(
          children: [
            const _Hero(),
            Expanded(child: _formArea(showBrand: false)),
          ],
        ),
      );
    }
    // Narrow windows keep the dark, decorated background behind the form.
    return Scaffold(
      backgroundColor: MsColors.bgInverse,
      body: Stack(
        children: [
          const Positioned.fill(child: _GuillocheBackground()),
          _formArea(showBrand: true, card: true),
        ],
      ),
    );
  }

  Widget _formArea({required bool showBrand, bool card = false}) {
    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBrand) ...[
            const Row(
              children: [
                BrandMark(),
                SizedBox(width: MsSpace.md),
                Text('MonedaSegura', style: MsText.heading),
              ],
            ),
            const SizedBox(height: MsSpace.xl),
          ],
          const Text('Iniciar sesión', style: MsText.title),
          const SizedBox(height: MsSpace.xl),
          MsTextField(
            label: 'Correo',
            controller: _email,
            hint: 'nombre@monedasegura.co',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: MsSpace.lg),
          MsTextField(
            label: 'Contraseña',
            controller: _password,
            hint: '••••••••••••',
            obscure: true,
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: MsSpace.xl),
          MsButton(
            label: 'Entrar',
            height: 44,
            fullWidth: true,
            onPressed: _canSubmit ? _submit : null,
          ),
          const SizedBox(height: MsSpace.lg),
          const Text(
            'Prototipo: usa cualquier contraseña con una cuenta '
            'de prueba, por ejemplo valentina.rios@monedasegura.co '
            '(administradora) o camilo.torres@monedasegura.co '
            '(analista).',
            style: MsText.caption,
          ),
        ],
      ),
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MsSpace.xl),
        child: card
            ? Container(
                padding: const EdgeInsets.all(MsSpace.xxl),
                decoration: BoxDecoration(
                  color: MsColors.bgCanvas,
                  borderRadius: BorderRadius.circular(MsRadius.lg),
                ),
                child: form,
              )
            : form,
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    const headline = TextStyle(
      fontFamily: MsText.family,
      fontSize: 44,
      height: 52 / 44,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.1,
      color: Colors.white,
    );
    return Container(
      width: 620,
      color: MsColors.bgInverse,
      child: Stack(
        children: [
          const Positioned.fill(child: _GuillocheBackground()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 56),
            child: _heroContent(headline),
          ),
        ],
      ),
    );
  }

  Widget _heroContent(TextStyle headline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const BrandMark(size: 32, iconSize: 20),
            const SizedBox(width: MsSpace.md),
            Text(
              'MonedaSegura',
              style: MsText.heading.copyWith(color: Colors.white),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detén el fraude', style: headline),
            Text('antes de que salga', style: headline),
            Text('el dinero.', style: headline),
            const SizedBox(height: MsSpace.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Revisa casos, ajusta reglas y sigue el modelo desde un '
                'solo lugar.',
                style: MsText.body.copyWith(color: const Color(0xB8FFFFFF)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dark background with the thin interlaced-ellipse decoration of the design.
class _GuillocheBackground extends StatelessWidget {
  const _GuillocheBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: MsColors.bgInverse,
      child: CustomPaint(painter: _GuillochePainter()),
    );
  }
}

class _GuillochePainter extends CustomPainter {
  const _GuillochePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.8, size.height * 0.85);
    final radius = math.min(size.width, size.height) * 0.45;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x14FFFFFF);
    const turns = 36;
    for (var i = 0; i < turns; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.pi * i / turns);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2,
          height: radius * 2 * 0.62,
        ),
        line,
      );
      canvas.restore();
    }
    for (final factor in const [1.0, 0.5, 0.2]) {
      canvas.drawCircle(center, radius * factor, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
