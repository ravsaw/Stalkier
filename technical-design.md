# Cień Podróżnika - Projekt Techniczny

Ten dokument zawiera szczegółowe informacje techniczne dotyczące implementacji kluczowych systemów gry "Cień Podróżnika", skupiając się szczególnie na architekturze AI, optymalizacji wydajności oraz zaawansowanych mechanizmach rozgrywki.

## 1. Architektura Systemu "Dwóch Mózgów"

### 1.1 Podstawy Koncepcyjne

System "dwóch mózgów" to dwuwarstwowa architektura AI zaprojektowana do efektywnego zarządzania zachowaniami NPC w świecie gry "Cień Podróżnika". Zapewnia realistyczne i złożone zachowania NPC, jednocześnie optymalizując wykorzystanie zasobów systemu.

#### 1.1.1 Podział Warstw

1. **Mózg Strategiczny (Warstwa 2D)**
   - Symulacja globalna, niska częstotliwość aktualizacji (1-5 Hz)
   - Długoterminowe planowanie i podejmowanie decyzji
   - Zarządzanie celami wysokiego poziomu i priorytetami
   - Globalne mapowanie świata i relacje między frakcjami

2. **Mózg Taktyczny (Warstwa 3D)**
   - Symulacja lokalna, wysoka częstotliwość aktualizacji (co klatkę)
   - Implementacja decyzji strategicznych w świecie 3D
   - Reakcje na bezpośrednie zagrożenia i możliwości
   - Nawigacja lokalna i interakcje z otoczeniem

#### 1.1.2 Przepływ Informacji

```
[Mózg Strategiczny (2D)] <--> [System Buforowania/Synchronizacji] <--> [Mózg Taktyczny (3D)]
       |                                                                      |
       v                                                                      v
[Globalna Mapa Świata]                                                 [Lokalne Otoczenie]
[Długoterminowe Planowanie]                                           [Nawigacja 3D]
[Pamięć i Wiedza]                                                     [Percepcja Bezpośrednia]
```

### 1.2 Modułowa Architektura Mózgów

Każdy z mózgów jest podzielony na współpracujące moduły, zapewniając elastyczność i łatwiejszą rozbudowę systemu.

#### 1.2.1 Moduły Mózgu Strategicznego

1. **Moduł Pamięci**
   - Przechowywanie wiedzy o świecie i doświadczeniach
   - System kategoryzacji i ważności informacji
   - Mechanizm zapominania nieistotnych danych
   - Udostępnianie wiedzy grupom i frakcjom

2. **Moduł Planowania Ścieżek 2D**
   - System nawigacji oparty na warstwieNavigacji2D
   - Globalne planowanie tras między lokacjami
   - System oceny bezpieczeństwa i efektywności ścieżek
   - Świadomość terytoriów frakcyjnych i zagrożeń

3. **Moduł Zarządzania Celami**
   - Hierarchiczna struktura celów długo- i średnioterminowych
   - System priorytetyzacji i warunków sukcesu/porażki
   - Mechanizm adaptacji celów do zmieniających się warunków
   - Balansowanie konfliktowych celów i potrzeb

4. **Moduł Relacji**
   - Śledzenie relacji z innymi NPC i frakcjami
   - System reputacji i historii interakcji
   - Mechanizm zaufania i podejrzliwości
   - Pamięć społeczna i wpływy kulturowe

#### 1.2.2 Moduły Mózgu Taktycznego

1. **Moduł Percepcji**
   - Symulacja zmysłów (wzrok, słuch, "zmysł strefy")
   - Wykrywanie i ocena zagrożeń i możliwości
   - Mechanizm uwagi i filtrowania bodźców
   - Adaptacja do warunków środowiskowych

2. **Moduł Nawigacji 3D**
   - System nawigacji w przestrzeni trójwymiarowej
   - Unikanie przeszkód i zagrożeń
   - Adaptacja ruchu do terenu i ukształtowania
   - Taktyczne wykorzystanie osłon i ukryć

3. **Moduł Interakcji**
   - System interakcji z obiektami w świecie
   - Wykorzystywanie przedmiotów i ekwipunku
   - Interakcje społeczne z innymi NPC
   - Specjalne interakcje z anomaliami i artefaktami

4. **Moduł Taktyki Bojowej**
   - Ocena sytuacji bojowej i zagrożeń
   - Wybór broni i taktyki odpowiedniej do sytuacji
   - Koordynacja grupowa w walce
   - Decyzje o wycofaniu się lub kontynuowaniu walki



## 2. System Hierarchicznego LOD dla AI

### 2.1 Poziomy Szczegółowości

