# Legal Case Timeline Tree Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the process detail Timeline into a tree-style vertical timeline grouped by date.

**Architecture:** Keep the existing `LegalCaseShowApp` snapshot contract and visible item limit. Add a local grouping helper in the React component, render date groups with a left rail and event nodes, and restyle the timeline section in `legalCaseShow.css`.

**Tech Stack:** React, TypeScript, Vite/Vitest, Testing Library, CSS.

## Global Constraints

- Do not commit changes unless explicitly authorized.
- Keep the tree inside the process detail screen.
- Preserve the current expand/collapse behavior for older timeline items.
- Follow the current Aurora visual tokens and component naming.

---

## Tasks

### Task 1: Timeline Grouping Behavior

**Files:**
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx`

**Steps:**
- [ ] Add a failing test that renders multiple timeline items on two dates and expects two date groups.
- [ ] Run the focused frontend test and confirm it fails because the tree groups do not exist.
- [ ] Add a `groupTimelineByDate` helper that groups visible timeline items by `occurred_at_label`.
- [ ] Render the timeline as grouped date nodes with event lists.
- [ ] Run the focused frontend test and confirm it passes.

### Task 2: Timeline Tree Styling

**Files:**
- Modify: `app/frontend/legal_case_show/legalCaseShow.css`

**Steps:**
- [ ] Replace the existing flat timeline item styling with tree rail, date pill, node marker, and event card styles.
- [ ] Keep mobile layout compact and avoid text overflow.
- [ ] Run the focused frontend test.
- [ ] Run the frontend test suite for `legal_case_show`.
