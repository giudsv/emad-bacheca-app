import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';
import 'area_riservata_screen.dart';
import 'registrazione_screen.dart';

/// Login dell'azienda (R2).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _inCorso = false;
  bool _nascondiPassword = true;
  String? _errore;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _accedi() async {
    setState(() => _errore = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _inCorso = true);
    try {
      await SessioneScope.read(context)
          .login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const AreaRiservataScreen(),
      ));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _inCorso = false;
          _errore = e.messaggio;
        });
      }
    }
  }

  Future<void> _registrati() async {
    final email = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => const RegistrazioneScreen(),
    ));
    if (email != null && mounted) {
      _email.text = email;
      _password.clear();
      mostraMessaggio(context, 'Account creato! Ora accedi con le tue '
          'credenziali.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Accesso aziende')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.business_center,
                size: 64, color: tema.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Area riservata alle aziende',
                textAlign: TextAlign.center,
                style: tema.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Accedi per pubblicare annunci e consultare le candidature.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Inserisci l\'email'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _nascondiPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _accedi(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _nascondiPassword
                      ? 'Mostra password'
                      : 'Nascondi password',
                  icon: Icon(_nascondiPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _nascondiPassword = !_nascondiPassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Inserisci la password' : null,
            ),
            if (_errore != null) ...[
              const SizedBox(height: 12),
              Text(_errore!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tema.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            PulsanteInvio(
              testo: 'Accedi',
              icona: Icons.login,
              inCorso: _inCorso,
              onPressed: _accedi,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Non hai un account?'),
                TextButton(
                  onPressed: _inCorso ? null : _registrati,
                  child: const Text('Registrati'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
