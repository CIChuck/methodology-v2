# Clinical Sample Reference Corpus

This folder contains approved non-PHI clinical reference samples for the BeneCard PA Document
Intelligence project.

These files may be used for:

- unit tests;
- integration tests;
- user acceptance testing;
- parser, digest, image-to-text, decomposition, and crosswalk evaluation.

New files may be added to this folder only after they are confirmed non-PHI. Do not commit patient
identifiers, raw PHI-bearing client packets, extracted PHI, or LLM responses containing PHI.

Tests that use these samples should prefer stable assertions such as page count, parser behavior,
digest completeness, page identity, extraction status, and expected high-level signals. Avoid brittle
full-text assertions unless the expected text is intentionally stable.
