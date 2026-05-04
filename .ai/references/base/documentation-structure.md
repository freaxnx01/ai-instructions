# Documentation directory structure

Repo-root layout for project documentation.

```
docs/
├── design/                    ← UI wireframes & Mermaid flows per feature
│   └── <feature-name>/
│       ├── wireframe.md       ← Phase 1 output (ASCII wireframe)
│       └── flow.md            ← Phase 2 output (Mermaid diagrams)
├── adr/                       ← Architecture Decision Records
└── ai-notes/                  ← AI agent working notes
```

- `README.md` and `CHANGELOG.md` live in the repo root
- UI design artifacts are saved per feature during the UI workflow phases
- AI agents write working notes to `docs/ai-notes/`, not `.ai/`
- `.ai/` is reserved for agent instructions and skill files only
