import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/modelli.dart';
import 'api.dart';

/// Stato globale dell'app: indirizzo del server e sessione dell'azienda.
///
/// L'indirizzo del server e la sessione vengono salvati sul dispositivo,
/// così l'azienda resta autenticata anche dopo la chiusura dell'app
/// (finché non esegue il logout).
class Sessione extends ChangeNotifier {
  Sessione._(this._prefs);

  static const _chiaveServer = 'server_url';
  static const _chiaveToken = 'token';
  static const _chiaveAzienda = 'azienda';

  /// Indirizzo predefinito: il computer host visto dall'emulatore Android.
  static const serverPredefinito = 'http://10.0.2.2:8080';

  final SharedPreferences _prefs;

  String _serverUrl = serverPredefinito;
  String? _token;
  Azienda? _azienda;

  String get serverUrl => _serverUrl;
  Azienda? get azienda => _azienda;
  bool get autenticata => _token != null && _azienda != null;

  /// Client per le API pubbliche e per quelle dell'area riservata.
  Api get api => Api(_serverUrl, token: _token);

  static Future<Sessione> carica() async {
    final prefs = await SharedPreferences.getInstance();
    final s = Sessione._(prefs);
    s._serverUrl = prefs.getString(_chiaveServer) ?? serverPredefinito;
    s._token = prefs.getString(_chiaveToken);
    final aziendaJson = prefs.getString(_chiaveAzienda);
    if (aziendaJson != null) {
      s._azienda = Azienda.fromJson(
          jsonDecode(aziendaJson) as Map<String, dynamic>);
    }
    return s;
  }

  Future<void> impostaServer(String url) async {
    var u = url.trim();
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    _serverUrl = u;
    await _prefs.setString(_chiaveServer, u);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final (token, azienda) = await api.login(email, password);
    _token = token;
    _azienda = azienda;
    await _prefs.setString(_chiaveToken, token);
    await _prefs.setString(_chiaveAzienda, jsonEncode(azienda.toJson()));
    notifyListeners();
  }

  /// Invalida il token sul server (se raggiungibile) e lo cancella in locale.
  Future<void> logout() async {
    try {
      await api.logout();
    } on ApiException {
      // Anche se il server non risponde, la sessione locale va chiusa.
    }
    await chiudiSessioneLocale();
  }

  Future<void> chiudiSessioneLocale() async {
    _token = null;
    _azienda = null;
    await _prefs.remove(_chiaveToken);
    await _prefs.remove(_chiaveAzienda);
    notifyListeners();
  }
}

/// Rende la [Sessione] accessibile a tutto l'albero dei widget.
class SessioneScope extends InheritedNotifier<Sessione> {
  const SessioneScope({
    super.key,
    required Sessione sessione,
    required super.child,
  }) : super(notifier: sessione);

  static Sessione of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SessioneScope>()!
      .notifier!;

  /// Accesso senza registrare una dipendenza (per callback e azioni).
  static Sessione read(BuildContext context) => context
      .getInheritedWidgetOfExactType<SessioneScope>()!
      .notifier!;
}
