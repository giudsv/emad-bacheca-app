import 'package:flutter/material.dart';

import '../main.dart' show routeObserver;
import '../models/modelli.dart';
import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';
import 'area_riservata_screen.dart';
import 'dettaglio_annuncio_screen.dart';
import 'login_screen.dart';

/// Schermata pubblica: elenco degli annunci pubblicati (R5).
class BachecaScreen extends StatefulWidget {
  const BachecaScreen({super.key});

  @override
  State<BachecaScreen> createState() => _BachecaScreenState();
}

class _BachecaScreenState extends State<BachecaScreen> with RouteAware {
  List<Annuncio>? _annunci;
  String? _errore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carica());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// La bacheca torna visibile (es. dopo aver pubblicato un annuncio o
  /// dopo il logout): si ricarica l'elenco.
  @override
  void didPopNext() => _carica();

  Future<void> _carica() async {
    setState(() => _errore = null);
    try {
      final annunci = await SessioneScope.read(context).api.elencoAnnunci();
      if (mounted) setState(() => _annunci = annunci);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    }
  }

  Future<void> _apriAreaAziende() async {
    final sessione = SessioneScope.read(context);
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => sessione.autenticata
          ? const AreaRiservataScreen()
          : const LoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sessione = SessioneScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Lavoro'),
        actions: [
          IconButton(
            tooltip: 'Indirizzo del server',
            icon: const Icon(Icons.dns_outlined),
            onPressed: () async {
              if (await mostraImpostazioniServer(context)) _carica();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _apriAreaAziende,
              icon: Icon(sessione.autenticata
                  ? Icons.business_center
                  : Icons.login),
              label: Text(sessione.autenticata ? 'Area riservata' : 'Aziende'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _carica, child: _corpo()),
    );
  }

  Widget _corpo() {
    if (_errore != null) {
      return MessaggioErrore(messaggio: _errore!, onRiprova: _carica);
    }
    final annunci = _annunci;
    if (annunci == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (annunci.isEmpty) {
      return const ElencoVuoto(
        icona: Icons.work_off_outlined,
        titolo: 'Nessun annuncio pubblicato',
        testo: 'Torna più tardi: le aziende pubblicheranno qui le loro '
            'offerte di lavoro.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: annunci.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              annunci.length == 1
                  ? '1 offerta di lavoro'
                  : '${annunci.length} offerte di lavoro',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
        }
        final a = annunci[i - 1];
        return CardAnnuncio(
          annuncio: a,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DettaglioAnnuncioScreen(annuncioId: a.id),
          )),
        );
      },
    );
  }
}

class CardAnnuncio extends StatelessWidget {
  const CardAnnuncio({
    super.key,
    required this.annuncio,
    required this.onTap,
    this.mostraCandidature = false,
  });

  final Annuncio annuncio;
  final VoidCallback onTap;
  final bool mostraCandidature;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final a = annuncio;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(a.titolo,
                        style: tema.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  if (mostraCandidature)
                    Badge.count(
                      count: a.numeroCandidature,
                      isLabelVisible: true,
                      backgroundColor: a.numeroCandidature > 0
                          ? tema.colorScheme.primary
                          : tema.colorScheme.outline,
                    ),
                ],
              ),
              if (a.aziendaNome != null && !mostraCandidature) ...[
                const SizedBox(height: 2),
                Text(a.aziendaNome!,
                    style: tema.textTheme.bodyMedium
                        ?.copyWith(color: tema.colorScheme.primary)),
              ],
              const SizedBox(height: 8),
              Text(a.descrizione,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  if (a.luogo != null)
                    Etichetta(icona: Icons.place_outlined, testo: a.luogo!),
                  if (a.tipoContratto != null)
                    Etichetta(
                        icona: Icons.badge_outlined, testo: a.tipoContratto!),
                  Etichetta(
                      icona: Icons.calendar_today_outlined,
                      testo: formatoData.format(a.dataPubblicazione)),
                  if (mostraCandidature)
                    Etichetta(
                      icona: Icons.people_outline,
                      testo: a.numeroCandidature == 1
                          ? '1 candidatura'
                          : '${a.numeroCandidature} candidature',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
