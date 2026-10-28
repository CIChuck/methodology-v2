# Practitioner Guide HTML

This directory is the static web presentation of the canonical Practitioner Guide in
`../practitioner-guide/`.

The site intentionally keeps presentation separate from authority:

- `content/` contains exact copies of the canonical Markdown files;
- `index.html`, `assets/styles.css`, and `assets/app.js` provide navigation and rendering;
- `vendor/` contains pinned browser bundles for Marked and Mermaid plus their licenses;
- Mermaid code fences are rendered when present, although the current guide contains none.

The client requests mirrored Markdown with here.now's `?raw=1` response mode. Ordinary local file
servers ignore that query and serve the same source files normally.

To refresh the mirrored content after the canonical guide changes:

```bash
cp ../practitioner-guide/*.md content/
```

Serve the directory over HTTP for local testing. Direct `file://` access cannot fetch the Markdown
content because browser security policies block those requests.
