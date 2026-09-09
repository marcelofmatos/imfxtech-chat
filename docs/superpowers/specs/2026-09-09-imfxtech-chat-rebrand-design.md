# Rebranding para IMFxTech Chat — Spec

Data: 2026-09-09
Status: aprovado pelo usuário, pronto para plano de implementação

## Contexto

Este repositório é um fork do [FluffyChat](https://fluffy.chat) (cliente Matrix em
Flutter). O objetivo é rebrandear o app para "IMFxTech Chat", publicável nas lojas
(Google Play e Apple App Store) com identidade visual própria, usando os ativos de
marca já entregues por um designer (pasta `~/HD3/botDon/branding/`, arquivos
`imfxtech-chat-*`). O checklist geral de publicação está em `TODO.md`; esta spec
cobre apenas a fatia de código do rebranding (itens 1–7 do `TODO.md`), restrita a
Android e iOS.

Modelo de produto relevante para decisões abaixo: a IMFxTech oferece este app pra
múltiplos clientes B2B, cada um com seu próprio homeserver Matrix (ex.:
`chat.<cliente>.vps.imfxtech.com`, `chat.<cliente>.nhwgroup.com.br`). Não existe um
homeserver padrão único — o app precisa continuar permitindo que o usuário digite o
endereço do servidor dele no login.

## Decisões de identidade

- **Nome exibido**: "IMFxTech Chat" (launcher, App Store, Play, notificações)
- **Application ID / Bundle ID**: `com.imfxtech.chat`
- **Plataformas nesta rodada**: Android e iOS apenas (macOS/Linux/Windows/Snap ficam
  de fora, sem mudanças)
- **Homeserver padrão**: nenhum fixo. `presetHomeserver` continua vazio em
  `config.sample.json` — comportamento já é esse hoje, mantém-se
- **Paleta**: extraída dos ícones fornecidos — navy `#0B1622` (fundo) e dourado
  `#D8A954` (destaque/seed do Material You)

## Escopo

### Dentro do escopo
- Nome exibido, `applicationId`/bundle ID e pacote Kotlin
- Ícones do launcher (Android adaptativo + legado) e App Icon (iOS), gerados a
  partir dos 3 PNGs em `branding/`
- Cor de tema (seed do Material You)
- Identificadores internos ligados à marca antiga: App Group, esquema de URL
  customizado, `appId` de sessão Matrix, namespaces internos `im.fluffychat.*`
  (decisão do usuário: trocar tudo, apesar do custo/risco maior que o mínimo)
- Textos visíveis ao usuário que mencionam "FluffyChat", **restrito a inglês
  (`intl_en.arb`) e português (`intl_pt_PT.arb`, `intl_pt_BR.arb`)**
- `config.sample.json`, `PRIVACY.md`, links institucionais em `app_config.dart`
- Gerar um APK de debug ao final, para teste manual

### Fora do escopo (fica registrado no `TODO.md`)
- macOS, Linux, Windows, Snap
- Contas Apple Developer / Google Play, certificados, keystores de release
- Firebase/APNs próprios (o `GoogleService-Info.plist` do iOS continua sendo o do
  FluffyChat original — mismatch de bundle ID, push não funcional até criar projeto
  próprio; não bloqueia build/ícone/nome)
- Feature graphic da Play Store e demais artes de listagem de loja (uploads
  separados no Console, não vivem no repo)
- Nome do pacote Dart (`pubspec.yaml` → `name: fluffychat`) e os ~953 imports
  `package:fluffychat/...` em 194 arquivos — identificador 100% interno do Flutter,
  invisível pro usuário e pras lojas; trocar custaria um diff enorme por zero
  ganho externo
- Classes/funções internas com "FluffyChat" no nome (`FluffyChatApp`,
  `FluffyChatPushPayload`, `buildFluffyChatCallKitParams`, arquivos
  `fluffy_chat_app.dart`/`fluffy_share.dart`/`fluffy_chat_tester.dart`) — mesma
  lógica: cosmético, interno, sem benefício visível
- Textos traduzidos com "FluffyChat" nos outros 55 idiomas além de inglês/português
  (comunidade traduz via Weblate; fora do nosso escopo)
- Créditos/atribuição ao FluffyChat na tela "Sobre" (licenças open-source) —
  **mantém-se de propósito**, inclusive por exigência da licença AGPL-3.0

## Identificadores — de/para

