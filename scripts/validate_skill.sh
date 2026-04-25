#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="${ROOT_DIR}/gpt-image-relay"

ROOT_DIR_ENV="${ROOT_DIR}" python3 - <<'PY'
from pathlib import Path
import os
import re
import sys
import yaml

root = Path(os.environ["ROOT_DIR_ENV"])
skill_dir = root / "gpt-image-relay"
skill_md = skill_dir / "SKILL.md"
agent_yaml = skill_dir / "agents" / "openai.yaml"

allowed_extensions = {
    ".md", ".mdx", ".txt", ".json", ".json5", ".yaml", ".yml", ".toml", ".js",
    ".cjs", ".mjs", ".ts", ".tsx", ".jsx", ".py", ".sh", ".rb", ".go", ".rs",
    ".swift", ".kt", ".java", ".cs", ".cpp", ".c", ".h", ".hpp", ".sql",
    ".csv", ".ini", ".cfg", ".env", ".xml", ".html", ".css", ".scss", ".sass",
    ".svg",
}

def fail(message):
    print(f"OpenClaw skill validation failed: {message}", file=sys.stderr)
    sys.exit(1)

if not skill_md.is_file():
    fail("missing gpt-image-relay/SKILL.md")

source = skill_md.read_text(encoding="utf-8")
match = re.match(r"^---\n(.*?)\n---\n(.*)$", source, re.S)
if not match:
    fail("SKILL.md must start with YAML frontmatter")

frontmatter = yaml.safe_load(match.group(1))
body = match.group(2)
if not isinstance(frontmatter, dict):
    fail("frontmatter must be a mapping")

name = frontmatter.get("name")
description = frontmatter.get("description")
version = str(frontmatter.get("version", "")).strip()
homepage = str(frontmatter.get("homepage", "")).strip()

if name != "gpt-image-relay":
    fail("frontmatter name must be gpt-image-relay")
if not re.match(r"^[a-z0-9][a-z0-9-]*$", name or ""):
    fail("name must be lowercase URL-safe")
if not description or len(str(description)) > 512:
    fail("description must be present and concise")
if not re.match(r"^\d+\.\d+\.\d+$", version):
    fail("version must be semver, for example 0.1.0")
if not homepage.startswith("https://github.com/Etherstrings/autoGenImageSkill"):
    fail("homepage must point to the GitHub project")

openclaw = ((frontmatter.get("metadata") or {}).get("openclaw") or {})
bins = ((openclaw.get("requires") or {}).get("bins") or [])
if "node" not in bins:
    fail('metadata.openclaw.requires.bins must include "node"')

for required in ["official", "proxy", "reserved", "scripts/gpt_image_cli.js", "{baseDir}/scripts/gpt_image_cli.js"]:
    if required not in body:
        fail(f"SKILL.md body does not explain {required}")

refs = re.findall(r"\[[^\]]+\]\((references/[^)]+)\)", body)
missing_refs = [ref for ref in refs if not (skill_dir / ref).is_file()]
if missing_refs:
    fail(f"missing referenced files: {missing_refs}")

if not agent_yaml.is_file():
    fail("missing agents/openai.yaml")
agent = yaml.safe_load(agent_yaml.read_text(encoding="utf-8"))
default_prompt = (((agent or {}).get("interface") or {}).get("default_prompt") or "")
if "$gpt-image-relay" not in default_prompt:
    fail("agents/openai.yaml default_prompt must mention $gpt-image-relay")
if ((agent or {}).get("policy") or {}).get("allow_implicit_invocation") is not True:
    fail("agents/openai.yaml should allow implicit invocation")

if (root / "scripts" / "install_skill.sh").exists():
    fail("install script exists; this repository should only generate the skill source")

bad_files = []
for path in skill_dir.rglob("*"):
    if path.is_dir():
        continue
    if path.name in {"SKILL.md"}:
        continue
    if path.suffix.lower() not in allowed_extensions:
        bad_files.append(str(path.relative_to(root)))
if bad_files:
    fail(f"non-text files are not ClawHub-friendly: {bad_files}")

print("OpenClaw source metadata ok")
PY

node --check "${SKILL_DIR}/scripts/gpt_image_cli.js"
node "${SKILL_DIR}/scripts/gpt_image_cli.js" help >/dev/null

printf 'OpenClaw skill validation passed for %s\n' "${SKILL_DIR}"
