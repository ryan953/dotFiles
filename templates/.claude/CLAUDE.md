## Package Manager
Detect from project: `package.json` → check `packageManager` field or lockfile (`pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`)

When starting a new JavaScript or TypeScript project prefer `pnpm` and the latest release of Node v24

## Task tracking

Use the `dex` command to create durable tasks, and track progress.
Check `dex --help` for available commands.

### Code Search & Intelligence

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
