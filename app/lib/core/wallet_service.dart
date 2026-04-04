import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:http/http.dart';

import 'storage_service.dart';

class WalletService {

  // 🔥 MULTI-CHAIN CONFIG (PRO READY)
  static const Map<String, Map<String, String>> networks = {
    "BSC": {
      "rpc": "https://bsc-dataseed.binance.org/",
      "symbol": "BNB",
    },
    "Ethereum": {
      "rpc": "https://mainnet.infura.io/v3/339315f5c81347debe3b12374712fa4d",
      "symbol": "ETH",
    },
    "Polygon": {
      "rpc": "https://polygon-rpc.com/",
      "symbol": "POL", // 🔥 FIXED (MATIC → POL)
    },
  };

  // 🔐 GENERATE MNEMONIC
  static String generateMnemonic() {
    String mnemonic;

    do {
      mnemonic = bip39.generateMnemonic();
    } while (!bip39.validateMnemonic(mnemonic));

    return mnemonic;
  }

  // ✅ VALIDATE MNEMONIC
  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  // 🔥 CREATE WALLET
  static Future<Map<String, String>> createWallet(String mnemonic) async {

    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("m/44'/60'/0'/0/0");

    final privateKeyBytes = child.privateKey!;
    final privateKeyHex = HEX.encode(privateKeyBytes);

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final address = await credentials.extractAddress();

    final wallets = await StorageService.getWallets();
    final walletName = "Wallet ${wallets.length + 1}";

    await StorageService.saveWallet(
      name: walletName,
      privateKey: privateKeyHex,
      address: address.hex,
    );

    return {
      "address": address.hex,
    };
  }

  // 🔥 GET BALANCE (MULTI-CHAIN SAFE)
  static Future<String> getBalance(String address, String network) async {

    try {
      final rpc = networks[network]?["rpc"];

      if (rpc == null) return "0.00";

      final client = Web3Client(rpc, Client());

      final ethAddress = EthereumAddress.fromHex(address);

      final balance = await client.getBalance(ethAddress);

      // 🔥 IMPORTANT: close client
      client.dispose();

      return balance
          .getValueInUnit(EtherUnit.ether)
          .toStringAsFixed(6);

    } catch (e) {
      return "0.00"; // 🔥 no crash
    }
  }

  // 🔥 GET SYMBOL
  static String getSymbol(String network) {
    return networks[network]?["symbol"] ?? "";
  }
}