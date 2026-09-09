// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:ui';

abstract class AppConfig {
  static const Color primaryColor = Color(0xFFD8A954);

  static const Color chatColor = primaryColor;
  static const double messageFontSize = 16.0;
  static const bool allowOtherHomeservers = true;
  static const bool enableRegistration = true;
  static const bool hideTypingUsernames = false;

  static const String inviteLinkPrefix = 'https://matrix.to/#/';
  static const String deepLinkPrefix = 'com.imfxtech.chat://chat/';
  static const String schemePrefix = 'matrix:';
  static const String pushNotificationsChannelId = 'imfxtech_chat_push';
  static const String pushNotificationsAppId = 'com.imfxtech.chat';
  static const double borderRadius = 18.0;
  static const double spaceBorderRadius = 11.0;
  static const double columnWidth = 360.0;

  static const String enablePushTutorial =
      'https://ko-fi.com/post/How-can-I-get-Push-Notifications-without-Google-N7Q825URG6?fromEditor=true';
  static const String encryptionTutorial =
      'https://ko-fi.com/post/How-to-use-end-to-end-encryption-in-FluffyChat-A5O725WDR5';
  static const String howDoIGetStickersTutorial =
      'https://ko-fi.com/post/How-to-add-a-sticker-pack-to-FluffyChat-N4N01OXATI';
  static const String appId = 'com.imfxtech.chat.IMFxTechChat';
  static const String appOpenUrlScheme = 'com.imfxtech.chat';
  static const String appSsoUrlScheme = 'com.imfxtech.chat.auth';

  static const String sourceCodeUrl =
      'https://github.com/marcelofmatos/imfxtech-chat';
  static const String supportUrl =
      'https://github.com/marcelofmatos/imfxtech-chat/issues';
  static const String changelogUrl =
      'https://github.com/marcelofmatos/imfxtech-chat/blob/main/CHANGELOG.md';

  static const Set<String> defaultReactions = {'👍', '❤️', '😂', '😮', '😢'};

  static final Uri newIssueUrl = Uri(
    scheme: 'https',
    host: 'github.com',
    path: '/marcelofmatos/imfxtech-chat/issues/new',
  );

  static final Uri homeserverList = Uri(
    scheme: 'https',
    host: 'raw.githubusercontent.com',
    path:
        'marcelofmatos/imfxtech-chat/refs/heads/main/recommended_homeservers.json',
  );

  static final Uri crashReportEndpoint = Uri(
    scheme: 'https',
    host: 'crash.fluffy.chat',
  );

  static const String mainIsolatePortName = 'main_isolate';
  static const String pushIsolatePortName = 'push_isolate';
  static const String pushHelperCrashReportKey = 'push_helper_crash_report';
}
