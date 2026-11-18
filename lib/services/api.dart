import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/modelli.dart';

/// Errore restituito dal server o dovuto alla connessione.
class ApiException implements Exception {
  ApiException(this.messaggio, {this.stato, this.campi = const {}});

  final String messaggio;
  final int? stato;

  /// Errori di validazione per singolo campo (es. `{'email': '...'}`).
  final Map<String, String> campi;

  bool get nonAutenticato => stato == 401;

  @override
  String toString() => messaggio;
}

/// Client delle API REST del back-end.
class Api {
  Api(this.baseUrl, {this.token});

  final String baseUrl;
  final String? token;

  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

  // ---------------------------------------------------------------- Auth

  Future<void> registrazione({
    required String nome,
    required String email,
    required String password,
  }) =>
      _invia(() => http.post(_uri('/api/auth/registrazione'),
          headers: _headers,
          body: jsonEncode(
              {'nome': nome, 'email': email, 'password': password})));

  /// Restituisce il token di sessione e l'azienda autenticata.
  Future<(String, Azienda)> login(String email, String password) async {
    final j = await _invia(() => http.post(_uri('/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password})));
    return (
      j['token'] as String,
      Azienda.fromJson(j['azienda'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() =>
      _invia(() => http.post(_uri('/api/auth/logout'), headers: _headers));

  Future<Azienda> me() async {
    final j = await _invia(
        () => http.get(_uri('/api/auth/me'), headers: _headers));
    return Azienda.fromJson(j['azienda'] as Map<String, dynamic>);
  }

  // ------------------------------------------------------------- Annunci

  Future<List<Annuncio>> elencoAnnunci() async {
    final j = await _invia(() => http.get(_uri('/api/annunci')));
    return _annunci(j);
  }

  Future<Annuncio> dettaglioAnnuncio(String id) async {
    final j = await _invia(() => http.get(_uri('/api/annunci/$id')));
    return Annuncio.fromJson(j['annuncio'] as Map<String, dynamic>);
  }

  Future<Annuncio> pubblicaAnnuncio({
    required String titolo,
    required String descrizione,
    String? luogo,
    String? tipoContratto,
  }) async {
    final j = await _invia(() => http.post(_uri('/api/annunci'),
        headers: _headers,
        body: jsonEncode({
          'titolo': titolo,
          'descrizione': descrizione,
          'luogo': luogo,
          'tipoContratto': tipoContratto,
        })));
    return Annuncio.fromJson(j['annuncio'] as Map<String, dynamic>);
  }

  Future<List<Annuncio>> mieiAnnunci() async {
    final j = await _invia(
        () => http.get(_uri('/api/me/annunci'), headers: _headers));
    return _annunci(j);
  }

  // --------------------------------------------------------- Candidature

  Future<void> inviaCandidatura({
    required String annuncioId,
    required String nome,
    required String cognome,
    required String email,
    String? telefono,
    String? messaggio,
    required String nomeFileCv,
    required Uint8List cv,
  }) {
    final req = http.MultipartRequest(
        'POST', _uri('/api/annunci/$annuncioId/candidature'))
      ..fields.addAll({
        'nome': nome,
        'cognome': cognome,
        'email': email,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        if (messaggio != null && messaggio.isNotEmpty) 'messaggio': messaggio,
      })
      ..files.add(
          http.MultipartFile.fromBytes('cv', cv, filename: nomeFileCv));
    return _invia(() async => http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 60))));
  }

  Future<List<Candidatura>> candidatureAnnuncio(String annuncioId) async {
    final j = await _invia(() => http.get(
        _uri('/api/annunci/$annuncioId/candidature'),
        headers: _headers));
    return (j['candidature'] as List)
        .map((c) => Candidatura.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Uint8List> scaricaCv(String candidaturaId) async {
    final r = await _richiesta(() => http.get(
        _uri('/api/candidature/$candidaturaId/cv'),
        headers: _headers));
    return r.bodyBytes;
  }

  // ------------------------------------------------------------- Utilità

  List<Annuncio> _annunci(Map<String, dynamic> j) => (j['annunci'] as List)
      .map((a) => Annuncio.fromJson(a as Map<String, dynamic>))
      .toList();

  Future<Map<String, dynamic>> _invia(
      Future<http.Response> Function() chiamata) async {
    final r = await _richiesta(chiamata);
    if (r.body.isEmpty) return {};
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<http.Response> _richiesta(
      Future<http.Response> Function() chiamata) async {
    final http.Response r;
    try {
      r = await chiamata().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Il server non risponde. Controlla l\'indirizzo '
          'del server e che sia in esecuzione.');
    } on SocketException {
      throw ApiException('Impossibile contattare il server. Controlla '
          'l\'indirizzo del server e la connessione.');
    } on http.ClientException {
      throw ApiException('Impossibile contattare il server. Controlla '
          'l\'indirizzo del server e la connessione.');
    }

    if (r.statusCode >= 200 && r.statusCode < 300) return r;

    String messaggio = 'Errore del server (${r.statusCode})';
    Map<String, String> campi = const {};
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      messaggio = j['errore'] as String? ?? messaggio;
      campi = (j['campi'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const {};
    } catch (_) {
      // risposta non JSON: si usa il messaggio generico
    }
    throw ApiException(messaggio, stato: r.statusCode, campi: campi);
  }
}
