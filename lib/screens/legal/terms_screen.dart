import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'legal_section.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regulamin')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Regulamin serwisu SoleTrade',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Obowiązuje od dnia instalacji aplikacji.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 20),
          LegalSection(
            title: '1. Postanowienia ogólne',
            body:
                'SoleTrade to platforma umożliwiająca użytkownikom zamieszczanie '
                'ogłoszeń dotyczących sprzedaży używanych skarpetek oraz kontakt '
                'między kupującymi a sprzedającymi. Korzystanie z aplikacji '
                'oznacza akceptację niniejszego regulaminu.',
          ),
          LegalSection(
            title: '2. Konto użytkownika',
            body:
                'Do korzystania z pełnej funkcjonalności aplikacji wymagane jest '
                'założenie konta. Użytkownik zobowiązany jest do podania '
                'prawdziwych danych i ponosi odpowiedzialność za bezpieczeństwo '
                'swojego konta.',
          ),
          LegalSection(
            title: '3. Zasady wystawiania ofert',
            body:
                'Każda oferta przed publikacją podlega moderacji. Zabronione jest '
                'zamieszczanie treści niezgodnych z prawem, wprowadzających w '
                'błąd lub naruszających prawa osób trzecich. Moderator zastrzega '
                'sobie prawo do odrzucenia lub usunięcia oferty bez podania '
                'przyczyny.',
          ),
          LegalSection(
            title: '4. Transakcje',
            body:
                'SoleTrade pełni wyłącznie rolę pośrednika w kontakcie między '
                'użytkownikami i nie jest stroną transakcji. Warunki sprzedaży, '
                'płatności i dostawy ustalane są bezpośrednio między kupującym a '
                'sprzedającym.',
          ),
          LegalSection(
            title: '5. Odpowiedzialność',
            body:
                'SoleTrade nie ponosi odpowiedzialności za jakość, zgodność z '
                'opisem ani legalność przedmiotów oferowanych przez '
                'użytkowników. Wszelkie spory między użytkownikami rozstrzygane '
                'są bez udziału operatora platformy.',
          ),
          LegalSection(
            title: '6. Blokowanie kont',
            body:
                'Operator zastrzega sobie prawo do zablokowania konta '
                'użytkownika naruszającego regulamin, bez wcześniejszego '
                'powiadomienia.',
          ),
          LegalSection(
            title: '7. Zmiany regulaminu',
            body:
                'Regulamin może być aktualizowany. O istotnych zmianach '
                'użytkownicy zostaną poinformowani w aplikacji.',
          ),
        ],
      ),
    );
  }
}
