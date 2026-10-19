# Vendored Markdown renderer

- Package: `markdown-it` 15.0.1, MIT licensed; see `LICENSE` in this directory.
- Source: the project's locked contributor dependency, browser UMD distribution
  at `markdown-it/dist/browser/markdown-it.umd.min.js`.
- Local filename: `markdown-it.min.js`, copied without modification.
- SHA-256: `f9f377ca892291fbe32904e77a00c6e27e8f95c14f435a54c8cb6859b3d97692`.
- Purpose: render trusted bundled documentation offline in a browser without
  requiring Node.js on an end-user Mac. Raw HTML and automatic link detection
  are disabled by the reader. No plugins, network scripts or CDN assets load.

To update, review the locked package and licence, copy its browser distribution,
record the new version/checksum here, and run the documentation fixture plus a
browser smoke test. Do not edit the minified distribution by hand.
