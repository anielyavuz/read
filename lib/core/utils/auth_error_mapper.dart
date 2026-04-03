import '../../l10n/generated/app_localizations.dart';

String mapAuthError(String code, AppLocalizations l10n) {
  switch (code) {
    case 'invalid-email':
      return l10n.errorInvalidEmail;
    case 'weak-password':
      return l10n.errorWeakPassword;
    case 'email-already-in-use':
      return l10n.errorEmailAlreadyInUse;
    case 'user-not-found':
      return l10n.errorUserNotFound;
    case 'wrong-password':
    case 'invalid-credential':
      return l10n.errorWrongPassword;
    case 'too-many-requests':
      return l10n.errorTooManyRequests;
    case 'network-request-failed':
      return l10n.errorNetworkRequestFailed;
    default:
      return l10n.errorGeneric;
  }
}
