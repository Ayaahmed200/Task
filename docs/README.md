# Documentation

Welcome! This repository currently has no discoverable source files, so this documentation provides the structure, templates, and instructions to generate comprehensive docs once code is added.

## Structure
- API Reference: `docs/api/`
- Guides & How-To: `docs/guides/`
- Components: `docs/components/`
- Examples: `docs/examples/`

## Generating Documentation
When source code is added, run the docs generator script:

```bash
bash scripts/generate-docs.sh
```

The script will:
- Detect supported languages (TypeScript/JavaScript, Python, Go, Rust, Java)
- Extract exported/public APIs
- Build markdown references into `docs/api`

## Authoring Guides
Place step-by-step guides under `docs/guides`. Use the template in `docs/templates/guide.md`.

## Components
When UI components exist, document them under `docs/components` using `docs/templates/component.md`.

## Examples
Runnable examples live in `docs/examples`. Keep them minimal and copy-paste friendly.

## Contributing to Docs
- Prefer clear, concise examples
- Show inputs/outputs
- Link to source files with relative paths
- Keep headings consistent and skimmable