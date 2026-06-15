#!/usr/bin/env bash

export PATH="$HOME/.local/bin:$PATH"
export UV_CACHE_DIR="$HOME/.cache/uv"
export UV_PYTHON_DOWNLOADS=never

WORKSPACE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$WORKSPACE_ROOT" || return 1

export WORKSPACE_ROOT
export STARSHIP_CONFIG="$WORKSPACE_ROOT/.starship.toml"
export NETRC="$WORKSPACE_ROOT/.netrc"

command -v module >/dev/null 2>&1
HPC_ENV=$?

if [ $HPC_ENV -eq 0 ]; then
  module load nodejs/18.17.1
  module load Python/3.12.3
  module load OpenSSL/1.1
  command -v uv >/dev/null 2>&1 || python3 -m pip install --user uv
  export PATH="$HOME/.local/bin:$PATH"
  case "${LUNGCT_GPU:-}" in
    a100)
      export UV_PROJECT_ENVIRONMENT="$HOME/.venvs/lungct-a100"
      TORCH_INDEX="pytorch-cu126"
      ;;
    b6000)
      export UV_PROJECT_ENVIRONMENT="$HOME/.venvs/lungct-b6000"
      TORCH_INDEX="pytorch-cu128"
      ;;
    latest)
      export UV_PROJECT_ENVIRONMENT="$HOME/.venvs/lungct-latest"
      TORCH_INDEX=""
      ;;
    *)
      echo "Error: set LUNGCT_GPU=a100, LUNGCT_GPU=b6000, or LUNGCT_GPU=latest"
      return 1 2>/dev/null || exit 1
      ;;
  esac
  rm -f "$WORKSPACE_ROOT/uv.toml"
  python3 - "$TORCH_INDEX" <<'PYEOF'
import re, sys
from pathlib import Path
index = sys.argv[1]
p = Path("pyproject.toml")
text = p.read_text()
text = re.sub(r'\ntorch\s*=\s*\{[^\n]*\}', '', text)
if index:
    text = re.sub(
        r'(\[tool\.uv\.sources\])',
        r'\1\ntorch = { index = "' + index + '" }',
        text,
    )
p.write_text(text)
PYEOF
elif [ "${IN_NIX_SHELL:-0}" != "0" ]; then
  export UV_PROJECT_ENVIRONMENT="$HOME/.venvs/lungct-nix"
else
  echo "Error: run inside nix develop or on HPC"
  return 1 2>/dev/null || exit 1
fi

export UV_PYTHON="$(which python3)"

echo "Syncing workspace ($UV_PROJECT_ENVIRONMENT)..."
uv sync --dev

# shellcheck disable=SC1091
. "$UV_PROJECT_ENVIRONMENT/bin/activate"
