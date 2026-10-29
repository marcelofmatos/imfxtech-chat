<!--
SPDX-FileCopyrightText: 2019-Present Christian Kußowski
SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Política de Privacidade — IMFxTech Chat

Última atualização: 29 de outubro de 2026

O IMFxTech Chat (pacote `com.imfxtech.chat`) é um cliente de mensagens para o
protocolo aberto [Matrix](https://matrix.org), publicado pela IMFX TECH LTDA.
Esta política explica quais dados o app trata e para quê.

## Resumo

- O app **não tem anúncios**, **não usa ferramentas de análise ou
  rastreamento** e **não vende nem compartilha** seus dados com terceiros
  para fins de publicidade.
- Suas mensagens e arquivos vão para o **servidor Matrix (homeserver) que
  você escolhe** ao entrar. É esse servidor que armazena sua conta e suas
  conversas.
- Conversas com criptografia de ponta a ponta só podem ser lidas pelos
  participantes, nem o servidor consegue lê-las.

## Dados tratados pelo app

| Dado | Quando | Para quê | Para onde vai |
|------|--------|----------|---------------|
| Identificador Matrix, nome de exibição, foto de perfil, e-mail/telefone (se você informar) | Login e cadastro | Criar e acessar sua conta | Seu homeserver |
| Mensagens, fotos, vídeos, áudios e arquivos | Quando você envia | Entregar a conversa | Seu homeserver (criptografado de ponta a ponta quando a sala usa criptografia) |
| Localização | Só quando você escolhe compartilhar a localização numa conversa | Enviar a localização à conversa | Seu homeserver |
| Câmera e microfone | Só quando você tira foto, grava vídeo/áudio ou entra numa chamada | Capturar a mídia que você vai enviar | Seu homeserver / servidor de chamadas |
| Token de notificação push (Firebase Cloud Messaging) | Ao ativar notificações | Avisar seu aparelho de novas mensagens | Google Firebase e seu homeserver (a notificação leva apenas identificadores do evento, não o conteúdo da mensagem) |

Todos os dados trafegam com criptografia (HTTPS/TLS).

## Dados armazenados no aparelho

O app guarda no seu aparelho, de forma local, o histórico em cache, as chaves
de criptografia e as preferências. Esses dados são apagados ao sair da conta
ou desinstalar o app.

## Exclusão de dados

Você pode desativar sua conta pelo próprio app (Configurações → Conta →
Desativar conta). A exclusão dos dados no servidor segue a política do
homeserver que você usa. Para contas no servidor da IMFxTech, peça a exclusão
pelo e-mail abaixo.

## Crianças

O app não é direcionado a menores de 13 anos.

## Contato

IMFX TECH LTDA — imfxtechdev@gmail.com

---

O IMFxTech Chat é baseado no FluffyChat, software livre licenciado sob a
AGPL-3.0.
