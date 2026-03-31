import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> savePrivateKey(String key) async {
    await _storage.write(key: "private_key", value: key);
  }

  static Future<String?> getPrivateKey() async {
    return await _storage.read(key: "private_key");
  }

  static Future<void> saveAddress(String address) async {
    await _storage.write(key: "wallet_address", value: address);
  }

  static Future<String?> getAddress() async {
    return await _storage.read(key: "wallet_address");
  }
}