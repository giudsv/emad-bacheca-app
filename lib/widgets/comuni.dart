import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/sessione.dart';

final formatoData = DateFormat('d MMMM yyyy', 'it_IT');
final formatoDataOra = DateFormat('d MMM yyyy, HH:mm', 'it_IT');

void mostraMessaggio(BuildContext context, String testo,
    {bool errore = false}) {
  final tema = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(testo),
      backgroundColor: errore ? tema.error : null,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Schermata di errore con pulsante "Riprova".
class MessaggioErrore extends StatelessWidget {
  const MessaggioErrore({
    super.key,
    required this.messaggio,
    required this.onRiprova,
    this.mostraImpostazioni = true,
  });

  final String messaggio;
  final VoidCallback onRiprova;
  final bool mostraImpostazioni;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(messaggio, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRiprova,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
            if (mostraImpostazioni) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  if (await mostraImpostazioniServer(context)) onRiprova();
                },
                icon: const Icon(Icons.dns_outlined),
                label: const Text('Indirizzo del server'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Indicazione per elenchi vuoti.
class ElencoVuoto extends StatelessWidget {
  const ElencoVuoto({
    super.key,
    required this.icona,
    required this.titolo,
    required this.testo,
  });

  final IconData icona;
  final String titolo;
  final String testo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // ListView per permettere il "tira per aggiornare" anche se vuoto.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(icona, size: 72, color: tema.colorScheme.outline),
        const SizedBox(height: 16),
        Text(titolo,
            textAlign: TextAlign.center, style: tema.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(testo,
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Etichetta con icona (luogo, contratto, ecc.).
class Etichetta extends StatelessWidget {
  const Etichetta({super.key, required this.icona, required this.testo});

  final IconData icona;
  final String testo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icona, size: 16, color: tema.colorScheme.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(testo,
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}

/// Pulsante che mostra un indicatore di caricamento mentre [inCorso].
class PulsanteInvio extends StatelessWidget {
  const PulsanteInvio({
    super.key,
    required this.testo,
    required this.icona,
    required this.inCorso,
    required this.onPressed,
  });

  final String testo;
  final IconData icona;
  final bool inCorso;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: inCorso ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: inCorso
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icona),
      label: Text(testo),
    );
  }
}

/// Finestra per impostare l'indirizzo del server.
/// Restituisce `true` se l'indirizzo è stato modificato.
Future<bool> mostraImpostazioniServer(BuildContext context) async {
  final sessione = SessioneScope.read(context);
  final controller = TextEditingController(text: sessione.serverUrl);
  final risultato = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Indirizzo del server'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'http://192.168.1.10:8080',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Emulatore Android: ${Sessione.serverPredefinito}\n'
            'Smartphone: l\'indirizzo IP del computer nella stessa rete Wi-Fi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Salva'),
        ),
      ],
    ),
  );
  if (risultato == null || risultato.trim().isEmpty) return false;
  await sessione.impostaServer(risultato);
  return true;
}
