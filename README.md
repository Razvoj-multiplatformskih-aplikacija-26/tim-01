# tim-01
Vodič za uređaje - Aplikacija sadrži katalog uređaja, personalizovane preporuke na osnovu tipa kose i željenog načina stilizovanja, poređenje modela, video-uputstva, vesti i mogućnost slanja upita za cenu putem Instagrama.

Opšti opis aplikacije

Korisnik bi u katalogu mogao da pregleda modele, njihove funkcije, nastavke, prednosti, mane i preporučenu namenu. Upitnik bi prikupljao podatke poput tipa i dužine kose, željene frizure i načina korišćenja, a zatim predlagao odgovarajuće uređaje i objašnjavao preporuku.

Aplikacija bi sadržala poređenje modela, korisničke recenzije, vesti o novim ili najavljenim uređajima i video-uputstva za pravilno korišćenje i održavanje. Urednici bi te podatke unosili i obrađivali kroz backoffice, dok bi javni veb prikazivao sadržaj koji je dostupan i pretraživačima.

Kako aplikacija ispunjava šest zahteva

1. Uloge
    Posetioci mogu da pregledaju katalog, vodiče, vesti i poređenja, dok registrovani korisnici mogu da sačuvaju omiljene uređaje, šalju recenzije i prijavljuju sadržaj. Urednici i administratori imaju posebna ovlašćenja za uređivanje kataloga, objava i video-uputstava, kao i za moderiranje recenzija.
2. Stanja
    Glavni pojam sa više stanja bile bi korisničke recenzije: na proveri, objavljena, privremeno sakrivena i odbijena ili arhivirana. Recenziju na proveri urednik može da objavi ili odbije, a objavljena recenzija može da se sakrije ako je prijavi više korisnika.
3. Pravila
    Server, na primer, može automatski da sakrije recenziju ako je prijave najmanje tri različita registrovana korisnika; urednik je zatim pregleda i odlučuje da li će je vratiti ili odbiti. Server proverava da su prijave od različitih korisnika i donosi konačnu odluku, pa pravilo zavisi od podataka više korisnika.
4. Rad bez mreže
    Korisnik može bez interneta da sačuva uređaj među omiljene ili da napravi nacrt recenzije. Aplikacija čuva izmenu lokalno i sinhronizuje je sa serverom kada se internet ponovo uspostavi.
5. Posao za osoblje
    Urednici koriste backoffice na većem ekranu da pretražuju i uređuju veliki broj uređaja, recenzija, vesti i video-uputstava. Mogu da filtriraju recenzije po statusu, obrađuju prijave i ažuriraju podatke kataloga.
6. Javni sadržaj
    Katalog uređaja, poređenja, vodiči, video-uputstva i objavljene vesti dostupni su bez prijave na javnom vebu. Tako korisnici mogu da ih pronađu preko pretraživača i pre nego što instaliraju aplikaciju.

Preporuka uređaja može da se zasniva na jednostavnom poklapanju odgovora iz upitnika sa osobinama uređaja — nije potrebna veštačka inteligencija. Na primer, aplikacija može da predloži model zbog nastavaka i načina stilizovanja koji odgovaraju korisnikovom izboru.