| Onde | De | Para |
|---|---|---|
| `android/app/build.gradle.kts` → `namespace`/`applicationId` | `chat.fluffy.fluffychat` | `com.imfxtech.chat` |
| Pacote Kotlin (`MainActivity.kt`, `FcmPushService.kt`) | `chat/fluffy/fluffychat/` | `com/imfxtech/chat/` |
| `AndroidManifest.xml` → `android:label` | `FluffyChat` | `IMFxTech Chat` |
| `AndroidManifest.xml` → esquema dos 2 `intent-filter` (deep link + SSO) | `im.fluffychat`, `im.fluffychat.auth` | `com.imfxtech.chat`, `com.imfxtech.chat.auth` |
| `ios/Runner/Info.plist` → `CFBundleDisplayName` / `CFBundleName` | `FluffyChat` / `fluffychat` | `IMFxTech Chat` / `IMFxTechChat` |
| `ios/Runner/Info.plist` → `CFBundleURLSchemes` | `im.fluffychat` | `com.imfxtech.chat` |
| `project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER` (app principal, 3 build configs) | `im.fluffychat.app` | `com.imfxtech.chat` |
| `project.pbxproj` → target Share (3 build configs) | `im.fluffychat.app.FluffyChat-Share` | `com.imfxtech.chat.Share` |
| `project.pbxproj` → target Notification Service (3 build configs) | `im.fluffychat.app.Notification-Service-Extension` | `com.imfxtech.chat.NotificationService` |
| 3x `.entitlements` (Runner, Share, Notification Service) → App Group | `group.im.fluffychat.app` | `group.com.imfxtech.chat` |
| `builder.dart:57,173` e `cipher.dart:23` → `appGroupIdentifier`/`groupId` | `group.im.fluffychat.app` | `group.com.imfxtech.chat` |
| `app_config.dart` → `deepLinkPrefix` | `im.fluffychat://chat/` | `com.imfxtech.chat://chat/` |
| `app_config.dart` → `appOpenUrlScheme` / `appSsoUrlScheme` | `im.fluffychat` / `im.fluffychat.auth` | `com.imfxtech.chat` / `com.imfxtech.chat.auth` |
| `app_config.dart` → `appId` (aparece na lista de sessões de outros clientes Matrix) | `im.fluffychat.FluffyChat` | `com.imfxtech.chat.IMFxTechChat` |
| `app_config.dart` → `pushNotificationsChannelId` / `pushNotificationsAppId` | `fluffychat_push` / `chat.fluffy.fluffychat` | `imfxtech_chat_push` / `com.imfxtech.chat` |
| `event_checkbox_extension.dart:9` | `im.fluffychat.checkboxes` | `com.imfxtech.chat.checkboxes` |
| `client_manager.dart:25` | `im.fluffychat.store.clients` | `com.imfxtech.chat.store.clients` |
| `account_config.dart:9` | `im.fluffychat.account_config` | `com.imfxtech.chat.account_config` |
| `account_bundles.dart:51` | `im.fluffychat.account_bundles` | `com.imfxtech.chat.account_bundles` |
| `chat_list.dart:192` | `im.fluffychat.search.server` | `com.imfxtech.chat.search.server` |
| `fluffy_share.dart:49` → parâmetro `client=` do link matrix.to | `client=im.fluffychat` | `client=com.imfxtech.chat` |
| `fluffy_chat_app.dart:51` → esquema de recebimento de mídia compartilhada | `sharemedia-im.fluffychat.app` | `sharemedia-com.imfxtech.chat` |

**Não mexe** (decisão explícita, ver "Fora do escopo"): `pubspec.yaml` (`name`,
`description`), nomes de classe/função/arquivo Dart com "FluffyChat", pastas
internas dos targets Xcode (`FluffyChat Share`, `Notification Service Extension` —
só o bundle ID muda, não o nome da pasta/target).

## Ícones

Fontes em `branding/` (já preparadas por um designer, recorte de zona segura já
feito):
- `imfxtech-chat-icone-apple-appstore-1024.png` — full-bleed, sem alpha
- `imfxtech-chat-icone-android-recentrado-1024.png` — recentrado na zona segura, sem alpha
- `imfxtech-chat-icone-android-adaptativo-frente-1024.png` — camada de frente, com alpha

Um script Python (Pillow) gera os arquivos finais a partir dessas 3 fontes — sem
adicionar dependências novas ao `pubspec.yaml` (ex.: `flutter_launcher_icons`), pra
não reprocessar o recorte de zona segura que o designer já fez.

| Destino | Fonte | Tamanhos |
|---|---|---|
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (20 arquivos) | ícone Apple 1024 | todos os do `Contents.json` atual |
| `android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` | ícone Android recentrado 1024 | 48/72/96/144/192px |
| `android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/ic_launcher_foreground.png` | camada de frente (alpha) | 108/162/216/324/432px |
| `android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/ic_launcher_monochrome.png` (ícone temático Android 13+) | silhueta branca extraída do alpha da camada de frente | mesmas 5 resoluções |

Mudanças de estrutura junto:
- `android/app/src/main/res/values/ic_launcher_background.xml` → cor muda pra
  `#0B1622`; `mipmap-anydpi-v26/ic_launcher.xml` passa a referenciar
  `@color/ic_launcher_background` em vez de `@drawable/ic_launcher_background`
  (elimina as 5 PNGs de fundo — o novo ícone é flat, não tem o gradiente do
  original, então uma cor sólida já é fiel ao design)
- Deleta os 5 `drawable-*/ic_launcher_background.png` (substituídos pela cor) e os
  vetores mortos `drawable/ic_launcher_foreground.xml` e
  `drawable/ic_launcher_monochrome.xml` (desenho do "paw" antigo do FluffyChat —
  já ficavam sem uso com as 5 densidades de PNG presentes, e agora representam o
  ícone errado)

