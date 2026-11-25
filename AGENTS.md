<!--
SPDX-FileCopyrightText: 2026 IMFX TECH LTDA

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# AGENTS.md — IMFxTech Chat

Instruções para agentes de código neste repositório. Foco em versão, release e publicação nas lojas.

## O que é este repositório

- App Flutter "IMFxTech Chat", fork do FluffyChat. O pacote Dart continua `name: fluffychat` no `pubspec.yaml`. Não renomeie.
- IDs: Android `com.imfxtech.chat`; iOS `com.imfxtech.chat`, `com.imfxtech.chat.Share` e `com.imfxtech.chat.NotificationService`; macOS `com.imfxtech.chat`.
- O `matrix-dart-sdk` vem de um fork (ver a dependência `matrix` no `pubspec.yaml`). A versão do Flutter fica em `.tool_versions.yaml`.
- O release roda em `marcelofmatos/imfxtech-chat`. Lá ficam os secrets, os runs do "Release and Build" e as GitHub Releases. O espelho `neurama-organizacao/imfxtech-chat` tem o mesmo código, mas nunca rodou release e não tem secrets. Rodar o workflow nele não publica nada. No clone local, `origin` aponta para o espelho neurama. Por isso todo comando `gh` deste arquivo leva `-R marcelofmatos/imfxtech-chat`.
- Nunca abra PR ou issue em `krille-chan/fluffychat` (upstream).

## Fonte da verdade

| Assunto | Fonte da verdade |
|---|---|
| Publicação (todas as plataformas) | `.github/workflows/release-and-build.yml` |
| Versão e build number | `scripts/bump_version.py`, chamado só pelo workflow |
| Versão atual | linha `version:` do `pubspec.yaml` (formato `X.Y.Z+B`) |
| Checagens de PR | `.github/workflows/integrate.yaml` |
| Notarização do DMG | `scripts/notarize-dmg.sh` |
| Notas de versão | `--generate-notes` da GitHub Release (não o `CHANGELOG.md`) |

Se um doc contradizer o workflow, vale o workflow. Avise a divergência no PR.

## Regras de PR

- Branch `tipo/slug` (ex.: `fix/notificacao-ios`, `ci/notarize-retry`, `docs/agents-md-publicacao`).
- Commits em Conventional Commits, descrição em português (`fix(macos): ...`, `ci(android): ...`, `docs: ...`). O CI checa o formato com `webiny/action-conventional-commits`.
- PR contra `main` de `marcelofmatos/imfxtech-chat`. Merge só por humano. O PR precisa passar no "Pull Request Workflow" (`integrate.yaml`), que não usa secrets.
- Antes de abrir o PR, rode localmente o que se aplica à mudança. Comandos tirados do job `code_tests` (o job tem mais checagens; na dúvida, leia o YAML):

```bash
reuse lint                                   # licença/SPDX (o CI usa fsfe/reuse-action)
./scripts/generate-locale-config.sh && git diff --exit-code
flutter pub get && git diff --exit-code pubspec.lock
dart format lib/ test/ --set-exit-if-changed
flutter analyze
flutter test
dart run dart_code_linter:metrics analyze lib --reporter=github
dart run dart_code_linter:metrics check-unused-code lib
dart run dart_code_linter:metrics check-unused-files lib
dart run dart_code_linter:metrics check-unused-l10n lib
dart run license_checker check-licenses -c licenses.yaml --problematic
```

- Arquivo novo precisa de cabeçalho SPDX. Para arquivo IMFX: `SPDX-FileCopyrightText: 2026 IMFX TECH LTDA` e `SPDX-License-Identifier: AGPL-3.0-or-later` (modelo em `docs/MACOS_RELEASE.md` ou `scripts/bump_version.py`). As pastas `android/`, `ios/`, `macos/`, `.github/` e outras já são cobertas pelo `REUSE.toml`.
- PR não altera a linha `version:` do `pubspec.yaml` nem o `snap/snapcraft.yaml`, e não cria tag. Sem segredo, dado de cliente ou dado pessoal em código, commit, PR ou issue.

## Automação de versão

