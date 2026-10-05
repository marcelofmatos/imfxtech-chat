# Arquitetura e fluxo — publicação do IMFxTech Chat no iOS (TestFlight)

Descreve o pipeline real que está funcionando: workflow `Release and Build`
(`.github/workflows/release-and-build.yml`), disparado manualmente, que gera a
versão, assina o app iOS, envia pro TestFlight e publica a release no GitHub.

## Arquitetura

```mermaid
flowchart LR
    dev["Maintainer<br/>workflow_dispatch"] --> gha
    subgraph gha["GitHub Actions"]
        bump["bump-version<br/>ubuntu-latest"]
        android["build-android<br/>ubuntu-latest"]
        ios["build-ios<br/>macos-latest"]
        rel["create-release<br/>ubuntu-latest"]
        bump --> android
        bump --> ios
        android --> rel
        ios --> rel
    end
    subgraph secrets["Repository secrets"]
        s_ios["IOS_CERTIFICATE_P12_BASE64<br/>IOS_CERTIFICATE_PASSWORD<br/>IOS_PROVISIONING_PROFILE_*_BASE64<br/>IOS_TEAM_ID"]
        s_asc["ASC_KEY_ID<br/>ASC_ISSUER_ID<br/>ASC_KEY_CONTENT"]
        s_and["ANDROID_KEYSTORE_*<br/>ANDROID_KEY_ALIAS"]
    end
    subgraph apple["Apple"]
        portal["developer.apple.com<br/>Certificados, App IDs, Profiles"]
        asc["App Store Connect<br/>TestFlight"]
    end
    ios -.-> s_ios
    ios -.-> s_asc
    android -.-> s_and
    ios -->|upload IPA| asc
    rel -->|gh release create| ghrel["GitHub Release<br/>APK + IPA"]
    portal -. "perfis e certificado<br/>gerados antes" .-> s_ios
```

## Fluxo do job `build-ios`

```mermaid
flowchart TD
    A["Checkout da tag vX.Y.Z"] --> B["flutter pub get + Rust"]
    B --> C{"Secrets iOS<br/>configurados?"}
    C -- não --> U1["flutter build ios --no-codesign"]
    U1 --> U2["Empacota Payload zip<br/>IPA sem assinatura"]
    C -- sim --> D["Importa .p12 num keychain temporário"]
    D --> E["Instala os 3 .mobileprovision<br/>em Provisioning Profiles"]
    E --> F["Gera ExportOptions.plist<br/>team, signingStyle manual, profiles"]
    F --> G["flutter build ipa --release<br/>archive com Apple Distribution"]
    G --> H["Renomeia para imfxtech-chat-VERSAO.ipa"]
    H --> I["xcrun altool --upload-app<br/>com a API key da App Store Connect"]
    I --> J["Build processado no TestFlight"]
    U2 --> K["upload-artifact"]
    J --> K
```

## Sequência completa (do disparo à instalação no aparelho)

```mermaid
sequenceDiagram
    autonumber
    participant M as Mantenedor
    participant GH as GitHub Actions
    participant AP as Portal Apple Developer
    participant ASC as App Store Connect
    participant TF as TestFlight
    participant D as Aparelho de teste

    rect rgb(235, 245, 255)
    note over M,AP: Preparação única (manual)
    M->>AP: Aceita convite e confirma papel Admin ou App Manager
    M->>AP: Cria CSR com OpenSSL e gera certificado Apple Distribution
    M->>AP: Registra App IDs com.imfxtech.chat, .Share e .NotificationService
    M->>AP: Cria 3 provisioning profiles App Store
    M->>GH: Salva .p12, perfis, Team ID e API key como secrets
    end

    rect rgb(240, 255, 240)
    note over M,GH: Execução (repetível)
    M->>GH: workflow_dispatch com bump patch, minor ou major
    GH->>GH: bump-version grava nova versao no pubspec e snapcraft
    GH->>GH: commit de bump na main e tag vX.Y.Z
    GH->>GH: build-android em paralelo gera APK assinado
    GH->>GH: build-ios importa certificado e perfis
    GH->>GH: flutter build ipa com assinatura manual
    GH->>ASC: altool envia IPA com a API key
    ASC->>TF: Build processado e disponivel no TestFlight
    GH->>GH: create-release publica APK e IPA como GitHub Release
    end

    rect rgb(255, 250, 235)
    note over M,D: Teste
    M->>TF: Convida testadores e envia o build
    TF->>D: Instala o app pelo TestFlight
    end
```

## Onde cada coisa está no repositório

| Peça | Arquivo |
|---|---|
| Pipeline | `.github/workflows/release-and-build.yml` |
| Versão | `scripts/bump_version.py`, `pubspec.yaml`, `snap/snapcraft.yaml` |
| Assinatura Xcode (Release) | `ios/Runner.xcodeproj/project.pbxproj` (manual, team `Q9FX293J5N`, perfis por target) |
| Entitlements | `ios/Runner/Runner.entitlements`, `ios/FluffyChat Share/*.entitlements`, `ios/Notification Service Extension/*.entitlements` |
| Passo a passo do Apple Developer | `docs/IOS_RELEASE_SIGNING.md` |
| Fastlane (não é mais usado no upload) | `ios/fastlane/Fastfile` |

## Pontos de atenção

- **Entitlements:** o perfil do app principal não inclui Push Notifications nem
  Associated Domains. Por isso ambos foram removidos de `Runner.entitlements`.
  Só voltam quando o App ID tiver essas capabilities e o perfil for regenerado.
- **Versões sem release:** execuções que falham depois do bump deixam a tag e o
  commit de versão sem release publicada (1.0.4, 1.0.5 e 1.0.6 ficaram assim).
- **Validade:** os perfis e o certificado vencem em 2027-10-03. Quando vencerem,
  é preciso gerar de novo e atualizar os secrets.
- **Conta:** os perfis foram criados no team `Q9FX293J5N`, de uma conta de
  pessoa física. Confirmar se é essa a conta que vai publicar o app da IMFxTech.
