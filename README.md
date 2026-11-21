# Vodič za uređaje

Vodič za uređaje je multiplatformska informativna aplikacija za Dyson uređaje. Korisnici mogu da pregledaju katalog, popune upitnik i dobiju personalizovane preporuke, uporede modele, pročitaju vesti i pogledaju video-uputstva za korišćenje i održavanje. Aplikacija ne obrađuje kupovinu i plaćanje; zainteresovani korisnici mogu da pošalju upit za cenu putem Instagrama.

**Trenutni obim KT2:** implementirani su lokalni katalog uređaja, recenzije sa serverskim upisom i moderacijom, korisničke uloge i trajne sesije na Androidu, Windowsu i vebu. Opis teme uključuje i planirane naredne funkcionalnosti: upitnik, preporuke, poređenja, vesti, video-uputstva, omiljene uređaje, trajne offline nacrte i sinhronizaciju, uređivanje kataloga i javni Jaspr veb.

## Tim

| Ime i prezime | Broj indeksa | Grupa | GitHub nalog |
|---|---|---|---|
| Miloš Milutinović | SI 108/2024 | 412 | [milos10824](https://github.com/milos10824) |
| Milisav Radovanović | SI 76/24 | 412 | [Milisasv](https://github.com/Milisasv) |

## Zahtevi za temu

1. Uloge

Sistem ima uloge posetioca, registrovanog korisnika i urednika/administratora. Posetioci pregledaju javni sadržaj, registrovani korisnici mogu da čuvaju omiljene uređaje, šalju recenzije i prijavljuju sadržaj, dok urednici i administratori uređuju katalog i objave i moderiraju recenzije.

2. Stanja

Korisnička recenzija prolazi kroz stanja: na proveri, objavljena, privremeno sakrivena i odbijena ili arhivirana. Urednik odobrava ili odbija recenzije na proveri, a objavljena recenzija može privremeno da se sakrije nakon većeg broja prijava.

3. Pravila

Pri unosu recenzije važe pravila iz zajedničkog paketa `domain`:

- Naslov mora imati od 5 do 80 grafema (vidljivih znakova).
- Tekst recenzije mora imati od 30 do 1000 grafema.
- Ocena mora biti ceo broj od 1 do 5.

Mobilna forma poziva ove domenske provere pri unosu i prikazuje poruke na srpskom.

Server automatski privremeno sakriva objavljenu recenziju kada je prijave najmanje tri različita registrovana korisnika. Server proverava da prijave potiču od različitih korisnika i menja stanje recenzije, nakon čega urednik odlučuje da li će je ponovo objaviti ili odbiti.

U KT2 server pokreće isto domensko pravilo nad svežim podacima iz baze.

4. Rad bez mreže

Korisnik u mobilnoj aplikaciji može bez internet veze da sačuva uređaj među omiljene ili da napravi nacrt recenzije. Izmene se čuvaju lokalno i sinhronizuju sa serverom kada veza postane dostupna.

5. Posao za osoblje

Urednici koriste backoffice na većem ekranu za rad sa većim brojem uređaja, recenzija, vesti i video-uputstava. Mogu da pretražuju i filtriraju zapise, ažuriraju katalog i obrađuju prijave i recenzije.

6. Javni sadržaj

Katalog, stranice uređaja, poređenja, vodiči, video-uputstva i objavljene vesti dostupni su bez prijave na javnom vebu. Sadržaj je namenjen i indeksiranju u pretraživačima kako bi korisnici mogli da pronađu informacije i pre instaliranja aplikacije.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
|---|---|---|---|
| Mobilna aplikacija | Posetioci i registrovani korisnici | Flutter | Android |
| Backoffice | Urednici i administratori | Flutter | Windows, veb |
| Javni veb | Svi posetioci | Jaspr | Pregledač |
| Server | Mobilna aplikacija, backoffice i javni veb | Relic, PostgreSQL | Linux |
| Domenski paket | Svi delovi sistema | Dart | Sve platforme |

## Razvoj

Repozitorijum je postavljen kao Dart pub workspace:

```text
apps/
  mobile/       Flutter aplikacija za korisnike
  backoffice/   Flutter aplikacija za urednike, za Windows i veb
  server/       Relic API i PostgreSQL šema
packages/
  domain/       model recenzije, stanja, pravila i port repozitorijuma
  blocs/        zajednički ReviewBloc, događaji i stanja ekrana
  api_contract/ tipovi HTTP zahteva, odgovora i grešaka
  api_mapping/  prevod između ugovora i domena
  api_client/   zajednička HTTP implementacija
  client_ui/    prijava i čuvanje sesije
tool/
  generate_platforms.ps1
  verify.ps1
```

U KT2 oba Flutter klijenta rade nad istim Relic serverom i PostgreSQL bazom. Mobilna aplikacija prikazuje objavljene recenzije i sopstvene zapise prijavljenog korisnika. Backoffice prikazuje sve statuse i akcije moderacije. Katalog u mobilnoj aplikaciji je lokalni prikaz uređaja.

`packages/api_contract` definiše JSON zahteve, odgovore i greške. `packages/api_mapping` prevodi između ugovora i domena. `packages/api_client` sadrži isti HTTP klijent za Android, Windows i Chrome. `packages/client_ui` obezbeđuje ekrane za prijavu i port za čuvanje sesije.

### Pokretanje KT2 iz čistog klona

Potrebni su Flutter 3.47 ili noviji sa Dart 3.13 ili novijim, pokrenut Docker Desktop u Linux režimu i Android emulator. U Android Studio SDK Manageru instalirati Android SDK Platform 36 (i viši ako ga koristi Flutter), NDK 30.0.16248370 i CMake 4.1.2. Gradle koristi JDK 17 ili noviji, kao što je JDK koji dolazi sa Android Studijom. Za Windows backoffice su potrebne Visual Studio alatke za razvoj desktop aplikacija u C++ i C++ ATL. Flutter na Windowsu koristi simboličke linkove za plugine. Ako prikaže poruku o njima, uključiti Developer Mode u Windows Settings.

U korenu repozitorijuma pokrenuti:

```powershell
Copy-Item .env.example .env
docker compose up -d --build
flutter pub get
```

Server sluša na `localhost:8080`. PostgreSQL priprema šemu i početne podatke kada se kreira novi volumen. Pri ponovnom podizanju koristi isti volumen. Ako server još kreće, možeš da proveriš sa `docker compose ps` i `Invoke-RestMethod http://localhost:8080/health`.

Svaku aplikaciju pokrenuti u zasebnom terminalu. Komande ispod kreću iz korena repozitorijuma.

```powershell
# Android (emulator mora biti pokrenut)
Set-Location apps\mobile
flutter devices
flutter run -d emulator-5554
```

```powershell
# Windows backoffice
Set-Location apps\backoffice
flutter run -d windows
```

```powershell
# Backoffice u Chrome-u, na adresi koju server dozvoljava
Set-Location apps\backoffice
flutter run -d chrome --web-hostname localhost --web-port 8081
```

ID u komandi za Android prilagoditi rezultatu `flutter devices`. Emulator pristupa lokalnom API-ju preko `http://10.0.2.2:8080`, a Windows i Chrome preko `http://localhost:8080`. Za drugačiju adresu može se proslediti `--dart-define=API_BASE_URL=...`. U Android debug buildu običan HTTP je podešen za adresu emulatora `10.0.2.2`. Za udaljeni API koristiti HTTPS. Chrome treba pokrenuti na `localhost` i portu iz `.env`, jer server dozvoljava taj origin za zahteve sa sesijskim kolačićem.

| Demo uloga | E-adresa | Lozinka |
|---|---|---|
| Urednik | `editor@example.test` | `EditorDemo123!` |
| Mobilni korisnici | `mobile1@example.test` do `mobile5@example.test` | `MobileDemo123!` |

Ovi nalozi služe lokalnoj demonstraciji. Lozinke su u bazi kao PBKDF2 heš. Android i Windows čuvaju token u bezbednom skladištu platforme, a Chrome koristi trajni `HttpOnly` kolačić. Trajanje sesije podešava `SESSION_TTL_SECONDS` u `.env`. Posle promene pokrenuti `docker compose up -d --force-recreate server` i ponovo se prijaviti za demonstraciju isteka.

Pri odjavi server poništava sesiju, a klijent uklanja sačuvanu prijavu. Ako serverska odjava ne uspe, Android i Windows mogu da obrišu lokalni token i prikažu da serverski opoziv nije potvrđen. Ako ne uspe ni lokalno brisanje, aplikacija prikazuje neuspeh i omogućava novi pokušaj. Web odjava zahteva odgovor servera koji briše `HttpOnly` kolačić; bez njega prijava ostaje aktivna uz poruku o neuspehu.

### Odluke iz vežbi V5 i V6

Relic ruter povezuje metode i putanje sa obradom zahteva, a zajednički middleware rešava CORS i pretvara greške u HTTP odgovore. API šalje vremena u UTC formatu ISO 8601 i statuse kao imenovane vrednosti. Lista podržava `limit`, `offset`, `status` i `query`. Klijent učitava stranice redom, pa postojeća pretraga i filter backoffice-a rade nad učitanim zapisima.

PostgreSQL transakcija obuhvata proveru i ceo upis promene recenzije. Zaključavanje reda važi između serverskih poziva i kada dolaze sa različitih klijenata. Zato smo ga izabrali umesto zaključavanja u memoriji serverskog procesa. Izabrali smo sesije u bazi jer odjava odmah poništava token. Osvežavanje pokreće novi HTTP zahtev i učitava promene drugih klijenata.

### Demonstracija KT2

1. Mobilni korisnik pošalje recenziju i vidi je pod statusom „Na proveri“. Urednik klikne „Osveži“ u backoffice-u i odobri recenziju. Mobilni korisnik ponovo osveži listu i vidi „Objavljena“.
2. `mobile4` može da izmeni svoju početnu recenziju `review-2` dok je na proveri. Provera na serveru odbija isti zahtev korisnika `mobile5`. Urednik može da odobri i odbije recenziju, a mobilni korisnik nema ta prava.
3. Početna `review-1` već ima dve prijave. Korisnici `mobile4` i `mobile5` mogu da se takmiče za treću prijavu. Server pod zaključavanjem reda proverava status i upisuje prijavu. Za ponovljivu proveru sa novom recenzijom služi komanda `dart run apps/server/tool/smoke.dart` iz korena.
4. Za vidljivo učitavanje dodati `--dart-define=KT2_DEMO_DELAY_MS=1500` komandi `flutter run`. Prazan režim `--dart-define=KT2_DEMO_EMPTY=true` učitava rezultat pretrage bez pogodaka sa servera. Za grešku zaustaviti server pomoću `docker compose stop server`, osvežiti ekran, ponovo podići server komandom `docker compose up -d server` i kliknuti „Pokušaj ponovo“.
5. Za promenu pravila uživo prvo sačuvati pokrenutu KT2 verziju klijenta, zatim u domenu povećati minimum naslova, npr. sa 5 na 8, i ponovo izgraditi server sa `docker compose up -d --build server`. Stari klijent može da pošalje naslov od 5–7 znakova. Poruku o odbijanju pravi od koda greške i nove granice iz odgovora.

Repozitorijum i dalje sadrži memorijske adaptere za testove i KT1 demonstraciju. Taj režim se bira sa `--dart-define=KT1_MEMORY_DEMO=true`. U njemu i dalje rade `KT1_DEMO_EMPTY` i `KT1_DEMO_DELAY_MS`.

Iz korena pokrenuti `.\tool\verify.ps1` za proveru formatiranja, analizu i testove domena, Bloc-a, HTTP klijenta, prijave/sesije i obe aplikacije. Za proveru HTTP tokova pokrenuti smoke skriptu dok Compose radi. Detalji prvobitne KT1 implementacije ostaju u [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).
