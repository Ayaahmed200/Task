#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
API_DIR="$DOCS_DIR/api"

mkdir -p "$API_DIR"

# Clean previous generated files
find "$API_DIR" -type f -name "*.md" -delete || true

echo "Generating API docs into $API_DIR" >&2

# Utility to write a section header
write_header() {
  local file="$1"; shift
  local title="$1"; shift
  {
    echo "# $title"
    echo
    echo "Generated on $(date -u +"%Y-%m-%d %H:%M:%SZ")"
    echo
  } >> "$file"
}

append_block() {
  local file="$1"; shift
  local heading="$1"; shift
  local content="$1"; shift || true
  {
    echo "## $heading"
    echo
    [ -n "$content" ] && { echo "$content"; echo; }
  } >> "$file"
}

# TS/JS exports
if command -v rg >/dev/null 2>&1; then
  RG="rg"
else
  if command -v ripgrep >/dev/null 2>&1; then RG="ripgrep"; else RG=""; fi
fi

if [ -n "${RG}" ]; then
  mapfile -t ts_files < <(${RG} --glob "**/*.{ts,tsx,js,jsx,mts,cts}" --type-not json --type-not lock --hidden -n "^\s*export\s+" -l "$ROOT_DIR" 2>/dev/null | sort -u)
else
  mapfile -t ts_files < <(find "$ROOT_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.mts" -o -name "*.cts" \) | sort -u)
fi

if [ ${#ts_files[@]} -gt 0 ]; then
  out="$API_DIR/typescript.md"
  : > "$out"
  write_header "$out" "TypeScript / JavaScript API"
  for f in "${ts_files[@]}"; do
    rel=${f#"$ROOT_DIR/"}
    echo "### $rel" >> "$out"
    echo >> "$out"
    echo '```ts' >> "$out"
    sed -n '1,200p' "$f" >> "$out"
    echo '```' >> "$out"
    echo >> "$out"
  done
fi

# Python public functions/classes (non-underscore)
mapfile -t py_files < <(find "$ROOT_DIR" -type f -name "*.py" 2>/dev/null | sort -u)
if [ ${#py_files[@]} -gt 0 ]; then
  out="$API_DIR/python.md"
  : > "$out"
  write_header "$out" "Python API"
  for f in "${py_files[@]}"; do
    rel=${f#"$ROOT_DIR/"}
    {
      echo "### $rel"
      echo
      echo '```python'
      awk '/^\s*def\s+[a-zA-Z][a-zA-Z0-9_]*\(|^\s*class\s+[A-Z][A-Za-z0-9_]*/{print}' "$f"
      echo '```'
      echo
    } >> "$out"
  done
fi

# Go public items (capitalized identifiers)
mapfile -t go_files < <(find "$ROOT_DIR" -type f -name "*.go" 2>/dev/null | sort -u)
if [ ${#go_files[@]} -gt 0 ]; then
  out="$API_DIR/go.md"
  : > "$out"
  write_header "$out" "Go API"
  for f in "${go_files[@]}"; do
    rel=${f#"$ROOT_DIR/"}
    {
      echo "### $rel"
      echo
      echo '```go'
      awk '/^\s*type\s+[A-Z][A-Za-z0-9_]*/ || /^\s*func\s+\([^)]+\)\s+[A-Z][A-Za-z0-9_]*\(/ || /^\s*func\s+[A-Z][A-Za-z0-9_]*\(/{print}' "$f"
      echo '```'
      echo
    } >> "$out"
  done
fi

# Rust public items
mapfile -t rs_files < <(find "$ROOT_DIR" -type f -name "*.rs" 2>/dev/null | sort -u)
if [ ${#rs_files[@]} -gt 0 ]; then
  out="$API_DIR/rust.md"
  : > "$out"
  write_header "$out" "Rust API"
  for f in "${rs_files[@]}"; do
    rel=${f#"$ROOT_DIR/"}
    {
      echo "### $rel"
      echo
      echo '```rust'
      awk '/^\s*pub\s+(fn|struct|enum|trait)\s+/{print}' "$f"
      echo '```'
      echo
    } >> "$out"
  done
fi

# Java public types/methods
mapfile -t java_files < <(find "$ROOT_DIR" -type f -name "*.java" 2>/dev/null | sort -u)
if [ ${#java_files[@]} -gt 0 ]; then
  out="$API_DIR/java.md"
  : > "$out"
  write_header "$out" "Java API"
  for f in "${java_files[@]}"; do
    rel=${f#"$ROOT_DIR/"}
    {
      echo "### $rel"
      echo
      echo '```java'
      awk '/^\s*public\s+/{print}' "$f"
      echo '```'
      echo
    } >> "$out"
  done
fi

# Components (React .tsx/.jsx basic extraction)
if [ ${#ts_files[@]} -gt 0 ]; then
  out="$API_DIR/components.md"
  : > "$out"
  write_header "$out" "Components"
  for f in "${ts_files[@]}"; do
    case "$f" in
      *.tsx|*.jsx)
        rel=${f#"$ROOT_DIR/"}
        name=$(basename "$f")
        echo "### $rel" >> "$out"
        echo >> "$out"
        echo '```tsx' >> "$out"
        sed -n '1,200p' "$f" >> "$out"
        echo '```' >> "$out"
        echo >> "$out"
      ;;
    esac
  done
fi

# Index file
index="$API_DIR/README.md"
: > "$index"
write_header "$index" "API Reference"

for f in $(ls "$API_DIR"/*.md 2>/dev/null | xargs -I {} basename {} | sort); do
  [ "$f" = "README.md" ] && continue
  echo "- [${f%.md}](/docs/api/$f)" >> "$index"
done

echo "Done." >&2