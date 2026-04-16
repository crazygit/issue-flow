# Tests

## Running Tests

```bash
# All tests
bash tests/state-machine/run-tests.sh
bash tests/skill-loading/run-tests.sh

# Or run all at once
for t in tests/*/run-tests.sh; do bash "$t"; done
```

## Test Categories

### State Machine Tests (`tests/state-machine/`)

Validates the `state-transition-guard.sh` hook correctly allows legal state transitions and blocks illegal ones.

### Skill Loading Tests (`tests/skill-loading/`)

Validates all SKILL.md files have correct YAML frontmatter (name, description, valid format).
