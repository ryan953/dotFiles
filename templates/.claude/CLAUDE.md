## Package Manager
Detect from project: `package.json` → check `packageManager` field or lockfile (`pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`)

When starting a new JavaScript or TypeScript project prefer `pnpm` and the latest release of Node v24

## Task tracking

Use the `dex` command to create durable tasks, and track progress.
Check `dex --help` for available commands.

## Writing

Be specific when referencing other works or sources. 
Don't try to be over-precise or over-certain when summarizing or making conclusions.
Try not to use contrastive negation all the time

## PR Descriptions
Keep PR descriptions focused on the reasons for a change, and any interesting or non-obvious design choices.
The description should include why, and an overview of how we're achieving some goal. If there are obvious approaches not chosen we should call them out and explain why we're not doing that.
Include references to dependencies if there are other PRs or files to that should change before/after this set.

PRs should also always call out the names of any feature-flags being used, so people can test the changes properly.
Include screenshots whenever possible, to people have a visual reference.

## Code Comments

Keep code comments focused on the rational for a design choice.
The purpose is not to re-state what the code is already doing, unless the code is non-conventional or is too terse.
Do not reference other places, especially external sources, or previous descisions that are no longer part of the codebase. Just explain the reasons why this was chosen, rarely compare to other options unless they're the obvious paths not taken.
Comments should be to the point, and not "AI slop"

## Code Search & Intelligence

`ast-grep` is an abstract syntax tree based tool to search code by pattern code. You can write patterns as 
if you are writing ordinary code. It will match all code that has the same syntactical structure. You can 
use `$` sign & upper case letters as a wildcard, e.g. `$MATCH`, to match any single AST node. Think of it as regular expression dot ., except it is not textual.

Use `ast-grep` has following form.

`ast-grep --pattern 'var code = $PATTERN' --rewrite 'let code = new $PATTERN' --lang ts`
Example
  Rewrite code in null coalescing operator
  `ast-grep -p '$A && $A()' -l ts -r '$A?.()'`
Rewrite Zodios
  `ast-grep -p 'new Zodios($URL,  $CONF as const,)' -l ts -r 'new Zodios($URL, $CONF)' -i`

When searching code **prefer ast-grep, or the language-specific LSP instead of the Grep** or Read tool calls. These are 
faster, more precise, and avoids reading entire files.

LSP includes:
- `workspaceSymbol` to find where something is defined
- `findReferences` to see all usages across the codebase
- `goToDefinition` / `goToImplementation` to jump to source
- `hover` for type info without reading the file

Use Grep only when LSP isn't available or for text/pattern searches (comments, strings, config).

**Always**: After writing or editing code, check LSP diagnostics and fix errors before proceeding.

## Testing Philosophy
- Write tests for React components using React Testing Library
- Focus on user behavior over implementation
- Test accessibility (roles, labels, keyboard nav)
- Prefer integration tests over unit tests
- Use browser automation to take screenshots and include them in Pull Request descriptions

## React Patterns
- Functional components with hooks
- Custom hooks for reusable logic
- Composition over inheritance
- Co-locate styles with components

## Tech Stack Expertise
- **React**: Hooks, context, suspense, concurrent features
- **Testing**: Jest, React Testing Library, Playwright, Vitest
- **Styling**: CSS Modules, Tailwind, CSS-in-JS, vanilla CSS
- **Build**: Vite, Webpack, esbuild, Turbopack
- **Types**: TypeScript preferred