- `python3 scripts/bump_version.py <patch|minor|major>` lê `version: X.Y.Z+B` do `pubspec.yaml`, sobe X, Y ou Z, soma 1 ao build number `B` sempre, grava o `pubspec.yaml` e a primeira linha `version:` do `snap/snapcraft.yaml` e imprime `X.Y.Z`. Não cria commit nem tag e não mexe no CHANGELOG.
- Quem chama é o job `bump-version` do workflow. Ele commita como `github-actions[bot]` com a mensagem `chore: bump version to X.Y.Z`, cria a tag `vX.Y.Z` e faz push da `main` e da tag.
- O build number `B` vira o `versionCode` do Android (via `flutter.versionCode` em `android/app/build.gradle.kts`) e o build do iOS e do macOS. As lojas rejeitam build number repetido. Por isso:
  - Nunca rode o script à mão para commitar. Nunca edite `version:` à mão. Nunca crie tag `v*` à mão. Nunca diminua nem reaproveite build number.
  - O comentário no topo do `pubspec.yaml` ("please also increase build number...") é herança do upstream. O script já faz isso.
- Qual bump escolher (decide o humano; o agente pode sugerir):
  - `patch`: só correções desde a última release.
  - `minor`: tem pelo menos uma feature nova (`feat:`), mesmo pequena.
  - `major`: só com pedido explícito do Marcelo.
- Para ver o que entra na próxima versão: `git fetch <remote> --tags` e `git log --oneline v1.1.6..<remote>/main`, onde `<remote>` é o remote que aponta para `marcelofmatos/imfxtech-chat` (troque `v1.1.6` pela última tag IMFxTech).

## Como publicar (só com pedido explícito de humano)

- Único caminho: workflow "Release and Build" (`.github/workflows/release-and-build.yml`), gatilho `workflow_dispatch`, input `bump` (`patch`, `minor` ou `major`; padrão `patch`). Pela interface: Actions → Release and Build → Run workflow → branch `main` → escolher `bump`.
- Pré-condições: o que vai sair já está mergeado na `main`; o último "Pull Request Workflow" da `main` está verde; não há outro run do "Release and Build" em andamento (o `concurrency` enfileira, não cancela).
- Pela CLI:

```bash
gh workflow run release-and-build.yml -R marcelofmatos/imfxtech-chat --ref main -f bump=patch
```

- Sempre `--ref main`. O job `bump-version` faz `git push origin HEAD:main`: disparado de outra branch, empurraria código não revisado para a `main` ou falharia.

## O que cada job faz e para onde vai

| Job | Resultado | Destino |
|---|---|---|
| `bump-version` | commit `chore: bump version to X.Y.Z` e tag `vX.Y.Z` | `main` e tags do repo |
| `build-android` | APK assinado (vai para a Release) e AAB (só artefato do run) | Google Play, faixa `internal`, status `vars.PLAY_RELEASE_STATUS` ou `draft` se a variável não existir. Só sobe se `PLAY_STORE_JSON_KEY` existir. O step tem `continue-on-error`: falha vira só aviso |
| `build-ios` | IPA assinado (runner `macos-26-intel`) | TestFlight via `xcrun altool --upload-app --type ios`. Sem os secrets de iOS, gera IPA `-unsigned` e não envia |
| `build-macos` | DMG arm64 assinado com Developer ID e notarizado (`scripts/notarize-dmg.sh`). Sem os secrets de macOS, sai sem assinatura e com aviso | GitHub Release. Falha aqui não bloqueia a Release, ela sai sem o DMG |
| `build-macos-store` | `.pkg` assinado | App Store Connect (Mac App Store) via `xcrun altool --upload-app --type macos`. Fica fora da Release e não bloqueia nada. Sem os secrets, pula os passos e deixa aviso |
| `create-release` | `gh release create vX.Y.Z`, título "IMFxTech Chat X.Y.Z", APK, IPA e DMG (se o macOS passou), notas automáticas | GitHub Releases de `marcelofmatos/imfxtech-chat`. Só roda se bump, Android e iOS passaram |