## Cor / tema

- `lib/config/app_config.dart` → `primaryColor` (semente real do Material You do
  app hoje): `Color(0xFF261386)` → `Color(0xFFD8A954)`
- `config.sample.json` → `colorSchemeSeedInt` (override opcional via MDM):
  `4283835834` → `4292389204` (mesma cor `0xFFD8A954` em decimal)

## Config, privacidade e links institucionais

- `config.sample.json` → `applicationName: "IMFxTech Chat"`
- `PRIVACY.md` → texto explícito (não um "TBD" vago): nota curta dizendo que a
  política de privacidade própria da IMFxTech está em elaboração, com link de
  referência à política original do FluffyChat enquanto isso (mantém a atribuição
  exigida pela AGPL)
- `app_config.dart` → `sourceCodeUrl`, `supportUrl`, `newIssueUrl` passam a apontar
  pro repositório `https://github.com/marcelofmatos/imfxtech-chat` (e
  `/issues`, `/issues/new`); `changelogUrl` aponta pro
  `https://github.com/marcelofmatos/imfxtech-chat/blob/main/CHANGELOG.md`;
  `homeserverList` passa a buscar
  `https://raw.githubusercontent.com/marcelofmatos/imfxtech-chat/refs/heads/main/recommended_homeservers.json`
  (mesmo conteúdo do arquivo já presente no repo, só para de depender do GitHub do
  FluffyChat em runtime)
- `enablePushTutorial`, `encryptionTutorial`, `howDoIGetStickersTutorial`: **sem
  mudança** — conteúdo educacional genérico sobre Matrix/E2E, e a AGPL exige manter
  atribuição ao projeto original de qualquer forma
- `crashReportEndpoint`: **sem mudança** — é uma constante morta (não referenciada
  em nenhum lugar do código), sem risco de vazar dado nenhum; não vale o esforço de
  editar pra um valor que nunca é lido

### Remoção do menu de doação

`client_chooser_button.dart` tem um item de menu "❤️ Support FluffyChat" que abre
`ko-fi.com/.../How-can-I-support-FluffyChat` — a página de doação pessoal do
criador do FluffyChat. Renomear o texto pra "Support IMFxTech Chat" mandaria a
doação pra pessoa errada. Decisão: **remover o item de menu** (`PopupMenuItem` do
`SettingsAction.support` e o `case` correspondente), já que a IMFxTech não tem uma
página de doação própria agora. A chave de tradução `supportFluffyChat` fica órfã
nos arquivos `.arb` (sem uso) — não vale editar os 59 idiomas só pra remover uma
chave morta.

## Textos visíveis (l10n) — apenas inglês e português

Restrito a `lib/l10n/intl_en.arb`, `intl_pt_PT.arb` e `intl_pt_BR.arb`
(`intl_pt.arb` não tem essas strings preenchidas, só metadados — sem ação).

| Chave | Mudança |
|---|---|
| `inviteText` | Troca "FluffyChat" pelo novo nome; remove a menção a "Visit fluffychat.im and install the app" (não existe site de distribuição próprio ainda) — fica só "install [nome]" genérico |
| `newMessageInFluffyChat` | "New message in FluffyChat" → "New message in IMFxTech Chat" (mesma troca nos 2 arquivos PT) |
| `signUpGreeting` | Troca "FluffyChat" pelo novo nome |
| `possibleByYou` | Reescreve levemente: remove a alegação "remains free, open-source, and entirely community-driven" (não se aplica ao modelo da IMFxTech) — vira um agradecimento genérico pela atualização |
| `newPassphraseDescription` | Troca "FluffyChat" pelo novo nome |
| `noGoogleServicesWarning` (só existe em `intl_pt_PT.arb`) | Troca "FluffyChat" pelo novo nome |

A chave `supportFluffyChat` **não** é editada (fica órfã, ver seção anterior).

## Verificação

1. `flutter analyze` + `flutter pub get` — garante que nada ficou quebrado pelas
   mudanças de identificador
2. Varredura `grep -ri "fluffychat"` restrita ao que decidimos mudar (arquivos
   nativos Android/iOS, `app_config.dart`, os 3 arquivos `.arb` tocados) — confirma
   que não sobrou nada esquecido dentro do escopo combinado
3. `flutter build apk --debug` — valida o novo `applicationId` e o pacote Kotlin
   movido; **este é o entregável final pedido pelo usuário para teste manual**
4. `flutter build ios --no-codesign` — valida o novo bundle ID e os
   `.entitlements` (sem certificado, só checa que o projeto compila)
5. Teste manual (quando houver dispositivo/emulador disponível): nome "IMFxTech
   Chat" no launcher, ícone correto nas máscaras circular/squircle, tela de login
   ainda aceita homeserver customizado, cor dourada aplicada, e principalmente
   testar o **compartilhamento de mídia pro app** (valida que o rename do App
   Group nos 6 lugares não quebrou a Share Extension no iOS)
