-- Optional: run this AFTER the app has started once (so Hibernate has
-- created the `books` table). Adds a MySQL FULLTEXT index across
-- title/author for noticeably faster search once you have tens of
-- thousands of rows. The app works fine without this — it's an upgrade,
-- not a requirement.

ALTER TABLE books ADD FULLTEXT INDEX ft_title_author (title, author);

-- Example fulltext query you could switch the search repository to use:
-- SELECT * FROM books
-- WHERE MATCH(title, author) AGAINST (? IN NATURAL LANGUAGE MODE)
-- LIMIT 20 OFFSET 0;
