#!/usr/bin/env bash
set -euo pipefail

# Default params
REMOTE="${REMOTE:-origin}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"
TEST_BRANCH="${TEST_BRANCH:-test-sync}"
REPO_PATH="${1:-.}"
FORCE="${FORCE:-false}"   # Si true, descarta cambios locales (git reset --hard)

usage() {
  cat <<EOF
Uso:
  REMOTE=origin MAIN_BRANCH=main TEST_BRANCH=test-sync FORCE=false \\
  $0 [ruta-del-repo]

Variables de entorno (opcionales):
  REMOTE        Nombre del remoto (default: origin)
  MAIN_BRANCH   Rama principal a alinear (default: main)
  TEST_BRANCH   Rama adicional a fusionar desde remoto (default: test-sync)
  FORCE         true para descartar cambios locales (reset --hard). Por defecto: false

Ejemplos:
  $0
  REPO_PATH=/home/ansible/IaC/infra $0
  FORCE=true $0
  REMOTE=origin MAIN_BRANCH=main TEST_BRANCH=test-sync $0
EOF
}

# Ayuda rápida si el usuario pasa -h o --help
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Verificaciones
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git no está instalado o no está en PATH." >&2
  exit 1
fi

if [[ ! -d "$REPO_PATH/.git" ]]; then
  echo "ERROR: '$REPO_PATH' no parece ser un repositorio git." >&2
  exit 1
fi

cd "$REPO_PATH"

# Avisa si hay cambios sin commitear
if [[ "$FORCE" != "true" ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "ERROR: Hay cambios locales sin commitear. Aborto por seguridad."
    echo "       - Haz commit/stash de tus cambios, o"
    echo "       - Ejecuta con FORCE=true para descartar cambios locales."
    exit 1
  fi
fi

echo "==> 1) Fetch remoto: $REMOTE"
git fetch "$REMOTE" --prune

echo "==> 2) Checkout a rama principal: $MAIN_BRANCH"
git checkout "$MAIN_BRANCH"

echo "==> 3) Alinear $MAIN_BRANCH con $REMOTE/$MAIN_BRANCH"
if [[ "$FORCE" == "true" ]]; then
  echo "    (FORCE=true) Haciendo reset --hard (se descartan cambios locales)"
  git reset --hard "$REMOTE/$MAIN_BRANCH"
else
  # Reset suave: asegura historial sin tocar el árbol de trabajo si ya estaba limpio
  git reset --hard "$REMOTE/$MAIN_BRANCH"
fi

echo "==> 4) Merge de $REMOTE/$TEST_BRANCH en $MAIN_BRANCH (si existe)"
if git ls-remote --exit-code --heads "$REMOTE" "$TEST_BRANCH" >/dev/null 2>&1; then
  # --no-edit para no abrir el editor; si hay conflictos, el script se detiene
  git merge --no-edit "$REMOTE/$TEST_BRANCH"
  echo "   Merge completado."
else
  echo "   Aviso: $REMOTE/$TEST_BRANCH no existe. Se omite merge."
fi

echo "✔ Hecho."
git --no-pager log --oneline -n 5