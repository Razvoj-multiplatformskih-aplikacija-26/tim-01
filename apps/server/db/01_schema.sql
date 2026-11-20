BEGIN;

CREATE TABLE users (
    id text PRIMARY KEY,
    email text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    role text NOT NULL CHECK (role IN ('mobile', 'editor'))
);

CREATE TABLE sessions (
    token_hash text PRIMARY KEY,
    user_id text NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    expires_at timestamptz NOT NULL
);

CREATE INDEX sessions_expires_at_idx ON sessions (expires_at);

CREATE TABLE reviews (
    id text PRIMARY KEY,
    device_id text NOT NULL,
    author_id text NOT NULL REFERENCES users (id),
    title text NOT NULL,
    body text NOT NULL,
    rating integer NOT NULL,
    status text NOT NULL CHECK (status IN ('pending', 'published', 'hidden', 'rejected', 'archived')),
    submitted_at timestamptz NOT NULL,
    status_at timestamptz NOT NULL,
    rejection_reason text,
    CHECK ((status = 'rejected') = (rejection_reason IS NOT NULL))
);

CREATE INDEX reviews_submitted_at_idx ON reviews (submitted_at DESC, id DESC);
CREATE INDEX reviews_status_submitted_at_idx ON reviews (status, submitted_at DESC, id DESC);
CREATE INDEX reviews_author_submitted_at_idx ON reviews (author_id, submitted_at DESC, id DESC);

CREATE TABLE review_reports (
    review_id text NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
    reporter_id text NOT NULL REFERENCES users (id),
    PRIMARY KEY (review_id, reporter_id)
);

COMMIT;
