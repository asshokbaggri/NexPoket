import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'storage_service.dart';

class WalletService {

  static String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  static Future<Map<String, String>> createWallet(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);

    final privateKeyBytes = sha256.convert(seed).bytes;
    final privateKeyHex = HEX.encode(privateKeyBytes);

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final address = await credentials.extractAddress();

    // 🔐 Secure Save
    await StorageService.savePrivateKey(privateKeyHex);
    await StorageService.saveAddress(address.hex);

    return {
      "privateKey": privateKeyHex,
      "address": address.hex,
    };
  }

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