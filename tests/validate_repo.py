from __future__ import annotations

from pathlib import Path

from test_public_repo_hygiene import validate


ROOT = Path(__file__).parents[1]
errors = validate(ROOT)
if errors:
    raise SystemExit("\n".join(errors))
print("DargoJiao repository validation passed")
