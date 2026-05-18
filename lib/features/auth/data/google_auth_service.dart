import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';

class GoogleAuthCredential {
  final String? idToken;
  final String? accessToken;

  const GoogleAuthCredential({this.idToken, this.accessToken});

  bool get hasAnyToken {
    return (idToken != null && idToken!.isNotEmpty) ||
        (accessToken != null && accessToken!.isNotEmpty);
  }
}

class GoogleAuthService {
  GoogleAuthService()
    : _googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? AppConfig.googleClientId : null,
        serverClientId: kIsWeb ? null : AppConfig.googleClientId,
        scopes: const ['openid', 'email', 'profile'],
      );

  final GoogleSignIn _googleSignIn;

  Future<GoogleAuthCredential> getGoogleCredential() async {
    try {
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();

      if (account == null) {
        throw Exception('Bạn đã hủy đăng nhập Google.');
      }

      final authentication = await account.authentication;

      final credential = GoogleAuthCredential(
        idToken: authentication.idToken,
        accessToken: authentication.accessToken,
      );

      if (!credential.hasAnyToken) {
        throw Exception(
          'Google không trả về idToken hoặc accessToken. Hãy kiểm tra OAuth Client ID và Authorized JavaScript origins.',
        );
      }

      return credential;
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
