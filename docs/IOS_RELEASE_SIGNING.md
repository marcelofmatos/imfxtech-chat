# Assinatura de release do iOS — processo e status

Este documento registra o que falta para o workflow `release-and-build.yml`
gerar um `.ipa` **assinado** (instalável em aparelho real / TestFlight), em vez
do build sem assinatura (`--no-codesign`) que ele gera hoje.

## Status atual (atualizado 2026-09-30)

- ✅ Bundle IDs do app já definidos: `com.imfxtech.chat` (app),
  `com.imfxtech.chat.Share` (extensão de compartilhamento),
  `com.imfxtech.chat.NotificationService` (extensão de notificação) — ver
  `docs/superpowers/specs/2026-09-09-imfxtech-chat-rebrand-design.md`.
- ✅ Convite da conta Apple Developer da IMFxTech (time "Don Silva Martins",
  Team ID `Q9FX293J5N`) aceito; papel de `marcelofmatos@gmail.com` no App
  Store Connect é **Administrador**.
- ✅ App já registrado no App Store Connect: nome "IMFxTech Chat", Bundle ID
  `com.imfxtech.chat`, SKU `imfxtech-chat`, Apple ID `6810974674`. Metadados
  (nome, subtítulo, categoria, descrição, palavras-chave, URL de suporte,
  URL e etiqueta de política de privacidade) preenchidos e publicados.
- ✅ `release-and-build.yml` (job `build-ios`) e `ios/fastlane/{Appfile,Fastfile}`
  já implementam o caminho assinado completo (importar `.p12`, instalar os 3
  `.mobileprovision`, gerar `ExportOptions.plist`, `flutter build ipa`, upload
  automático pro TestFlight via fastlane). Ele cai automaticamente para o
  build sem assinatura (`--no-codesign`) enquanto os secrets abaixo não
  existirem — nada quebra.
- ⏳ **Bloqueio atual**: `marcelofmatos@gmail.com` **não** tem acesso ao
  Developer Portal (Certificates, Identifiers & Profiles) do time "Don Silva
  Martins" — confirmado repetidamente entre 2026-09-26 e 2026-09-29, não é
  atraso de propagação. Ser Admin no App Store Connect não dá esse acesso
  automaticamente nesse time; é um sistema de papéis separado
  (developer.apple.com/account → People), que só o Team Agent
  (`dev@nhwgroup.com.br`) pode conceder. Sem isso não dá pra gerar o
  certificado de distribuição nem os App IDs/Provisioning Profiles dos
  próximos passos.
- ⏳ Certificado de distribuição, App IDs (com capabilities), Provisioning
  Profiles: nada disso existe ainda — depende do bloqueio acima.
- ⏳ Secrets do GitHub (passo 5): nenhum criado ainda.

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

### 5. Configuração no GitHub (eu faço) — workflow já pronto, só faltam os secrets

O job `build-ios` em `.github/workflows/release-and-build.yml` e
`ios/fastlane/{Appfile,Fastfile}` **já foram implementados** (2026-09-30):
importa o `.p12` numa keychain temporária do runner, instala os 3
`.mobileprovision` em `~/Library/MobileDevice/Provisioning Profiles/`, gera
um `ExportOptions.plist` com o Team ID, roda
`flutter build ipa --export-options-plist=...` (archive + export assinado,
em vez do hack de zipar `Payload/Runner.app` que só serve pra build sem
assinatura) e sobe pro TestFlight via `fastlane upload_testflight` usando uma
chave de API do App Store Connect. Tudo isso é condicional: se
`IOS_CERTIFICATE_P12_BASE64` não existir, o job cai automaticamente no build
sem assinatura de hoje — não quebra nada enquanto os secrets não existem.

Faltam só criar os *repository secrets* (mesmo padrão já usado pros do
Android — `ANDROID_KEYSTORE_BASE64` etc., ver
[imfxtech-chat-secrets-backup/README.md](file:///home/marcelo/HD3/botDon/imfxtech-chat-secrets-backup/README.md)):

- `IOS_CERTIFICATE_P12_BASE64` / `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_APP_BASE64`
- `IOS_PROVISIONING_PROFILE_SHARE_BASE64`
- `IOS_PROVISIONING_PROFILE_NOTIFICATION_BASE64`
- `IOS_TEAM_ID`
- `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_CONTENT` — chave de API do App
  Store Connect (não é a mesma coisa do certificado de distribuição; gerada
  em App Store Connect → Usuários e acesso → Integrações → App Store
  Connect API, papel **App Manager** ou superior — isso o Marcelo já tem
  acesso pra fazer, não depende do Developer Portal). `ASC_KEY_CONTENT` é o
  conteúdo do arquivo `.p8` baixado, codificado em base64
  (`base64 -w0 AuthKey_XXXX.p8`).

### 6. Teste

- Build assinado com profile **App Store**: sobe pro TestFlight
  automaticamente (lane `upload_testflight` do fastlane) e instala por lá.
- Pra instalar direto num aparelho de teste sem passar pelo TestFlight, seria
  preciso um profile **Ad Hoc** à parte (não implementado — não é o fluxo
  que o Marcelo pediu, que é "publicado pelo git actions").

## Referências

- Spec do rebrand (bundle IDs, App Group): `docs/superpowers/specs/2026-09-09-imfxtech-chat-rebrand-design.md`
- Workflow atual: `.github/workflows/release-and-build.yml`
- `TODO.md` (seção 9, contas e credenciais das lojas)
