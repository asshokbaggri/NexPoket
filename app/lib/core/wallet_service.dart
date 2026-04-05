// app/lib/core/wallet_service.dart

import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:http/http.dart';

import 'storage_service.dart';

class WalletService {

  // 🔥 MULTI-CHAIN CONFIG
  static const Map<String, Map<String, String>> networks = {
    "BSC": {
      "rpc": "https://bsc-dataseed.binance.org/",
      "symbol": "BNB",
      "chainId": "56",
      "chainFolder": "smartchain",
    },
    "Ethereum": {
      "rpc": "https://mainnet.infura.io/v3/339315f5c81347debe3b12374712fa4d",
      "symbol": "ETH",
      "chainId": "1",
      "chainFolder": "ethereum",
    },
    "Polygon": {
      "rpc": "https://polygon-rpc.com/",
      "symbol": "POL",
      "chainId": "137",
      "chainFolder": "polygon",
    },
  };

  // 🔥 DEFAULT TOKENS (VERY IMPORTANT 🔥)
  static const Map<String, List<Map<String, dynamic>>> defaultTokens = {
    "BSC": [
      {
        "name": "BNB",
        "symbol": "BNB",
        "contract": "",
        "decimals": 18,
        "isNative": true,
      },
      {
        "name": "Tether USD",
        "symbol": "USDT",
        "contract": "0x55d398326f99059fF775485246999027B3197955",
        "decimals": 18,
        "isNative": false,
      },
      {
        "name": "USD Coin",
        "symbol": "USDC",
        "contract": "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
        "decimals": 18,
        "isNative": false,
      },
    ],

    "Ethereum": [
      {
        "name": "Ethereum",
        "symbol": "ETH",
        "contract": "",
        "decimals": 18,
        "isNative": true,
      },
      {
        "name": "Tether USD",
        "symbol": "USDT",
        "contract": "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        "decimals": 6,
        "isNative": false,
      },
      {
        "name": "USD Coin",
        "symbol": "USDC",
        "contract": "0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        "decimals": 6,
        "isNative": false,
      },
    ],

    "Polygon": [
      {
        "name": "Polygon",
        "symbol": "POL",
        "contract": "",
        "decimals": 18,
        "isNative": true,
      },
      {
        "name": "Tether USD",
        "symbol": "USDT",
        "contract": "0xc2132D05D31c914a87C6611C10748AaCBdEac2bA",
        "decimals": 6,
        "isNative": false,
      },
      {
        "name": "USD Coin",
        "symbol": "USDC",
        "contract": "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
        "decimals": 6,
        "isNative": false,
      },
    ],
  };

  // 🔐 GENERATE MNEMONIC
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

  // 🔥 GET NATIVE BALANCE
  static Future<String> getBalance(String address, String network) async {
    try {
      final rpc = networks[network]?["rpc"];

      if (rpc == null) return "0.00";

      final client = Web3Client(rpc, Client());

      final ethAddress = EthereumAddress.fromHex(address);

      final balance = await client.getBalance(ethAddress);

      client.dispose();

      return balance
          .getValueInUnit(EtherUnit.ether)
          .toStringAsFixed(6);

    } catch (e) {
      return "0.00";
    }
  }

  // 🔥 ERC20 TOKEN BALANCE
  static Future<String> getTokenBalance({
    required String address,
    required String contract,
    required int decimals,
    required String network,
  }) async {
    try {
      final rpc = networks[network]?["rpc"];
      if (rpc == null) return "0.00";

      final client = Web3Client(rpc, Client());

      final contractAddr = EthereumAddress.fromHex(contract);
      final userAddr = EthereumAddress.fromHex(address);

      final abi = ContractAbi.fromJson(
        '[{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"type":"function"}]',
        "ERC20",
      );

      final contractObj = DeployedContract(abi, contractAddr);
      final balanceFunction = contractObj.function("balanceOf");

      final result = await client.call(
        contract: contractObj,
        function: balanceFunction,
        params: [userAddr],
      );

      client.dispose();

      final BigInt raw = result.first;

      final divisor = BigInt.from(10).pow(decimals);

      final double value = raw / divisor;

      return value.toStringAsFixed(6);

    } catch (e) {
      return "0.00";
    }
  }

  // 🔥 GET SYMBOL
  static String getSymbol(String network) {
    return networks[network]?["symbol"] ?? "";
  }

  // 🔥 GET DEFAULT TOKENS
  static List<Map<String, dynamic>> getDefaultTokens(String network) {
    return defaultTokens[network] ?? [];
  }

  // 🔥 TOKEN ICON (TRUST WALLET CDN)
  static String getTokenIcon({
    required String network,
    required String contract,
    required bool isNative,
  }) {
    final folder = networks[network]?["chainFolder"] ?? "";

    if (isNative) {
      return "https://assets.trustwallet.com/blockchains/$folder/info/logo.png";
    }

    return "https://assets.trustwallet.com/blockchains/$folder/assets/$contract/logo.png";
  }
}