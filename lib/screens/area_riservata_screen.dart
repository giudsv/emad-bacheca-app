import 'package:flutter/material.dart';

import '../models/modelli.dart';
import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';
import 'bacheca_screen.dart';
import 'candidature_screen.dart';
import 'nuovo_annuncio_screen.dart';

/// Area riservata dell'azienda autenticata: i propri annunci, la
/// pubblicazione di nuovi annunci (R4), le candidature (R7) e il logout (R3).
class AreaRiservataScreen extends StatefulWidget {
  const AreaRiservataScreen({super.key});

  @override
  State<AreaRiservataScreen> createState() => _AreaRiservataScreenState();
}

class _AreaRiservataScreenState extends State<AreaRiservataScreen> {
  List<Annuncio>? _annunci;
  String? _errore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carica());
  }

  Future<void> _carica() async {
    setState(() => _errore = null);
    final sessione = SessioneScope.read(context);
    try {
      final annunci = await sessione.api.mieiAnnunci();
      if (mounted) setState(() => _annunci = annunci);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.nonAutenticato) {
        // Sessione scaduta o invalidata: si torna alla parte pubblica.
        await sessione.chiudiSessioneLocale();
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
        mostraMessaggio(context, 'Sessione scaduta: effettua di nuovo il '
            'login.', errore: true);
        return;
      }
      setState(() => _errore = e.messaggio);
    }
  }

  Future<void> _nuovoAnnuncio() async {
    final pubblicato = await Navigator.of(context).push<Annuncio>(
      MaterialPageRoute(builder: (_) => const NuovoAnnuncioScreen()),
    );
    if (pubblicato == null || !mounted) return;
    await _carica();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Annuncio "${pubblicato.titolo}" pubblicato in '
            'bacheca'),
        action: SnackBarAction(
          label: 'VEDI BACHECA',
          onPressed: () =>
              Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ));
  }

  Future<void> _logout() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uscire dall\'account?'),
        content: const Text('Per tornare nell\'area riservata dovrai '
            'effettuare di nuovo il login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    await SessioneScope.read(context).logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    mostraMessaggio(context, 'Logout effettuato');
  }

  @override
  Widget build(BuildContext context) {
    final sessione = SessioneScope.of(context);
    final azienda = sessione.azienda;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area riservata'),
        backgroundColor: tema.colorScheme.primaryContainer,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: azienda == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: tema.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: tema.colorScheme.primary,
                        foregroundColor: tema.colorScheme.onPrimary,
                        child: Text(azienda.nome.characters.first
                            .toUpperCase()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(azienda.nome,
                                style: tema.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Text(azienda.email,
                                style: tema.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('I miei annunci',
                      style: tema.textTheme.titleMedium),
                ),
                Expanded(
                  child: RefreshIndicator(onRefresh: _carica, child: _elenco()),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuovoAnnuncio,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo annuncio'),
      ),
    );
  }

  Widget _elenco() {
    if (_errore != null) {
      return MessaggioErrore(messaggio: _errore!, onRiprova: _carica);
    }
    final annunci = _annunci;
    if (annunci == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (annunci.isEmpty) {
      return const ElencoVuoto(
        icona: Icons.post_add,
        titolo: 'Nessun annuncio',
        testo: 'Tocca "Nuovo annuncio" per pubblicare la tua prima offerta '
            'di lavoro.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
      itemCount: annunci.length,
      itemBuilder: (context, i) => CardAnnuncio(
        annuncio: annunci[i],
        mostraCandidature: true,
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CandidatureScreen(annuncio: annunci[i]),
          ));
          if (mounted) _carica();
        },
      ),
    );
  }
}
