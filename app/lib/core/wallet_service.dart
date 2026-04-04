// app/lib/core/wallet_service.dart

import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:http/http.dart';

import 'storage_service.dart';

class WalletService {

  // 🔐 SAFE MNEMONIC (avoid weird UX duplicates feeling)
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

  // 🔥 CREATE WALLET (WITH PROPER NAMING)
  static Future<Map<String, String>> createWallet(String mnemonic) async {

    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("m/44'/60'/0'/0/0");

    final privateKeyBytes = child.privateKey!;
    final privateKeyHex = HEX.encode(privateKeyBytes);

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final address = await credentials.extractAddress();

    // 🔥 AUTO NAME FIX (Wallet 1, 2, 3...)
    final wallets = await StorageService.getWallets();
    final walletNumber = wallets.length + 1;
    final walletName = "Wallet $walletNumber";

    await StorageService.saveWallet(
      name: walletName,
      privateKey: privateKeyHex,
      address: address.hex,
    );

    return {
      "address": address.hex,
    };
  }

  // 🔥 BALANCE
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