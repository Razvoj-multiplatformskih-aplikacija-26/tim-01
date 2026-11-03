=# tim-01
# Vodič za uređaje

Vodič za uređaje je multiplatformska informativna aplikacija za Dyson uređaje. Korisnici mogu da pregledaju katalog, popune upitnik i dobiju personalizovane preporuke, uporede modele, pročitaju vesti i pogledaju video-uputstva za korišćenje i održavanje. Aplikacija ne obrađuje kupovinu i plaćanje; zainteresovani korisnici mogu da pošalju upit za cenu putem Instagrama.

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

Server automatski privremeno sakriva objavljenu recenziju kada je prijave najmanje tri različita registrovana korisnika. Server proverava da prijave potiču od različitih korisnika i menja stanje recenzije, nakon čega urednik odlučuje da li će je ponovo objaviti ili odbiti.

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
packages/
  domain/       model recenzije, stanja, pravila i port repozitorijuma
  blocs/        zajednički ReviewBloc, događaji i stanja ekrana
tool/
  generate_platforms.ps1
  verify.ps1
```

Za KT1 glavni pojam je korisnička recenzija. Mobilna aplikacija prikazuje zapise, detalj, formu za novu recenziju i prijavljivanje sadržaja. Backoffice daje uredniku tabelu ili listu, pretragu, filtere, bočni detalj i akcije moderacije. Oba klijenta koriste iste pakete `domain` i `blocs`, ali imaju zasebne podatke u memoriji.

### Prvo pokretanje

Potrebni su Flutter 3.47 ili noviji sa Dart 3.13 ili novijim, Android alatke i Visual Studio sa paketom Desktop development with C++.

```powershell
# Iz korena repozitorijuma, samo prvi put:
.\tool\generate_platforms.ps1

# Provera formata, analize i testova:
.\tool\verify.ps1

# Mobilna aplikacija:
Push-Location apps\mobile
flutter run
Pop-Location

# Backoffice za Windows:
Push-Location apps\backoffice
flutter run -d windows

# Isti backoffice u pregledaču:
flutter run -d chrome
Pop-Location
```

Skripta za platforme ne prepisuje postojeće foldere. Ako su `android`, `windows` ili `web` već generisani, zaustaviće se i tražiti da se stanje prvo ručno proveri.

Detaljan redosled rada i kriterijumi završetka nalaze se u [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).
