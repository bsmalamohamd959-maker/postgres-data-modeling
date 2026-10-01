PostgreSQL Blog Schema

A small PostgreSQL schema for a blog-like application with users, posts, and comments.

## Data model

| Table | Purpose |
| --- | --- |
| `users` | Author and commenter accounts. |
| `posts` | Draft or published posts owned by a user. |
| `comments` | Comments made by a user on a post. |

Relationships:

```text
users 1 ──< posts
users 1 ──< comments >── 1 posts
```

## Prerequisites

This schema uses `gen_random_uuid()`, supplied by PostgreSQL's `pgcrypto` extension:

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

## Schema

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL
);

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    title TEXT NOT NULL,
    body TEXT,
    status TEXT DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at TIMESTAMPTZ DEFAULT now(),
    metadata JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id),
    users_id UUID REFERENCES users(id),
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## Sample data

Create a user before inserting a post that references them:

```sql
INSERT INTO users (email, display_name)
VALUES ('emailone.com', 'Example Author');

INSERT INTO posts (user_id, title, body, status, published_at, metadata)
SELECT
    id,
    'My First Post',
    'Hello world',
    'published',
    now(),
    '{"featured": true, "reading_time_minutes": 2, "tags": ["intro", "hello-world"]}'::jsonb
FROM users
WHERE email = 'emailone.com';

INSERT INTO comments (post_id, users_id, body)
SELECT
    p.id,
    u.id,
    'Thanks for sharing!'
FROM posts AS p
CROSS JOIN users AS u
WHERE p.title = 'My First Post'
  AND u.email = 'emailone.com';
```

## Notes and recommended improvements

- `comments.users_id` is retained to match the provided schema, but `user_id` is the conventional column name.
- `posts.user_id`, `comments.post_id`, and `comments.users_id` currently allow `NULL`. Make them `NOT NULL` if every post and comment must have an owner and relationship.
- A post normally should have `published_at` set only when it is published. Consider removing its default and setting it during publication.
- Restrict post states with a `CHECK` constraint or PostgreSQL enum, rather than accepting any text value.
- The original comment-linking update used `p.users_id`, which does not exist on `posts`; the correct column is `p.user_id`:

```sql
UPDATE comments AS c
SET post_id = p.id
FROM posts AS p
WHERE c.users_id = p.user_id;
```

Use that update cautiously: one user can own multiple posts, so it can assign a comment to an arbitrary matching post. Prefer inserting each comment with its intended `post_id`.

## Useful indexes

Foreign keys are not indexed automatically in PostgreSQL. These indexes help common post and comment lookups:

```sql
CREATE INDEX posts_user_id_idx ON posts (user_id);
CREATE INDEX comments_post_id_idx ON comments (post_id);
CREATE INDEX comments_users_id_idx ON comments (users_id);
