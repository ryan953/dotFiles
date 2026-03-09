---
name: browser-test
description: Browse a website, take screenshots, and make visual or functional assertions using rodney. Use when the user wants to visit a URL, verify how a page looks, check that UI elements are present, or validate page behavior in a real browser.
trigger: Use when interacting with a live website — checking a page, capturing screenshots, asserting content, or verifying a feature works in the browser.
---

# Browser Test

Use `rodney` to interact with websites, capture screenshots, and assert page behavior.

## Goals

- Navigate to URLs and capture screenshots as visual evidence
- Assert that specific content, elements, or states are present on the page
- Verify a feature or fix works correctly in a real browser
- Produce a brief summary of findings with screenshots attached

## Workflow

1. Run `rodney --help` to confirm available commands and flags.
2. Navigate to the target URL.
3. Capture a screenshot of the relevant page or state.
4. Make assertions against visible content or element presence.
5. If something looks wrong, capture additional screenshots of the failure state.
6. Report findings: what was checked, what passed, what failed, with screenshots.

## Tool preference

Prefer `rodney` over `playwright-cli` for all website interaction. Use `playwright-cli` only if rodney lacks a required capability.