- Não publica Windows, Linux, Snap, Docker, Web nem F-Droid. Nada usa fastlane.
- TestFlight e App Store Connect: o upload só entrega o build. Mandar para revisão da Apple e liberar para usuários é passo humano no App Store Connect.
- Google Play: a API só aceita upload depois que o primeiro AAB foi enviado à mão no Play Console. Enquanto o app não estiver publicado na Play, o status tem que ser `draft`. Trocar a variável `PLAY_RELEASE_STATUS` para `completed` é decisão humana.

## Acompanhar e conferir o resultado

```bash
gh run list -R marcelofmatos/imfxtech-chat --workflow release-and-build.yml -L 5
gh run watch <run-id> -R marcelofmatos/imfxtech-chat
gh run view <run-id> -R marcelofmatos/imfxtech-chat            # resumo e anotações (warnings)
gh run view <run-id> -R marcelofmatos/imfxtech-chat --log-failed
gh release view vX.Y.Z -R marcelofmatos/imfxtech-chat           # assets e notas
gh release list -R marcelofmatos/imfxtech-chat -L 5
```

A publicação está concluída quando:

1. Todos os jobs ficaram verdes, ou o que falhou foi só macOS e isso foi reportado.
2. A tag `vX.Y.Z` existe e a `main` tem o commit `chore: bump version to X.Y.Z`.
3. A Release tem `imfxtech-chat-X.Y.Z.apk`, o `.ipa` (assinado, sem `-unsigned`) e, se o macOS passou, `imfxtech-chat-X.Y.Z-macos.dmg`.
4. O `gh run view` não mostra o aviso `Google Play` ("Upload to Google Play failed"). Se mostrar, a Play não recebeu a versão, mesmo com o run verde. Reporte.
5. O job `build-macos-store` terminou com o step "Upload to App Store Connect" executado (não pulado).
6. O humano recebeu o relato: versão, link do run, link da Release, o que foi para cada loja e o que ficou pendente (revisão Apple, Play).

## Secrets e variáveis

