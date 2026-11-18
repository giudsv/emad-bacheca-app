# EMAD – Bacheca annunci di lavoro · App Flutter

App Flutter per una bacheca di annunci di lavoro:

- le **aziende** si registrano, pubblicano annunci e consultano le candidature ricevute;
- i **candidati**, senza registrarsi, consultano gli annunci e si candidano inviando i propri dati e il curriculum in PDF.

Il back-end, sviluppato anch'esso in Dart, è in una repository separata:
**[emad-bacheca-backend](https://github.com/giudsv/emad-bacheca-backend)**.

## Avvio

1. Avvia il back-end (vedi il suo README): `dart run bin/server.dart`.
2. Avvia l'app:
   ```bash
   flutter pub get
   flutter run
   ```
3. Se serve, imposta l'indirizzo del server con l'icona 🖧 in alto nella bacheca:
   - **emulatore Android**: `http://10.0.2.2:8080` (è il valore predefinito);
   - **smartphone**: `http://<IP del PC>:8080`, con telefono e PC sulla stessa rete Wi-Fi.

## Scenari

### S1 – Pubblicare un annuncio (R1, R2, R4)
**Aziende** → **Registrati** → nome dell'azienda, email e password → **Crea account**.
Si torna al login con l'email già compilata: inserisci la password e tocca **Accedi**, e si apre l'**Area riservata**.
Poi **Nuovo annuncio** → titolo, descrizione (e, se vuoi, sede e tipo di contratto) → **Pubblica annuncio**.
L'annuncio compare in bacheca: per vederla, usa *Vedi bacheca* nel messaggio di conferma o la freccia indietro.

### S2 – Candidarsi a un annuncio (R5, R6)
Senza login, la bacheca mostra gli annunci pubblicati.
Tocca un annuncio per aprirne il dettaglio → **Candidati** → nome, cognome, email → **Allega curriculum** (PDF) → **Invia candidatura**.
Compare il messaggio *Candidatura inviata!*.

### S3 – Consultare le candidature e uscire (R7, R3)
**Area riservata** → tocca un annuncio in *I miei annunci* per vedere le candidature ricevute.
Tocca una candidatura per vedere i dati del candidato → **Apri curriculum**: il PDF si apre direttamente nell'app.
Infine tocca l'icona **Logout** e conferma: si torna alla bacheca pubblica e l'area riservata richiede di nuovo il login.

## Struttura del codice

```
lib/
├── main.dart                          # Avvio, tema, stato globale
├── models/modelli.dart                # Azienda, Annuncio, Candidatura
├── services/
│   ├── api.dart                       # Client HTTP delle API REST
│   └── sessione.dart                  # Sessione azienda + indirizzo server (salvati sul dispositivo)
├── screens/
│   ├── bacheca_screen.dart            # Bacheca pubblica (R5)
│   ├── dettaglio_annuncio_screen.dart # Dettaglio annuncio (R5)
│   ├── candidatura_screen.dart        # Form di candidatura con upload del CV (R6)
│   ├── registrazione_screen.dart      # Registrazione azienda (R1)
│   ├── login_screen.dart              # Login azienda (R2)
│   ├── area_riservata_screen.dart     # I miei annunci + logout (R3, R7)
│   ├── nuovo_annuncio_screen.dart     # Pubblicazione annuncio (R4)
│   ├── candidature_screen.dart        # Candidature di un annuncio (R7)
│   ├── dettaglio_candidatura_screen.dart # Dati del candidato (R7)
│   └── curriculum_screen.dart         # Visualizzatore PDF del curriculum (R7)
└── widgets/comuni.dart                # Widget e funzioni condivise
```

Pacchetti usati: `http`, `shared_preferences`, `file_picker`, `pdfx`, `intl`.
