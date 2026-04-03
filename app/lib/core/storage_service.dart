// app/lib/core/storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _privateKeyKey = "private_key";
  static const _addressKey = "wallet_address";
  static const _encryptionKeyKey = "encryption_key";

  // 🔐 GET OR CREATE ENCRYPTION KEY
  static Future<encrypt.Key> _getEncryptionKey() async {
    String? key = await _storage.read(key: _encryptionKeyKey);

    if (key == null) {
      final newKey = encrypt.Key.fromSecureRandom(32);
      await _storage.write(
        key: _encryptionKeyKey,
        value: base64Encode(newKey.bytes),
      );
      return newKey;
    }

    return encrypt.Key.fromBase64(key);
  }

  // 🔐 ENCRYPT PRIVATE KEY
  static Future<void> savePrivateKey(String privateKey) async {
    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(privateKey, iv: iv);

    final combined = {
      "iv": iv.base64,
      "data": encrypted.base64,
    };

    await _storage.write(
      key: _privateKeyKey,
      value: jsonEncode(combined),
    );
  }

  // 🔐 DECRYPT PRIVATE KEY
  static Future<String?> getPrivateKey() async {
    final stored = await _storage.read(key: _privateKeyKey);

    if (stored == null) return null;

    final json = jsonDecode(stored);

    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromBase64(json["iv"]);
    final encryptedData = json["data"];

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final decrypted = encrypter.decrypt64(encryptedData, iv: iv);

    return decrypted;
  }

  // 📍 ADDRESS (no need encryption)
  static Future<void> saveAddress(String address) async {
    await _storage.write(key: _addressKey, value: address);
  }

  static Future<String?> getAddress() async {
    return await _storage.read(key: _addressKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}