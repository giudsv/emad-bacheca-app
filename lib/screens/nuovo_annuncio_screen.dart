import 'package:flutter/material.dart';

import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';

/// Pubblicazione di un nuovo annuncio (R4).
/// Restituisce l'annuncio pubblicato, o `null` se l'utente rinuncia.
class NuovoAnnuncioScreen extends StatefulWidget {
  const NuovoAnnuncioScreen({super.key});

  @override
  State<NuovoAnnuncioScreen> createState() => _NuovoAnnuncioScreenState();
}

class _NuovoAnnuncioScreenState extends State<NuovoAnnuncioScreen> {
  static const _tipiContratto = [
    'Tempo indeterminato',
    'Tempo determinato',
    'Stage / Tirocinio',
    'Apprendistato',
    'Part-time',
    'Freelance',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titolo = TextEditingController();
  final _descrizione = TextEditingController();
  final _luogo = TextEditingController();
  String? _tipoContratto;
  bool _inCorso = false;
  AutovalidateMode _autovalida = AutovalidateMode.disabled;

  @override
  void dispose() {
    _titolo.dispose();
    _descrizione.dispose();
    _luogo.dispose();
    super.dispose();
  }

  Future<void> _pubblica() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalida = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() => _inCorso = true);
    try {
      final annuncio = await SessioneScope.read(context).api.pubblicaAnnuncio(
            titolo: _titolo.text.trim(),
            descrizione: _descrizione.text.trim(),
            luogo: _luogo.text.trim(),
            tipoContratto: _tipoContratto,
          );
      if (mounted) Navigator.of(context).pop(annuncio);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _inCorso = false);
      mostraMessaggio(context, e.messaggio, errore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo annuncio')),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalida,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titolo,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                hintText: 'Es. Sviluppatore Flutter junior',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Il titolo è obbligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descrizione,
              minLines: 5,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrizione *',
                hintText: 'Mansioni, requisiti, cosa offrite…',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'La descrizione è obbligatoria'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _luogo,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Sede di lavoro (facoltativo)',
                hintText: 'Es. Salerno, da remoto…',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipoContratto,
              decoration: const InputDecoration(
                labelText: 'Tipo di contratto (facoltativo)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                for (final t in _tipiContratto)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _tipoContratto = v),
            ),
            const SizedBox(height: 24),
            PulsanteInvio(
              testo: 'Pubblica annuncio',
              icona: Icons.campaign,
              inCorso: _inCorso,
              onPressed: _pubblica,
            ),
          ],
        ),
      ),
    );
  }
}
