# Git Workflow Guide for Feature Development

## The Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feat/your-feature-name
```

**Why:** Never work directly on `main`. A branch gives you isolation — if something goes wrong, `main` is untouched. The branch name should describe the feature (e.g., `feat/tabbed-pages`, `fix/login-bug`).

### 2. Work in Small Commits (TDD Loop)

For each piece of the feature, repeat this cycle:

```
Write failing test → Make it pass → Commit
```

Each commit should be one logical unit:
- `feat: add PageTab data class`
- `feat: convert MainAreaTemplate to StatefulWidget`
- `feat: add tab bar navigation`
- `refactor: update example app`
- `docs: update README`
- `chore: bump version`

**Why small commits?**
- Easy to review what changed
- Easy to revert one piece without losing everything
- Each commit leaves the project in a working state

### 3. Verify Before Moving On

After every commit:
```bash
flutter test          # Do all tests pass?
flutter analyze       # Any lint issues?
```

**Never move forward with broken tests.** Fix them first.

### 4. Merge Back to Main

```bash
git checkout main
git merge feat/your-feature-name    # Fast-forward merge
flutter test                         # Verify again on main
git branch -d feat/your-feature-name # Clean up
```

## Commit Message Conventions

Use prefixes to categorize changes:

| Prefix | When to use |
|---|---|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `refactor:` | Restructuring code without changing behavior |
| `docs:` | Documentation only |
| `chore:` | Version bumps, config, maintenance |
| `test:` | Adding or fixing tests only |

## When You Get a New Requirement

Here's your checklist:

1. **Understand** — What exactly needs to change? Which files?
2. **Branch** — `git checkout -b feat/descriptive-name`
3. **Break it down** — Split the work into small, testable pieces
4. **For each piece:**
   - Write a test that fails
   - Write the minimum code to pass it
   - Run `flutter test` + `flutter analyze`
   - Commit with a clear message
5. **Update docs** — README, CHANGELOG, version if needed
6. **Merge** — Back to main after everything passes
7. **Clean up** — Delete the feature branch

## A Real Example

Say you get: *"Add a badge count to each tab"*

```
Branch:  git checkout -b feat/tab-badge

Commit 1: "feat: add badge property to PageTab"
  - Add test: PageTab stores badge count
  - Add `int? badge` field to PageTab

Commit 2: "feat: render badge on tab chips"
  - Add test: badge renders on tab chip
  - Update _PageTabChip to show badge circle

Commit 3: "refactor: add badge demo to example"
  - Update example app

Commit 4: "docs: document badge parameter"
  - Update README

Merge back to main, delete branch.
```

The key insight: **small steps, always working, always tested.** It feels slower at first, but you avoid big debugging sessions and always have a safe point to go back to.
