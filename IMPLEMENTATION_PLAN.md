# Plan implementacije projekta Vodič za uređaje

## Odluka o obimu za KT1

Za KT1 glavni pojam je `Review`, odnosno korisnička recenzija. To je najčistiji izbor zato što tema već definiše uloge, pet stanja, automatsko sakrivanje posle tri različite prijave i jasan posao urednika.

Upitnik, poređenje uređaja, vesti, video-uputstva, Instagram upit i javni veb ostaju u proizvodnom planu, ali ne treba da usporavaju KT1. Za prvu kontrolnu tačku dovoljno je da katalog postoji kao početni ekran, dok se kompletan tok i sva pravila grade oko recenzija.

## Arhitektura

```text
Mobilni ekran       Backoffice ekran
       \                 /
        \               /
         ReviewBloc u packages/blocs
                   |
         ReviewRepository port
                   |
       zaseban memorijski adapter u svakom klijentu
                   |
       model i pravila u packages/domain
```

Ekrani samo prikazuju stanje i šalju događaje. `ReviewBloc` vodi učitavanje i akcije. Domenski paket proverava unos, dozvoljene prelaze i broj različitih prijavljivača. Memorijski adapter simulira server za KT1. U KT2 se taj adapter menja HTTP adapterom bez izmene ekrana.

## Domenski model

Glavni tipovi:

- `ReviewId`, `DeviceId` i `UserId` su posebni tipovi, a ne obični stringovi.
- `Review` ima final polja i pravi novu instancu pri promeni.
- `ReviewTitle`, `ReviewBody` i `RatingValue` mogu da nastanu samo kroz proveru.
- `ReviewStatus` je sealed hijerarhija sa stanjima `ReviewPending`, `ReviewPublished`, `ReviewHidden`, `ReviewRejected` i `ReviewArchived`.
- `DomainError` vraća tip greške. Aplikacija bira tekst na srpskom.

Dozvoljeni prelazi:

| Iz stanja | U stanje |
|---|---|
| Na proveri | Objavljena ili odbijena |
| Objavljena | Privremeno sakrivena ili arhivirana |
| Privremeno sakrivena | Ponovo objavljena, odbijena ili arhivirana |
| Odbijena | Arhivirana |
| Arhivirana | Nema daljih prelaza |

Pravila za KT1:

- Naslov ima 5 do 80 grafema.
- Tekst recenzije ima 30 do 1000 grafema.
- Ocena je od 1 do 5.
- Autor ne može da prijavi svoju recenziju.
- Isti korisnik ne može da prijavi istu recenziju dvaput.
- Treća različita prijava privremeno sakriva objavljenu recenziju.
- Svaka promena stanja mora da prođe kroz tabelu dozvoljenih prelaza.

## Tačan redosled završavanja KT1

### 1. Okruženje i platforme

1. Instalirati Flutter 3.47+ i proveriti `flutter doctor` za Android, Windows i Chrome.
2. U korenu pokrenuti `.\tool\generate_platforms.ps1`.
3. Pokrenuti `flutter pub get` u korenu.
4. Commitovati generisane `android`, `windows`, `web`, `.metadata` i korenski `pubspec.lock`.

Kriterijum završetka: `flutter run` radi iz oba foldera aplikacija, a backoffice se pokreće i kao Windows aplikacija i u Chrome-u.

### 2. Domen

1. Pokrenuti postojeće testove za granice teksta, ocenu, prelaze i prijave.
2. Dodati još test za svaki novi poslovni zahtev pre menjanja UI-ja.
3. Proveriti da `packages/domain` nema `package:flutter`, `dart:io`, `dart:ffi` ni `dart:js_interop`.

Kriterijum završetka: `dart test packages/domain` prolazi i promena granice pravila menja ponašanje oba klijenta bez dupliranja uslova.

### 3. Zajedničko upravljanje stanjem

