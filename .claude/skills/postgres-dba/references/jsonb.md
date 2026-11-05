# jsonb columns

Examples come from the Ether codebase; adapt names to your repo.

Use jsonb for provider payloads and genuinely open-ended, document-shaped
data. Never `json`. In a migration, `:map` and `:jsonb` both create a jsonb
column; in the schema the field is `:map` (or `{:array, :map}`).

## Relational spine, jsonb body

Columns you filter, sort, join or upsert on are real columns. The rest can sit
in the document:

`social_media_posts` is the model: keyed on `(provider, post_id)`, the raw
provider response in `post_data` (`:map`), and the fields feeds query on
(`published_at`, `has_media`, `related_player_ids`, …) as real columns.
`has_media` was promoted out of the payload because feeds filter on it
(ADR-0001 denormalize-has-media). That's the pattern: if a query needs a
field, it gets a column, set by the worker that writes the payload.

## Querying inside a document

Only for occasional reads. Keep it in pipe syntax with named bindings:

```elixir
Post
|> from(as: :post)
|> where([post: post], fragment("?->>'lang' = ?", post.post_data, ^language))
```

If this shows up on a hot path, promote the field to a column or add a GIN
index (`execute/2`, `CREATE INDEX CONCURRENTLY ... USING gin (post_data)`).

## Don't

- Store data in jsonb that you join on.
- Build an EAV ("key", "value") table; use a `:map` column instead.
- Hold large provider responses in jsonb when only a few fields are read;
  extract those fields in the worker.
