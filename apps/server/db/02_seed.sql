BEGIN;

INSERT INTO users (id, email, password_hash, role) VALUES
    ('editor-1', 'editor@example.test', 'pbkdf2-sha256$600000$K8FVZ8E2CqcI9nt5s9VMHA==$8sidil3wu+vJrG4pN1QbtCqteNQyTva8yIaC7ojU2c0=', 'editor'),
    ('mobile-1', 'mobile1@example.test', 'pbkdf2-sha256$600000$IEAl5q2fxUDULVaKvhLBpg==$/H8mqkPLc05CudSuAhZPYUDEBR16yoybspOeCW35nlA=', 'mobile'),
    ('mobile-2', 'mobile2@example.test', 'pbkdf2-sha256$600000$vq4kqaQOGEDpkcmU0JaWAQ==$vScaYFbz8x6nU5cZn+cCoZu2KO7c5tK+k9c0Z2jJ9Js=', 'mobile'),
    ('mobile-3', 'mobile3@example.test', 'pbkdf2-sha256$600000$QlflARUadWljLSRhwz/d5w==$fcsCuQiXptqv+o+sBkeqhIwvAOpJDPyZ9kE3TS4N01Q=', 'mobile'),
    ('mobile-4', 'mobile4@example.test', 'pbkdf2-sha256$600000$uD5Rkdgz/OJ+ku/kgAeaFg==$5+GWTg9LAXrvCMDBiqISQTTcf+HQWvp4ctTSK1YBYeY=', 'mobile'),
    ('mobile-5', 'mobile5@example.test', 'pbkdf2-sha256$600000$SqTNOr+kEfNbMpDheWsa7w==$XBbwFjfCNUSmq9Pna++RW4Un0VQKaj6+7UmWluXFDbA=', 'mobile');

INSERT INTO reviews
    (id, device_id, author_id, title, body, rating, status, submitted_at, status_at, rejection_reason)
VALUES
    ('review-1', 'airwrap-id', 'mobile-1', 'Brzo stilizovanje bez prejake toplote',
     'Posle nekoliko nedelja korišćenja kosa izgleda urednije, a postupak traje kraće nego ranije.',
     5, 'published', CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '9 days', NULL),
    ('review-2', 'supersonic-nural', 'mobile-4', 'Prijatniji je za svakodnevno sušenje',
     'Uređaj je dobro izbalansiran i podešavanje temperature je jednostavno čak i kada žurim ujutru.',
     4, 'pending', CURRENT_TIMESTAMP - INTERVAL '9 days', CURRENT_TIMESTAMP - INTERVAL '9 days', NULL),
    ('review-3', 'v15-detect', 'mobile-2', 'Dobro pokazuje sitnu prašinu',
     'Svetlo na podnom nastavku pomaže da vidim mesta preko kojih treba preći još jednom.',
     5, 'published', CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '7 days', NULL),
    ('review-4', 'gen5detect', 'mobile-2', 'Snažan, ali teži za duži rad',
     'Snaga usisavanja je dobra, ali se težina primeti kada se čisti više prostorija bez pauze.',
     4, 'hidden', CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '6 days', NULL),
    ('review-5', 'purifier-big-quiet', 'mobile-5', 'Dobar izbor za dnevnu sobu',
     'U tihom režimu može da radi dok razgovaramo, a podešavanje preko aplikacije je jednostavno.',
     4, 'pending', CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '6 days', NULL),
    ('review-6', 'wash-g1', 'mobile-3', 'Lakše održavanje pločica',
     'Najviše mi koristi posle kuvanja kada treba brzo da očistim deo poda pored šporeta.',
     4, 'published', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '4 days', NULL),
    ('review-7', 'airwrap-id', 'mobile-4', 'Potreban je pregled navoda',
     'Uređaj sam koristio samo jednom i nisam mogao da proverim sve opisane načine stilizovanja.',
     3, 'rejected', CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '3 days', 'Nepotpun opis.'),
    ('review-8', 'supersonic-nural', 'mobile-1', 'Ravnomernije sušenje kose',
     'Na srednjoj brzini uspem da osušim kosu bez dužeg zadržavanja nastavka na jednom mestu.',
     5, 'published', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days', NULL),
    ('review-9', 'v15-detect', 'mobile-3', 'Nastavci se lako zamenjuju',
     'Zamena nastavka ne traži alat, pa brzo mogu da pređem sa poda na usisavanje nameštaja.',
     4, 'archived', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 day', NULL),
    ('review-10', 'purifier-big-quiet', 'mobile-5', 'Korisno praćenje kvaliteta vazduha',
     'Pregled iz dana u dan mi pomaže da uporedim kada je vredelo povećati brzinu uređaja.',
     5, 'archived', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP, NULL);

INSERT INTO review_reports (review_id, reporter_id) VALUES
    ('review-1', 'mobile-2'),
    ('review-1', 'mobile-3'),
    ('review-4', 'mobile-1'),
    ('review-4', 'mobile-3'),
    ('review-4', 'mobile-5');

COMMIT;