Hierarchiczny system LOD (Level of Detail) dla AI umożliwia skalowanie złożoności symulacji w zależności od odległości i znaczenia NPC. Pozwala to na symulowanie dużej liczby postaci przy zachowaniu wydajności.

#### 2.1.1 Definicja Poziomów LOD

1. **Full Detail (Poziom 0)**
   - Odległość: 0-50 jednostek od gracza
   - Pełna percepcja, nawigacja i interakcje
   - Zaawansowane zachowania bojowe i społeczne
   - Kompleksowa animacja i fizyka
   - Aktualizacja co klatkę

2. **Medium Detail (Poziom 1)**
   - Odległość: 50-200 jednostek
   - Uproszczona percepcja (mniejszy zasięg i dokładność)
   - Podstawowa nawigacja z unikaniem przeszkód
   - Uproszczone animacje i zachowania
   - Aktualizacja co 2-3 klatki

3. **Low Detail (Poziom 2)**
   - Odległość: 200-500 jednostek
   - Minimalna percepcja (tylko krytyczne zagrożenia)
   - Bardzo uproszczona nawigacja
   - Podstawowe animacje
   - Aktualizacja co 5-10 klatek

4. **Strategic Only (Poziom 3)**
   - Odległość: ponad 500 jednostek
   - Brak symulacji taktycznej, tylko strategiczna
   - Ruch po siatce 2D zamiast pełnej nawigacji 3D
   - Minimalne renderowanie lub brak
   - Aktualizacja co 30-60 klatek


## 3. System Śledzenia Historii NPC

### 3.1 Struktura Danych Historii

Każdy NPC ma swoją "historię życia" składającą się z istotnych wydarzeń. Wydarzenia są kategoryzowane według znaczenia, aby uniknąć nadmiernego gromadzenia mało istotnych informacji.

#### 3.1.1 Kategorie Znaczenia Wydarzeń

1. **Trywialne (0)** - codzienne czynności, ignorowane w zapisie
2. **Drobne (1)** - mniejsze interakcje, podstawowe znaleziska
3. **Znaczące (2)** - walki, cenne znaleziska, ważne lokacje
4. **Kluczowe (3)** - pierwsze zabójstwo, rzadkie artefakty
5. **Krytyczne (4)** - transformacje, śmierć, unikalne osiągnięcia


### 3.2 System Generowania Narracji

System generowania narracji tworzy spójne opisy życia NPC na podstawie zgromadzonych wydarzeń.


## 4. Architektura Wielowątkowa

### 4.1 Rozdzielenie Obliczeń

Implementacja wielowątkowa umożliwia efektywne wykorzystanie wielu rdzeni procesora i uniknięcie spadków wydajności podczas intensywnych obliczeń AI.

#### 4.1.1 Podział na Wątki/Taski

1. **Główny Wątek/Task**
   - Renderowanie i fizyka
   - Obsługa wejścia gracza
   - Mózg taktyczny (3D) dla najbliższych NPC
   - Główna pętla gry i zarządzanie sceną

2. **Wątek/Task AI Strategicznego**
   - "Mózg strategiczny" (2D) dla wszystkich NPC
   - Długoterminowe planowanie i symulacja
   - Zarządzanie frakcjami i dynamiką społeczną
   - Periodyczna aktualizacja (niższa częstotliwość)

3. **Wątek/Task Nawigacyjny**
   - Obliczanie i buforowanie ścieżek
   - Dynamiczne aktualizacje map nawigacyjnych
   - Optymalizacja nawigacji dla grup NPC

4. **Wątek/Task Symulacji Świata**
   - Symulacja ekonomii i handlu
   - Zmiany środowiskowe i anomalie
   - System dynamicznej pogody
   - Ekologia i migracje fauny


## Podsumowanie

Architektura techniczna "Cienia Podróżnika" została zaprojektowana z myślą o skalowalności, wydajności i elastyczności. Kluczowe elementy to:

1. **System Dual-Brain AI**: Innowacyjne rozwiązanie łączące strategiczne planowanie z taktyczną realizacją
2. **Hierarchiczny LOD**: Inteligentne zarządzanie zasobami dla tysięcy NPC
3. **Wielowątkowość**: Efektywne wykorzystanie nowoczesnych procesorów wielordzeniowych
4. **Rozbudowane Systemy Symulacji**: Od ekonomii po interakcje środowiskowe
5. **Narzędzia Debugowania**: Kompleksowe wsparcie dla deweloperów

Wszystkie te systemy współpracują ze sobą, tworząc emergentne zachowania i bogate doświadczenia gameplay'owe, które są charakterystyczne dla "Cienia Podróżnika".