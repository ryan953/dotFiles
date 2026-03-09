---
name: pr-explain
description: Create an executable demo document (demo.md) that explains and proves what a feature or PR does, using showboat to mix commentary, shell commands, and captured output. Use when the user wants to document, demonstrate, or explain a feature they just built — especially before opening a PR or sharing work with reviewers.
trigger: Use when asked to "explain this PR", "document what I built", "create a demo", "show how this feature works", or "write a pr explanation".
---

# PR Explain

Use `showboat` to produce a `demo.md` that shows what the feature does and proves it works.

## Goals

- Explain the feature in plain language a reviewer can follow
- Demonstrate the feature with real, executable commands and captured output
- Include screenshots or images where visual evidence helps
- Produce a document that is reproducible — a verifier can re-run it and confirm outputs still match

## Workflow

1. Run `uvx showboat --help` to confirm available commands.
2. Run `uvx showboat init demo.md "<feature title>"` to create the document.
3. Add a brief commentary block explaining what the feature does and why.
4. For each key behavior, add an exec block that runs the relevant command and captures output.
5. Where UI or visual output matters, capture a screenshot with `rodney` and add it with `showboat image`.
6. Add a closing note summarizing what was demonstrated and any known limitations.
7. Optionally run `uvx showboat verify demo.md` to confirm all outputs are reproducible.

## Output

A `demo.md` file in the current directory containing:
- Plain-language description of the feature
- Executable code blocks with captured output
- Images/screenshots where relevant
- Reproducible via `showboat verify`
