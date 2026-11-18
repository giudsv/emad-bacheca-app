import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../models/modelli.dart';
import '../services/api.dart';
import '../services/sessione.dart';
import '../widgets/comuni.dart';

/// Visualizzatore del curriculum PDF, scaricato dal server con il token
/// dell'azienda autenticata.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key, required this.candidatura});

  final Candidatura candidatura;

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  PdfControllerPinch? _controller;
  String? _errore;
  int _pagina = 1;
  int _totalePagine = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carica());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _carica() async {
    setState(() => _errore = null);
    try {
      final byte = await SessioneScope.read(context)
          .api
          .scaricaCv(widget.candidatura.id);
      if (!mounted) return;
      setState(() {
        _controller = PdfControllerPinch(document: PdfDocument.openData(byte));
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: Text('CV di ${widget.candidatura.nomeCompleto}'),
        bottom: _totalePagine > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Pagina $_pagina di $_totalePagine'),
                ),
              )
            : null,
      ),
      backgroundColor: Colors.grey.shade300,
      body: _errore != null
          ? MessaggioErrore(
              messaggio: _errore!,
              onRiprova: _carica,
              mostraImpostazioni: false,
            )
          : controller == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewPinch(
                  controller: controller,
                  onDocumentLoaded: (doc) =>
                      setState(() => _totalePagine = doc.pagesCount),
                  onPageChanged: (p) => setState(() => _pagina = p),
                  onDocumentError: (_) => setState(() =>
                      _errore = 'Impossibile aprire il curriculum: il file '
                          'PDF potrebbe essere danneggiato.'),
                  builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                    options: const DefaultBuilderOptions(),
                    documentLoaderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    pageLoaderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
    );
  }
}
