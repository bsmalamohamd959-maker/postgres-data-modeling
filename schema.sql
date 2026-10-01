-- 1. Create Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL
);

-- 2. Create Posts Table
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

-- 3. Create Comments Table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id),
    users_id UUID REFERENCES users(id),
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Sample Insert Statements
INSERT INTO posts (user_id, title, body, status, published_at, metadata)
SELECT 
    id, 
    'My-First-post', 
    'Hello world', 
    'published', 
    now(), 
    '{"featured": true, "reading_time_minuts": 2, "tags": ["intro", "hello-world"]}'::jsonb
FROM users 
WHERE email = 'Emailtow.com';

INSERT INTO comments (post_id, users_id, body)
SELECT 
    p.id, 
    u.id, 
    'Thanks for sharing!'
FROM posts p, users u
WHERE p.title = 'My-Third-post' AND u.email = 'Emailfour.com';

-- 5. Linking Comments to Posts via User ID
UPDATE comments c
SET post_id = p.id
FROM posts p
WHERE c.users_id = p.users_id;
