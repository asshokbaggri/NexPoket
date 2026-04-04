// app/lib/core/storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _walletsKey = "wallets";
  static const _selectedWalletKey = "selected_wallet";
  static const _selectedNetworkKey = "selected_network";
  static const _encryptionKeyKey = "encryption_key";

  // 🔐 GET / CREATE ENCRYPTION KEY
  static Future<encrypt.Key> _getEncryptionKey() async {
    try {
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
    } catch (e) {
      final newKey = encrypt.Key.fromSecureRandom(32);

      await _storage.write(
        key: _encryptionKeyKey,
        value: base64Encode(newKey.bytes),
      );

      return newKey;
    }
  }

  // 🔐 ENCRYPT DATA
  static Future<Map<String, String>> _encrypt(String data) async {
    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(data, iv: iv);

    return {
      "iv": iv.base64,
      "data": encrypted.base64,
    };
  }

  // 🔐 DECRYPT DATA
  static Future<String> _decrypt(Map<String, dynamic> jsonData) async {
    final key = await _getEncryptionKey();

    final iv = encrypt.IV.fromBase64(jsonData["iv"]);
    final encryptedData = jsonData["data"];

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt64(encryptedData, iv: iv);
  }

  // 🔥 NETWORK STORAGE (MULTI-CHAIN SAFE)
  static Future<void> setSelectedNetwork(String network) async {
    await _storage.write(
      key: _selectedNetworkKey,
      value: network.trim(),
    );
  }

  static Future<String> getSelectedNetwork() async {
    final net = await _storage.read(key: _selectedNetworkKey);

    if (net == null || net.trim().isEmpty) {
      return "BSC";
    }

    return net.trim();
  }

  // 🔥 SAVE WALLET (MULTI WALLET SAFE)
  static Future<void> saveWallet({
    required String name,
    required String privateKey,
    required String address,
  }) async {
    final wallets = await getWallets();

    final exists = wallets.any((w) => w["address"] == address);
    if (exists) return;

    final encrypted = await _encrypt(privateKey);

    final wallet = {
      "name": name.trim(),
      "address": address,
      "privateKey": encrypted,
    };

    wallets.add(wallet);

    await _storage.write(
      key: _walletsKey,
      value: jsonEncode(wallets),
    );

    await setSelectedWallet(address);
  }

  // 🔥 GET ALL WALLETS (SAFE PARSE)
  static Future<List<Map<String, dynamic>>> getWallets() async {
    try {
      final data = await _storage.read(key: _walletsKey);

      if (data == null || data.isEmpty) return [];

      final decoded = jsonDecode(data);

      if (decoded is List) {
        return decoded
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // 🔥 GET SELECTED WALLET
  static Future<Map<String, dynamic>?> getSelectedWallet() async {
    try {
      final address = await _storage.read(key: _selectedWalletKey);
      final wallets = await getWallets();

      if (wallets.isEmpty) return null;

      if (address == null) {
        return wallets.first;
      }

      return wallets.firstWhere(
        (w) => w["address"] == address,
        orElse: () => wallets.first,
      );
    } catch (e) {
      return null;
    }
  }

  // 🔥 SET SELECTED WALLET
  static Future<void> setSelectedWallet(String address) async {
    await _storage.write(
      key: _selectedWalletKey,
      value: address,
    );
  }

  // 🔥 GET PRIVATE KEY (SAFE)
  static Future<String?> getPrivateKey(String address) async {
    try {
      final wallets = await getWallets();

      final wallet = wallets.firstWhere(
        (w) => w["address"] == address,
        orElse: () => {},
      );

      if (wallet.isEmpty) return null;

      return await _decrypt(wallet["privateKey"]);
    } catch (e) {
      return null;
    }
  }

  // 🔥 RENAME WALLET (STRICT FIX)
  static Future<void> renameWallet(String address, String newName) async {
    final wallets = await getWallets();

    final trimmedName = newName.trim();

    if (trimmedName.isEmpty) return;

    for (var w in wallets) {
      if (w["address"] == address) {
        w["name"] = trimmedName;
      }
    }

    await _storage.write(
      key: _walletsKey,
      value: jsonEncode(wallets),
    );
  }

  // 🔥 DELETE WALLET
  static Future<void> deleteWallet(String address) async {
    final wallets = await getWallets();

    wallets.removeWhere((w) => w["address"] == address);

    await _storage.write(
      key: _walletsKey,
      value: jsonEncode(wallets),
    );

    final selected = await _storage.read(key: _selectedWalletKey);

    if (selected == address) {
      if (wallets.isNotEmpty) {
        await setSelectedWallet(wallets.first["address"]);
      } else {
        await _storage.delete(key: _selectedWalletKey);
      }
    }
  }

  // 🔥 CLEAR ALL (LOGOUT)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}