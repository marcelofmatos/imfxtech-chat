#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Envia o .dmg para a notarização da Apple, espera o resultado e grampeia o
# ticket. Substitui o `notarytool submit --wait`, que derruba o job inteiro na
# primeira queda de rede durante a espera (aconteceu na v1.1.5). Aqui, falha de
# rede vira nova tentativa; só "Invalid"/"Rejected" ou o tempo limite falham.
#
# Uso: notarize-dmg.sh <arquivo.dmg>
# Env: ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID (chave de API do App Store Connect)
#      NOTARY_TIMEOUT_SECONDS (padrão 5400), NOTARY_POLL_SECONDS (padrão 30)

set -euo pipefail

dmg=$1
timeout=${NOTARY_TIMEOUT_SECONDS:-5400}
poll=${NOTARY_POLL_SECONDS:-30}
auth=(--key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID")

# Lê um campo de texto do JSON de uma linha que o notarytool imprime.
json_field() {
  sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p"
}

id=""
for attempt in 1 2 3; do
  if out=$(xcrun notarytool submit "$dmg" "${auth[@]}" --output-format json); then
    id=$(json_field id <<<"$out")
    [ -n "$id" ] && break
  fi
  echo "::warning::Envio para notarização falhou (tentativa $attempt de 3)."
  sleep "$poll"
done
[ -n "$id" ] || { echo "::error::Não foi possível enviar o .dmg para notarização."; exit 1; }
echo "Submission ID: $id"

deadline=$((SECONDS + timeout))
while :; do
  status=""
  if out=$(xcrun notarytool info "$id" "${auth[@]}" --output-format json); then
    status=$(json_field status <<<"$out")
  fi
  echo "$(date -u +%H:%M:%S) status: ${status:-sem resposta, tentando de novo}"
  case "$status" in
    Accepted) break ;;
    Invalid | Rejected)
      xcrun notarytool log "$id" "${auth[@]}" || true
      echo "::error::Notarização $status (submission $id)."
      exit 1
      ;;
  esac
  if ((SECONDS >= deadline)); then
    echo "::error::Notarização sem resultado em ${timeout}s (submission $id). Ela continua na Apple: xcrun notarytool info $id"
    exit 1
  fi
  sleep "$poll"
done

xcrun stapler staple "$dmg"