1. Dovršiti testove za `ReviewBloc`: učitavanje, prazan rezultat, greška, podaci i svaka akcija.
2. Proveriti da su događaji i stanja `Equatable`.
3. Zadržati ekran bez direktnog pozivanja repozitorijuma.
4. Dodati zaštitu od brzih uzastopnih zahteva ako se uvede pretraga sa mreže, na primer `restartable()`.

Kriterijum završetka: zamena memorijskog adaptera drugim adapterom ne traži izmenu ekrana.

### 4. Mobilna aplikacija

1. Potvrditi tok: katalog, lista recenzija, detalj recenzije, nova recenzija.
2. Zadržati rute kao URL adrese u `go_router` konfiguraciji.
3. Na formi proveravati `ReviewTitle`, `ReviewBody` i `RatingValue` iz domena i prikazivati poruke na srpskom.
4. Na jednoj objavljenoj recenziji unapred postaviti dve prijave, tako da demo korisnik trećom prijavom pokrene automatsko sakrivanje.
5. Zadržati dugme sa bubom koje namerno ruši sledeće učitavanje i ekran sa dugmetom `Pokušaj ponovo`.
6. Napraviti ikonicu od 1024 px, Android adaptivne slojeve i pokrenuti `flutter_launcher_icons`.
7. Dodati najmanje jedan widget test forme i jedan test navigacije na detalj.

Kriterijum završetka: na Android emulatoru mogu da se pokažu učitavanje, greška, prazan prikaz i podaci, zatim kreiranje recenzije i sakrivanje posle treće prijave.

### 5. Backoffice

1. Na širini od najmanje 900 px koristiti tabelu i bočni panel.
2. Ispod te granice koristiti listu i zadržati isti izabrani `ReviewId`.
3. Dovršiti pretragu i filter po svim stanjima.
4. Potvrditi akcije: odobri, odbij, ponovo objavi i arhiviraj.
5. Nepovratnu akciju arhiviranja ostaviti iza dijaloga za potvrdu.
6. Proveriti rad tastaturom: strelice menjaju izbor, `Ctrl+A` odobrava ili ponovo objavljuje, `Ctrl+R` otvara odbijanje, a fokus je vidljiv.
7. Dodati widget test koji sužava prozor i potvrđuje prelazak sa tabele na listu.

Kriterijum završetka: isti tok radi na Windows-u i u Chrome-u, bez miša i posle sužavanja prozora.

### 6. Vizuelni i završni prolaz

1. Uskladiti nazive uređaja, kategorije i tekstove sa odabranim obimom projekta.
2. Proveriti kontrast, povećan tekst, fokus i minimalnu veličinu cilja dodira od 48 px.
3. Pokrenuti `.\tool\verify.ps1`.
4. Pokrenuti obe aplikacije iz čistog klona prema README-u.
5. Pripremiti commit koji će biti na `main` grani u trenutku roka.

Kriterijum završetka: nema grešaka analizatora, svi testovi prolaze i svaki član tima može uživo da promeni jedno pravilo i pokaže gde se promena vidi.

## Podela posla u paru

Nemojte podeliti projekat tako da jedna osoba zna samo mobilni, a druga samo backoffice, jer oba studenta brane ceo sistem. Bolja podela je po vertikalnim tokovima:

- Prvi član vodi kreiranje i prikaz recenzije kroz domen, Bloc i mobilni ekran.
- Drugi član vodi moderaciju kroz prelaze, Bloc i backoffice.
- Testove domena, integraciju i pripremu odbrane radite zajedno, uz obavezne međusobne code review-e.

## Posle KT1

- KT2: Relic server, PostgreSQL, autentifikacija, uloge i serverska odluka o trećoj prijavi.
- KT3: lokalna baza, offline omiljeni uređaji i nacrt recenzije, red za sinhronizaciju i obrada konflikta.
- KT4: Jaspr javni veb, SEO rute za katalog i uređaje, testiranje i isporuka.

Važno: kada stigne server, klijent može odmah da proceni pravilo nad svojim podacima, ali server mora ponovo da ga proveri nad svežim podacima i donese konačnu odluku.
