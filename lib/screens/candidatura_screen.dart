import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/modelli.dart';
import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';

/// Form di candidatura del candidato (R6). Restituisce `true` se inviata.
class CandidaturaScreen extends StatefulWidget {
  const CandidaturaScreen({super.key, required this.annuncio});

  final Annuncio annuncio;

  @override
  State<CandidaturaScreen> createState() => _CandidaturaScreenState();
}

class _CandidaturaScreenState extends State<CandidaturaScreen> {
  static const _dimensioneMassima = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _messaggio = TextEditingController();

  String? _nomeFile;
  Uint8List? _cv;
  String? _erroreCv;
  bool _invio = false;
  Map<String, String> _erroriServer = {};
  AutovalidateMode _autovalida = AutovalidateMode.disabled;

  @override
  void dispose() {
    for (final c in [_nome, _cognome, _email, _telefono, _messaggio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scegliCv() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null) return;
    final Uint8List byte;
    try {
      byte = await file.readAsBytes();
    } catch (_) {
      setState(() => _erroreCv = 'Impossibile leggere il file selezionato');
      return;
    }
    if (byte.length > _dimensioneMassima) {
      setState(() => _erroreCv = 'Il file supera la dimensione massima di 10 MB');
      return;
    }
    setState(() {
      _nomeFile = file.name;
      _cv = byte;
      _erroreCv = null;
    });
  }

  Future<void> _invia() async {
    setState(() => _erroriServer = {});
    final formOk = _formKey.currentState!.validate();
    final cvOk = _cv != null;
    if (!cvOk) setState(() => _erroreCv = 'Allega il tuo curriculum in PDF');
    if (!formOk || !cvOk) {
      setState(() => _autovalida = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _invio = true);
    try {
      await SessioneScope.read(context).api.inviaCandidatura(
            annuncioId: widget.annuncio.id,
            nome: _nome.text.trim(),
            cognome: _cognome.text.trim(),
            email: _email.text.trim(),
            telefono: _telefono.text.trim(),
            messaggio: _messaggio.text.trim(),
            nomeFileCv: _nomeFile!,
            cv: _cv!,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _invio = false;
        _erroriServer = e.campi;
        if (e.campi['cv'] != null) _erroreCv = e.campi['cv'];
      });
      mostraMessaggio(context, e.messaggio, errore: true);
    }
  }

  String? _obbligatorio(String? v, String campo, String messaggio) {
    if (v == null || v.trim().isEmpty) return messaggio;
    return _erroriServer[campo];
  }

  String? _validaEmail(String? v) {
    final e = v?.trim() ?? '';
    if (e.isEmpty) return 'L\'email è obbligatoria';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      return 'Inserisci un\'email valida';
    }
    return _erroriServer['email'];
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalida,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              color: tema.colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(widget.annuncio.titolo),
                subtitle: widget.annuncio.aziendaNome == null
                    ? null
                    : Text(widget.annuncio.aziendaNome!),
              ),
            ),
            const SizedBox(height: 20),
            Text('I tuoi dati', style: tema.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  _obbligatorio(v, 'nome', 'Il nome è obbligatorio'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cognome,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Cognome *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  _obbligatorio(v, 'cognome', 'Il cognome è obbligatorio'),
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
              validator: _validaEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Telefono (facoltativo)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messaggio,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Messaggio per l\'azienda (facoltativo)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Text('Curriculum *', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            _SelettoreCv(
              nomeFile: _nomeFile,
              dimensione: _cv?.length,
              errore: _erroreCv,
              onScegli: _invio ? null : _scegliCv,
            ),
            const SizedBox(height: 24),
            PulsanteInvio(
              testo: _invio ? 'Invio in corso…' : 'Invia candidatura',
              icona: Icons.send,
              inCorso: _invio,
              onPressed: _invia,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelettoreCv extends StatelessWidget {
  const _SelettoreCv({
    required this.nomeFile,
    required this.dimensione,
    required this.errore,
    required this.onScegli,
  });

  final String? nomeFile;
  final int? dimensione;
  final String? errore;
  final VoidCallback? onScegli;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colore =
        errore != null ? tema.colorScheme.error : tema.colorScheme.outline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: onScegli,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            side: BorderSide(color: colore),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: [
              Icon(
                nomeFile == null ? Icons.upload_file : Icons.picture_as_pdf,
                color: nomeFile == null
                    ? tema.colorScheme.primary
                    : Colors.red.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeFile ?? 'Allega curriculum (PDF, max 10 MB)',
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodyLarge,
                    ),
                    if (dimensione != null)
                      Text('${(dimensione! / 1024).toStringAsFixed(0)} KB · '
                          'tocca per cambiare',
                          style: tema.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (errore != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(errore!,
                style: tema.textTheme.bodySmall
                    ?.copyWith(color: tema.colorScheme.error)),
          ),
      ],
    );
  }
}
