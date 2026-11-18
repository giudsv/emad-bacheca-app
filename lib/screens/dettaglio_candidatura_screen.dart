import 'package:flutter/material.dart';

import '../models/modelli.dart';
import '../widgets/comuni.dart';
import 'curriculum_screen.dart';

/// Dati di un candidato e accesso al curriculum allegato (R7).
class DettaglioCandidaturaScreen extends StatelessWidget {
  const DettaglioCandidaturaScreen({
    super.key,
    required this.candidatura,
    required this.annuncio,
  });

  final Candidatura candidatura;
  final Annuncio annuncio;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = candidatura;

    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: tema.colorScheme.primary,
              foregroundColor: tema.colorScheme.onPrimary,
              child: Text(
                '${c.nome.characters.first}${c.cognome.characters.first}'
                    .toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(c.nomeCompleto,
              textAlign: TextAlign.center,
              style: tema.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text('Candidatura per "${annuncio.titolo}"',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _Riga(icona: Icons.person_outline, etichetta: 'Nome',
                    valore: c.nome),
                _Riga(icona: Icons.person_outline, etichetta: 'Cognome',
                    valore: c.cognome),
                _Riga(icona: Icons.email_outlined, etichetta: 'Email',
                    valore: c.email),
                if (c.telefono != null)
                  _Riga(icona: Icons.phone_outlined, etichetta: 'Telefono',
                      valore: c.telefono!),
                _Riga(
                  icona: Icons.schedule,
                  etichetta: 'Inviata il',
                  valore: formatoDataOra.format(c.dataInvio),
                ),
              ],
            ),
          ),
          if (c.messaggio != null) ...[
            const SizedBox(height: 16),
            Text('Messaggio', style: tema.textTheme.titleMedium),
            const SizedBox(height: 6),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(c.messaggio!, style: tema.textTheme.bodyLarge),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Curriculum', style: tema.textTheme.titleMedium),
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf,
                  color: Colors.red.shade700, size: 36),
              title: Text(c.nomeFileCv, overflow: TextOverflow.ellipsis),
              subtitle:
                  Text('${(c.dimensioneCv / 1024).toStringAsFixed(0)} KB'),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CurriculumScreen(candidatura: c),
            )),
            icon: const Icon(Icons.description),
            label: const Text('Apri curriculum'),
          ),
        ],
      ),
    );
  }
}

class _Riga extends StatelessWidget {
  const _Riga({
    required this.icona,
    required this.etichetta,
    required this.valore,
  });

  final IconData icona;
  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icona),
      title: Text(etichetta),
      subtitle: SelectableText(valore,
          style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
