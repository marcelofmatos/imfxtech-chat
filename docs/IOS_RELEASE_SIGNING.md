# Assinatura de release do iOS — processo e status

Este documento registra o que falta para o workflow `release-and-build.yml`
gerar um `.ipa` **assinado** (instalável em aparelho real / TestFlight), em vez
do build sem assinatura (`--no-codesign`) que ele gera hoje.

## Status atual

- ✅ Bundle IDs do app já definidos: `com.imfxtech.chat` (app),
  `com.imfxtech.chat.Share` (extensão de compartilhamento),
  `com.imfxtech.chat.NotificationService` (extensão de notificação) — ver
  `docs/superpowers/specs/2026-09-09-imfxtech-chat-rebrand-design.md`.
- ✅ `release-and-build.yml` já builda um `.ipa` sem assinatura em toda
  execução (job `build-ios`, roda em `macos-latest`), só pra validar que
  compila.
- ⏳ Conta Apple Developer da IMFxTech: convite recebido, ainda não aceito /
  papel no time ainda não confirmado.
- ⏳ Certificado de distribuição, App IDs, Provisioning Profiles: nada disso
  existe ainda.

## Passo a passo completo

### 1. Aceitar o convite e confirmar o papel (só você)

- Aceitar o convite recebido por e-mail (ou em
  [developer.apple.com/account](https://developer.apple.com/account), deve
  aparecer pendente).
- Confirmar em **Membership/People** que seu papel é **Admin** ou
  **App Manager** — só esses dois níveis conseguem gerar certificado de
  distribuição. Se só deram "Developer", pedir pra quem convidou subir o
  nível.
- Anotar o **Team ID** (aparece na página de Membership) — vai virar secret
  `IOS_TEAM_ID`.

### 2. Certificado de distribuição (eu + você)

Não precisa de Mac — dá pra gerar o CSR com OpenSSL direto daqui:

```bash
openssl genrsa -out ios_distribution.key 2048
openssl req -new -key ios_distribution.key -out ios_distribution.csr \
  -subj "/emailAddress=<email>/CN=<nome ou IMFxTech>/C=BR"
```

Preciso de **nome** e **e-mail** pra preencher o `-subj` antes de gerar.

Depois:
1. Sobe o `.csr` em developer.apple.com → **Certificates, Identifiers &
   Profiles** → **Certificates** → "+" → **Apple Distribution**.
2. Baixa o `.cer` gerado.
3. Eu converto `.cer` + `ios_distribution.key` num `.p12` protegido por senha:
   ```bash
   openssl x509 -in ios_distribution.cer -inform DER -out ios_distribution.pem -outform PEM
   openssl pkcs12 -export -inkey ios_distribution.key -in ios_distribution.pem \
     -out ios_distribution.p12 -password pass:<SENHA_FORTE>
   ```

### 3. Registrar os App IDs (você, no portal)

Em **Identifiers** → "+" → **App IDs**, um explícito pra cada bundle ID do
projeto:

| App ID | Capabilities a habilitar |
|---|---|
| `com.imfxtech.chat` | App Groups (`group.com.imfxtech.chat`), Push Notifications (quando tivermos APNs próprio) |
| `com.imfxtech.chat.Share` | App Groups |
| `com.imfxtech.chat.NotificationService` | App Groups, Push Notifications |

### 4. Provisioning Profiles (você, no portal)

Em **Profiles** → "+", um profile **por App ID** (3 no total), tipo:
- **App Store** — pra distribuição via TestFlight/App Store review, ou
- **Ad Hoc** — só instala em aparelhos cujo UDID esteja cadastrado no
  profile; útil pra testar antes de mandar pra revisão da Apple.

Cada profile usa o certificado de distribuição gerado no passo 2. Baixa os 3
arquivos `.mobileprovision`.

### 5. Configuração no GitHub (eu faço)

Novos *repository secrets* (mesmo padrão já usado pros do Android —
`ANDROID_KEYSTORE_BASE64` etc., ver
[imfxtech-chat-secrets-backup/README.md](file:///home/marcelo/HD3/botDon/imfxtech-chat-secrets-backup/README.md)):

- `IOS_CERTIFICATE_P12_BASE64` / `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_APP_BASE64`
- `IOS_PROVISIONING_PROFILE_SHARE_BASE64`
- `IOS_PROVISIONING_PROFILE_NOTIFICATION_BASE64`
- `IOS_TEAM_ID`

E troco o job `build-ios` em `.github/workflows/release-and-build.yml`: em vez
de `flutter build ios --release --no-codesign` + zipar o `.app` manualmente,
passa a:
1. Importar o `.p12` numa keychain temporária do runner.
2. Instalar os 3 `.mobileprovision` em
   `~/Library/MobileDevice/Provisioning Profiles/`.
3. Gerar um `ExportOptions.plist` com o Team ID e o método de export
   (`app-store` ou `ad-hoc`).
4. Rodar `flutter build ipa --export-options-plist=ExportOptions.plist`, que
   já faz archive + export assinado corretamente (diferente do hack atual de
   zipar `Payload/Runner.app`, que só serve pra build sem assinatura).

### 6. Teste

- Com profile **App Store**: sobe pro TestFlight (via `xcrun altool` ou
  `fastlane pilot`) e instala por lá.
- Com profile **Ad Hoc**: instala direto no aparelho cujo UDID está no
  profile (ex.: via um link de instalação OTA, ou Diawi).

## Referências

- Spec do rebrand (bundle IDs, App Group): `docs/superpowers/specs/2026-09-09-imfxtech-chat-rebrand-design.md`
- Workflow atual: `.github/workflows/release-and-build.yml`
- `TODO.md` (seção 9, contas e credenciais das lojas)
