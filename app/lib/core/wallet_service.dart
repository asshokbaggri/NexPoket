// app/lib/core/wallet_service.dart

import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:http/http.dart';

import 'storage_service.dart';

class WalletService {

  // 🔐 SAFE MNEMONIC GENERATION (NO DUPLICATE / INVALID)
  static String generateMnemonic() {
    String mnemonic;

    do {
      mnemonic = bip39.generateMnemonic();
    } while (!bip39.validateMnemonic(mnemonic));

    return mnemonic;
  }

  // ✅ VALIDATE
  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  // 🔥 REAL WALLET (BIP44 DERIVATION)
  static Future<Map<String, String>> createWallet(String mnemonic) async {

    final seed = bip39.mnemonicToSeed(mnemonic);

    // 🔥 ROOT
    final root = bip32.BIP32.fromSeed(seed);

    // 🔥 ETH PATH (IMPORTANT)
    final child = root.derivePath("m/44'/60'/0'/0/0");

    final privateKeyBytes = child.privateKey;
    if (privateKeyBytes == null) {
      throw Exception("Private key generation failed");
    }

    final privateKeyHex = HEX.encode(privateKeyBytes);

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final address = await credentials.extractAddress();

    // 🔐 SAVE SECURELY
    await StorageService.savePrivateKey(privateKeyHex);
    await StorageService.saveAddress(address.hex);

    return {
      "privateKey": privateKeyHex,
      "address": address.hex,
    };
  }

  // 🔥 GET BALANCE (REAL)
  static Future<String> getBalance(String address) async {
    final client = Web3Client(
      "https://mainnet.infura.io/v3/339315f5c81347debe3b12374712fa4d",
      Client(),
    );

    final ethAddress = EthereumAddress.fromHex(address);
    final balance = await client.getBalance(ethAddress);

    return balance.getValueInUnit(EtherUnit.ether).toString();
  }
}