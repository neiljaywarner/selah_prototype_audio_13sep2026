# Product Requirements Document & Use Cases
*This page mirrors the official PRD in `docs/PRD_AND_USE_CASES.md`.*

## 1. Executive Vision
Selah provides hands-free, looped auditory immersion in Scripture passages. We bridge the gap between whole-chapter audio recordings and targeted personal meditation.

## 2. Personas
- **Sarah (Morning Commuter / Walker)**: Listens to *1 Cor 13:4–7* while walking. Phone stays in coat pocket; excerpt loops with 5-second silence between plays.
- **Pastor David (Sermon Prep)**: Compares *Romans 8:31–39* in Berean Standard Bible (BSB) vs. World English Bible (WEB) using Translation Shuffle.
- **Marcus (Evening Calming Meditation)**: Listens to *Psalm 23* to fall asleep peacefully without blue light.

## 3. Curated Excerpt Catalog
- **1 Corinthians 13:4–7**: Love is patient, love is kind (1CO 13:4–7)
- **Matthew 11:28–30**: Come to Me, all you who are weary (MAT 11:28–30)
- **Romans 8:31–39**: More than conquerors (ROM 8:31–39)
- **Psalm 23:1–6**: The Lord is my Shepherd (PSA 23:1–6)

## 4. Guardrail for Custom Queries
When users type an unaligned verse range like `col 1:17-20`, a polite floating SnackBar explains:
> *"Feature coming soon! Custom verse range 'col 1:17-20' will be supported in v0.3.0. Enjoy our curated demo passages (1 Cor 13, Matt 11, Rom 8, Psalm 23) or full chapters."*
