/// Modelli dei dati scambiati con il server.
library;

class Azienda {
  const Azienda({required this.id, required this.nome, required this.email});

  factory Azienda.fromJson(Map<String, dynamic> j) => Azienda(
        id: j['id'] as String,
        nome: j['nome'] as String,
        email: j['email'] as String,
      );

  final String id;
  final String nome;
  final String email;

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'email': email};
}

class Annuncio {
  const Annuncio({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.dataPubblicazione,
    this.aziendaId,
    this.aziendaNome,
    this.luogo,
    this.tipoContratto,
    this.numeroCandidature = 0,
  });

  factory Annuncio.fromJson(Map<String, dynamic> j) => Annuncio(
        id: j['id'] as String,
        titolo: j['titolo'] as String,
        descrizione: j['descrizione'] as String,
        dataPubblicazione:
            DateTime.parse(j['dataPubblicazione'] as String).toLocal(),
        aziendaId: j['aziendaId'] as String?,
        aziendaNome: j['aziendaNome'] as String?,
        luogo: j['luogo'] as String?,
        tipoContratto: j['tipoContratto'] as String?,
        numeroCandidature: (j['numeroCandidature'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String titolo;
  final String descrizione;
  final DateTime dataPubblicazione;
  final String? aziendaId;
  final String? aziendaNome;
  final String? luogo;
  final String? tipoContratto;
  final int numeroCandidature;
}

class Candidatura {
  const Candidatura({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.nomeFileCv,
    required this.dimensioneCv,
    required this.dataInvio,
    this.telefono,
    this.messaggio,
  });

  factory Candidatura.fromJson(Map<String, dynamic> j) => Candidatura(
        id: j['id'] as String,
        nome: j['nome'] as String,
        cognome: j['cognome'] as String,
        email: j['email'] as String,
        telefono: j['telefono'] as String?,
        messaggio: j['messaggio'] as String?,
        nomeFileCv: j['nomeFileCv'] as String,
        dimensioneCv: (j['dimensioneCv'] as num).toInt(),
        dataInvio: DateTime.parse(j['dataInvio'] as String).toLocal(),
      );

  final String id;
  final String nome;
  final String cognome;
  final String email;
  final String? telefono;
  final String? messaggio;
  final String nomeFileCv;
  final int dimensioneCv;
  final DateTime dataInvio;

  String get nomeCompleto => '$nome $cognome';
}
