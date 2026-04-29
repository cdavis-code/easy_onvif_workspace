---
name: update-readme
description: Updates README.md to match the current project state. Use when the user says "update readme", "sync readme", "refresh documentation", "readme is outdated", or asks to document the project.
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Update README

Analyze a project's codebase and update its README.md to accurately reflect the current state.

## Instructions

1. Read the current `README.md` to understand existing structure
2. Read package files (`pubspec.yaml`, `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, etc.) for metadata
3. Use Glob to understand directory layout (`**/*.{js,ts,py,go,rs}`)
4. Compare README against actual codebase for discrepancies
5. Update only sections that are outdated or incorrect
6. Provide a summary of changes made

## What to verify

- **Dependencies:** Match actual package files
- **Features:** Reflect capabilities found in code
- **Installation:** Steps work with current setup
- **Usage examples:** Code snippets are accurate
- **File references:** Mentioned paths exist
- **Configuration:** Options are complete

## Rules

- MUST preserve existing README structure when possible
- MUST keep any badges, images, or custom formatting
- MUST use relative links for internal documentation
- Never add sections that weren't requested
- Never remove sections without explicit approval
- Never fabricate features not found in the codebase

## Output

After updating, summarize:
- Sections updated
- What was added or removed
- Anything needing manual review
