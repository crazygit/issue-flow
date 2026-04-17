# Testing

Issue-Flow keeps its test surface small and focused. The main goal is to protect the workflow contract rather than to simulate a full agent runtime.

## Test Suites

### State machine tests

```bash
bash tests/state-machine/run-tests.sh
```

These tests validate that the state-transition guard allows legal transitions and blocks invalid ones.

### Skill loading tests

```bash
bash tests/skill-loading/run-tests.sh
```

These tests validate `SKILL.md` files, including required frontmatter and structural expectations.

## Run Everything

```bash
bash tests/state-machine/run-tests.sh && bash tests/skill-loading/run-tests.sh
```

## When To Run Tests

- Run both suites before opening a pull request
- Run the state-machine suite after changing workflow phases, transition rules, or guard logic
- Run the skill-loading suite after editing any `SKILL.md` file or metadata

## If You Change Behavior

If a change affects the visible workflow, do all of the following:

- update the relevant docs
- update tests if the contract changed intentionally
- explain the behavior change in the pull request summary
