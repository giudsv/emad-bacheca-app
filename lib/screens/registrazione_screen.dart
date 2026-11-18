import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';

/// Registrazione di una nuova azienda (R1).
/// Se va a buon fine, restituisce l'email usata per l'account.
class RegistrazioneScreen extends StatefulWidget {
  const RegistrazioneScreen({super.key});

  @override
  State<RegistrazioneScreen> createState() => _RegistrazioneScreenState();
}

class _RegistrazioneScreenState extends State<RegistrazioneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _conferma = TextEditingController();
  bool _inCorso = false;
  Map<String, String> _erroriServer = {};
  AutovalidateMode _autovalida = AutovalidateMode.disabled;

  @override
  void dispose() {
    for (final c in [_nome, _email, _password, _conferma]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _creaAccount() async {
    setState(() => _erroriServer = {});
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalida = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() => _inCorso = true);
    try {
      await SessioneScope.read(context).api.registrazione(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) Navigator.of(context).pop(_email.text.trim());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _inCorso = false;
        _erroriServer = e.stato == 409 ? {'email': e.messaggio} : e.campi;
      });
      _formKey.currentState!.validate();
      mostraMessaggio(context, e.messaggio, errore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registra la tua azienda')),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalida,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome dell\'azienda *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Il nome dell\'azienda è obbligatorio'
                  : _erroriServer['nome'],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                final e = v?.trim() ?? '';
                if (e.isEmpty) return 'L\'email è obbligatoria';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
                  return 'Inserisci un\'email valida';
                }
                return _erroriServer['email'];
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Password *',
                helperText: 'Almeno 6 caratteri',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'La password deve avere almeno 6 caratteri'
                  : _erroriServer['password'],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _conferma,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _creaAccount(),
              decoration: const InputDecoration(
                labelText: 'Conferma password *',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => v != _password.text
                  ? 'Le password non coincidono'
                  : null,
            ),
            const SizedBox(height: 24),
            PulsanteInvio(
              testo: 'Crea account',
              icona: Icons.how_to_reg,
              inCorso: _inCorso,
              onPressed: _creaAccount,
            ),
          ],
        ),
      ),
    );
  }
}
