from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).parents[1]
DARGO = ROOT / "dargo"


class DargoCliTests(unittest.TestCase):
    def run_dargo(
        self, *args: str, env: dict[str, str] | None = None
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(DARGO), *args],
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_version(self) -> None:
        result = self.run_dargo("version")

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "DargoJiao v0.2.1")

    def test_prompt_points_to_skill(self) -> None:
        result = self.run_dargo("prompt")

        self.assertEqual(result.returncode, 0)
        self.assertIn("$dargojiao", result.stdout)
        self.assertIn("templates/bootstrap-prompt.md", result.stdout)

    def test_unknown_command_fails(self) -> None:
        result = self.run_dargo("unknown")

        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_install_is_idempotent_in_temporary_root(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            env = os.environ.copy()
            env["DARGOJIAO_SKILLS_DIR"] = temporary

            first = self.run_dargo("install", env=env)
            second = self.run_dargo("install", env=env)

            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertTrue(
                (Path(temporary) / "dargojiao" / "SKILL.md").is_file()
            )


if __name__ == "__main__":
    unittest.main()
