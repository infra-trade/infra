#!/usr/bin/env bash
# prep-commit-and-update.sh
# 1) Muestra cambios locales
# 2) Si hay cambios, hace commit WIP
# 3) Llama a ./update-from-remote.sh con los mismos argumentos

set -euo pipefail

# Entra a la raíz del repo (por si se ejecuta desde un subdirectorio)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "ERROR: Aquí no parece haber un repositorio Git (no se pudo resolver la raíz)."
  exit 1
fi
cd "${REPO_ROOT}"

echo "==> Estado del repo:"
git status

# Detecta cambios sin commitear
if [[ -n "$(git status --porcelain)" ]]; then
  echo "==> Hay cambios locales: agregando y creando commit WIP…"
  git add -A
  # Permite personalizar el mensaje con COMMIT_MSG, si no usa uno por defecto con fecha
  COMMIT_MSG="${COMMIT_MSG:-WIP: mis cambios locales ($(date -Iseconds))}"
  git commit -m "${COMMIT_MSG}"
else
  echo "==> No hay cambios locales, nada que commitear."
fi

# Verifica que el script update-from-remote.sh exista y sea ejecutable
if [[ ! -x "./update-from-remote.sh" ]]; then
  if [[ -f "./update-from-remote.sh" ]]; then
    echo "==> ./update-from-remote.sh existe pero no es ejecutable. Corrigiendo permisos…"
    chmod +x ./update-from-remote.sh
  else
    echo "ERROR: No encuentro ./update-from-remote.sh en ${REPO_ROOT}"
    exit 1
  fi
fi

echo "==> Ejecutando ./update-from-remote.sh $*"
./update-from-remote.sh "$@"

echo "==> Listo."