- Ficam em Settings → Secrets and variables → Actions de `marcelofmatos/imfxtech-chat`. Não existem no espelho neurama.
- Android: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `PLAY_STORE_JSON_KEY`.
- Apple (API do App Store Connect, usada por iOS e macOS): `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`.
- iOS: `IOS_CERTIFICATE_P12_BASE64`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_APP_BASE64`, `IOS_PROVISIONING_PROFILE_SHARE_BASE64`, `IOS_PROVISIONING_PROFILE_NOTIFICATION_BASE64`, `IOS_TEAM_ID`.
- macOS DMG: `MACOS_CERTIFICATE_P12_BASE64`, `MACOS_CERTIFICATE_PASSWORD`. Mac App Store: `MACOS_APPSTORE_CERTIFICATE_P12_BASE64`, `MACOS_APPSTORE_CERTIFICATE_PASSWORD`, `MACOS_INSTALLER_CERTIFICATE_P12_BASE64`, `MACOS_INSTALLER_CERTIFICATE_PASSWORD`, `MACOS_PROVISIONING_PROFILE_STORE_BASE64`.
- Variável (não secret): `PLAY_RELEASE_STATUS`. Hoje não está definida, logo o status é `draft`.
- Nunca leia, imprima, decodifique, copie ou peça valor de secret. Nem em log de debug, nem para "testar".
- Não crie, troque ou apague secret ou variável. Se faltar ou expirar, diga qual nome e peça ao humano. Não adicione `echo`, `set -x` ou `cat` de arquivo de assinatura em workflow.
- Arquivos gerados no CI (`android/key.properties`, `android/app/imfxtech-chat-release.keystore`, `ios/ExportOptions.plist`, `.p12`, `.mobileprovision`, `.p8`) nunca vão para commit.

## Não use (órfãos do upstream)

Estes arquivos existem, mas nenhum workflow chama. Não use para publicar, não "conserte" para usar e não tome como referência de como o release funciona:

- `android/fastlane/` (`Fastfile`, `Appfile`) e `ios/fastlane/`.
- `fastlane/metadata`, symlink para `android/fastlane/metadata`, usado pelo F-Droid do upstream. Se alguém rodar o `supply` do fastlane com esse metadata, ele sobrescreve a ficha da Play com textos e imagens antigos.
- `scripts/release-ios-testflight.sh`, `scripts/build-ios.sh`, `scripts/build-macos.sh` (IDs `im.fluffychat`), `scripts/build-windows.ps1`, `scripts/prepare-android-release.sh`.
- `snap/snapcraft.yaml`, ainda com a marca FluffyChat (só a linha `version:` é mantida pelo bump). O `Dockerfile` é do upstream e não é publicado.
- `.github/workflows/main_deploy.yaml` e `.github/workflows/matrix_notify.yaml`: dependem de secrets que não existem em `marcelofmatos/imfxtech-chat`.

## Armadilhas conhecidas

- Run verde não garante Play. Na v1.1.6 a Play respondeu "The app is suspended." e o upload falhou. Por causa do `continue-on-error`, o run ficou verde e só deixou um warning. Sempre leia os warnings do run.
- O repo tem cerca de 200 tags herdadas do upstream (`v1.2x`, `v2.x`), e `git tag | tail` mostra versões que não são do IMFxTech. Use `gh release list -R marcelofmatos/imfxtech-chat` ou `git tag -l 'v1.1.*'` (ajuste ao major/minor atual).
- O `CHANGELOG.md` é do upstream (v2.9.x) e não tem entradas do IMFxTech. Não edite para release e não use como fonte. `README.md` e `CONTRIBUTING.md` são do upstream e não descrevem o release do IMFxTech.
- O cabeçalho do `release-and-build.yml` cita `docs/GOOGLE_PLAY_PUBLISHING.md`, que não existe.
- Depois do bump, a tag e o commit já estão na `main`. Se um build falhar depois disso, não dispare um novo run para "consertar" sem falar com o humano: um novo run gera outra versão. Reexecutar só os jobs falhos (`gh run rerun <run-id> --failed`) reaproveita a mesma tag, mas pode reenviar um build number que a loja já recebeu. Decisão humana.
- O build da Apple precisa do SDK do iOS 26, por isso o runner `macos-26-intel`. Não troque o runner sem motivo.
- A primeira notarização de um Developer ID novo pode levar horas. O script espera até 90 min; depois disso, o ID da submission sai no log.

## Quando falhar

- Diagnostique pelo `--log-failed`, explique a causa e reporte. Se for código ou workflow, proponha a correção em PR.
- Nunca contorne desligando assinatura, removendo upload, trocando `draft` por outro status, tirando `continue-on-error` de um lado e pondo em outro, ou pulando job.
- Se a causa for conta, certificado, perfil ou secret (expirado, suspenso, revogado), pare e avise o humano.

## Exige aprovação humana explícita

- Disparar o "Release and Build" (e escolher `patch`, `minor` ou `major`).
- Reexecutar jobs de um run de release.
- Criar, editar ou apagar release, tag, secret ou variável.
- Mudar `PLAY_RELEASE_STATUS`, a faixa da Play, o runner Apple ou qualquer passo de assinatura ou upload no `release-and-build.yml`.
- Qualquer ação no Play Console ou no App Store Connect (envio para revisão, liberação, ficha da loja).
- Mergear PR.

O agente nunca faz, mesmo com pedido vago:

- Rodar fastlane, `xcrun altool`, `notarytool` ou upload para lojas da própria máquina.
- `gh release create`, `git tag v*` ou `git push --tags` manuais.
- Apagar tag ou release, inclusive as herdadas do upstream.
- Force-push na `main`.

## Docs: quando ler

| Doc | Leia quando |
|---|---|
| `docs/ARQUITETURA-PUBLICACAO-IOS.md` | For mexer no job `build-ios`, nos perfis, nos bundles da extensão ou no upload ao TestFlight. Está atual. |
| `docs/MACOS_RELEASE.md` | For mexer no DMG, no Developer ID ou na notarização. A parte que diz que a Mac App Store não está implementada está desatualizada. |
| `docs/MACOS_APPSTORE_RELEASE.md` | For mexer no job `build-macos-store`. |
| `docs/IOS_RELEASE_SIGNING.md` | Só como histórico de como os secrets do iOS foram gerados. Está desatualizado: diz que não há secrets e que o upload é por fastlane. |
