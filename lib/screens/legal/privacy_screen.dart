import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'legal_section.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polityka prywatności')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Polityka prywatności SoleTrade',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Dbamy o Twoją prywatność i dyskrecję.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 20),
          LegalSection(
            title: '1. Jakie dane zbieramy',
            body:
                'Zbieramy dane podane podczas rejestracji (e-mail, nazwa '
                'użytkownika), dane profilu (zdjęcie, opis), treść wystawianych '
                'ofert oraz wiadomości wysyłane w ramach czatu z innymi '
                'użytkownikami.',
          ),
          LegalSection(
            title: '2. W jakim celu przetwarzamy dane',
            body:
                'Dane wykorzystujemy do świadczenia usług aplikacji: '
                'umożliwienia zakładania kont, publikowania ofert, kontaktu '
                'między użytkownikami oraz moderacji treści.',
          ),
          LegalSection(
            title: '3. Udostępnianie danych',
            body:
                'Nazwa użytkownika, ocena i treść ofert są widoczne publicznie '
                'w aplikacji. Dane kontaktowe (e-mail) nie są udostępniane '
                'innym użytkownikom bez Twojej zgody.',
          ),
          LegalSection(
            title: '4. Bezpieczeństwo',
            body:
                'Dane przechowywane są w bazie Supabase z zastosowaniem zasad '
                'kontroli dostępu ograniczających odczyt i zapis wyłącznie do '
                'uprawnionych użytkowników i moderatorów.',
          ),
          LegalSection(
            title: '5. Twoje prawa',
            body:
                'Masz prawo do wglądu, poprawiania i usunięcia swoich danych '
                'oraz konta w dowolnym momencie poprzez ustawienia profilu lub '
                'kontakt z moderatorem.',
          ),
          LegalSection(
            title: '6. Pliki cookies i przechowywanie lokalne',
            body:
                'Wersja webowa aplikacji może wykorzystywać lokalne '
                'przechowywanie danych w przeglądarce w celu utrzymania sesji '
                'zalogowanego użytkownika.',
          ),
          LegalSection(
            title: '7. Kontakt',
            body:
                'W sprawach dotyczących ochrony danych osobowych skontaktuj się '
                'z nami poprzez wiadomość w aplikacji.',
          ),
        ],
      ),
    );
  }
}
