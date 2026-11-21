import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyStore {
  ApiKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // The data protection keychain needs the keychain-access-groups
              // entitlement, which needs a provisioning profile. Unsigned
              // GitHub builds don't have one, so use the legacy keychain.
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            );

  static const _openAiKey = 'openai_api_key';

  final FlutterSecureStorage _storage;

  Future<String?> readOpenAiKey() => _storage.read(key: _openAiKey);

  Future<void> writeOpenAiKey(String value) =>
      _storage.write(key: _openAiKey, value: value.trim());

  Future<void> deleteOpenAiKey() => _storage.delete(key: _openAiKey);
}
