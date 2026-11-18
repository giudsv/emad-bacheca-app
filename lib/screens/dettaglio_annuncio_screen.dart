import 'package:flutter/material.dart';

import '../models/modelli.dart';
import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';
import 'candidatura_screen.dart';

/// Dettaglio di un annuncio con il pulsante per candidarsi (R5, R6).
class DettaglioAnnuncioScreen extends StatefulWidget {
  const DettaglioAnnuncioScreen({super.key, required this.annuncioId});

  final String annuncioId;

  @override
  State<DettaglioAnnuncioScreen> createState() =>
      _DettaglioAnnuncioScreenState();
}

class _DettaglioAnnuncioScreenState extends State<DettaglioAnnuncioScreen> {
  Annuncio? _annuncio;
  String? _errore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carica());
  }

  Future<void> _carica() async {
    setState(() => _errore = null);
    try {
      final a = await SessioneScope.read(context)
          .api
          .dettaglioAnnuncio(widget.annuncioId);
      if (mounted) setState(() => _annuncio = a);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    }
  }

  Future<void> _candidati() async {
    final inviata = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => CandidaturaScreen(annuncio: _annuncio!),
    ));
    if (inviata == true && mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.check_circle,
              size: 48, color: Theme.of(context).colorScheme.primary),
          title: const Text('Candidatura inviata!'),
          content: Text(
            'La tua candidatura per "${_annuncio!.titolo}" è stata '
            'registrata. L\'azienda potrà consultare i tuoi dati e il tuo '
            'curriculum.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessione = SessioneScope.of(context);
    final a = _annuncio;

    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio annuncio')),
      body: _errore != null
          ? MessaggioErrore(messaggio: _errore!, onRiprova: _carica)
          : a == null
              ? const Center(child: CircularProgressIndicator())
              : _contenuto(a),
      bottomNavigationBar: a == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: sessione.autenticata
                    ? const Text(
                        'Sei autenticato come azienda: le aziende non possono '
                        'candidarsi agli annunci.',
                        textAlign: TextAlign.center,
                      )
                    : PulsanteInvio(
                        testo: 'Candidati',
                        icona: Icons.send,
                        inCorso: false,
                        onPressed: _candidati,
                      ),
              ),
            ),
    );
  }

  Widget _contenuto(Annuncio a) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(a.titolo,
            style: tema.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (a.aziendaNome != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.business, size: 18, color: tema.colorScheme.primary),
            const SizedBox(width: 6),
            Text(a.aziendaNome!,
                style: tema.textTheme.titleMedium
                    ?.copyWith(color: tema.colorScheme.primary)),
          ]),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (a.luogo != null)
              Etichetta(icona: Icons.place_outlined, testo: a.luogo!),
            if (a.tipoContratto != null)
              Etichetta(icona: Icons.badge_outlined, testo: a.tipoContratto!),
            Etichetta(
              icona: Icons.calendar_today_outlined,
              testo: 'Pubblicato il ${formatoData.format(a.dataPubblicazione)}',
            ),
          ],
        ),
        const Divider(height: 32),
        Text('Descrizione', style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(a.descrizione,
            style: tema.textTheme.bodyLarge?.copyWith(height: 1.5)),
      ],
    );
  }
}
