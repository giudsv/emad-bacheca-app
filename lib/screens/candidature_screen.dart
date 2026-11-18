import 'package:flutter/material.dart';

import '../models/modelli.dart';
import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';
import 'dettaglio_candidatura_screen.dart';

/// Candidature ricevute per un annuncio dell'azienda (R7).
class CandidatureScreen extends StatefulWidget {
  const CandidatureScreen({super.key, required this.annuncio});

  final Annuncio annuncio;

  @override
  State<CandidatureScreen> createState() => _CandidatureScreenState();
}

class _CandidatureScreenState extends State<CandidatureScreen> {
  List<Candidatura>? _candidature;
  String? _errore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carica());
  }

  Future<void> _carica() async {
    setState(() => _errore = null);
    try {
      final c = await SessioneScope.read(context)
          .api
          .candidatureAnnuncio(widget.annuncio.id);
      if (mounted) setState(() => _candidature = c);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidature ricevute')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: tema.colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: ListTile(
              leading: const Icon(Icons.work_outline),
              title: Text(widget.annuncio.titolo,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: _candidature == null
                  ? null
                  : Text(_candidature!.length == 1
                      ? '1 candidatura'
                      : '${_candidature!.length} candidature'),
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _carica, child: _elenco()),
          ),
        ],
      ),
    );
  }

  Widget _elenco() {
    if (_errore != null) {
      return MessaggioErrore(messaggio: _errore!, onRiprova: _carica);
    }
    final candidature = _candidature;
    if (candidature == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (candidature.isEmpty) {
      return const ElencoVuoto(
        icona: Icons.inbox_outlined,
        titolo: 'Nessuna candidatura',
        testo: 'Non sono ancora arrivate candidature per questo annuncio.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: candidature.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final c = candidature[i];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${c.nome.characters.first}${c.cognome.characters.first}'
                .toUpperCase()),
          ),
          title: Text(c.nomeCompleto),
          subtitle: Text('${c.email}\n'
              'Inviata il ${formatoDataOra.format(c.dataInvio)}'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DettaglioCandidaturaScreen(
              candidatura: c,
              annuncio: widget.annuncio,
            ),
          )),
        );
      },
    );
  }
}
