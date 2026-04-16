// app/lib/core/wallet_service.dart

import 'dart:convert';

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

  // =========================================================
// 🔥 EXPLORER CONFIG (ETHERSCAN V2 - SINGLE KEY)
// =========================================================

static const String explorerApiKey = "S97UPFBS6EJRSNUHQU1PD25KNT89UJKX6C";

static const Map<String, int> explorerChainIds = {
  "Ethereum": 1,
  "BSC": 56,
  "Polygon": 137,
};

  // 🔥 DEFAULT TOKENS
  static const Map<String, List<Map<String, dynamic>>> defaultTokens = {
    "BSC": [
      {"name": "BNB","symbol": "BNB","contract": "","decimals": 18,"isNative": true},
      {"name": "Tether USD","symbol": "USDT","contract": "0x55d398326f99059fF775485246999027B3197955","decimals": 18,"isNative": false},
      {"name": "USD Coin","symbol": "USDC","contract": "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d","decimals": 18,"isNative": false},
    ],
    "Ethereum": [
      {"name": "Ethereum","symbol": "ETH","contract": "","decimals": 18,"isNative": true},
      {"name": "Tether USD","symbol": "USDT","contract": "0xdAC17F958D2ee523a2206206994597C13D831ec7","decimals": 6,"isNative": false},
      {"name": "USD Coin","symbol": "USDC","contract": "0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48","decimals": 6,"isNative": false},
    ],
    "Polygon": [
      {"name": "Polygon","symbol": "POL","contract": "","decimals": 18,"isNative": true},
      {"name": "Tether USD","symbol": "USDT","contract": "0xc2132D05D31c914a87C6611C10748AaCBdEac2bA","decimals": 6,"isNative": false},
      {"name": "USD Coin","symbol": "USDC","contract": "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174","decimals": 6,"isNative": false},
    ],
  };

  // 🔥 SYMBOL FIX MAP
  static const Map<String, String> symbolMap = {
    "weth": "eth",
    "matic": "pol",
    "bnb": "bnb",
    "eth": "eth",
    "btc": "btc",
    "usdt": "usdt",
    "usdc": "usdc",
  };

  // 🔥 STABLE COIN CHECK
  static bool isStableCoin(String symbol) {
    final s = symbol.toLowerCase();
    return s == "usdt" || s == "usdc" || s == "busd" || s == "dai";
  }

  // 🔥 STATIC MAP
  static const Map<String, String> baseIds = {
    "eth": "ethereum",
    "bnb": "binancecoin",
    "pol": "matic-network",
    "usdt": "tether",
    "usdc": "usd-coin",
    "btc": "bitcoin",
    "shib": "shiba-inu",
    "trx": "tron",
    "doge": "dogecoin",
    "sol": "solana",
  };

  static Map<String, String> dynamicIdCache = {};

  // =========================================================
  // 🔥 COINGECKO ID RESOLVER
  // =========================================================

  static Future<String?> resolveCoinGeckoId(String symbol) async {

    final clean = symbol.toLowerCase();

    if (baseIds.containsKey(clean)) {
      return baseIds[clean];
    }

    if (dynamicIdCache.containsKey(clean)) {
      return dynamicIdCache[clean];
    }

    try {
      final url = Uri.parse(
        "https://api.coingecko.com/api/v3/search?query=$clean",
      );

      final res = await Client().get(url);
      final data = jsonDecode(res.body);

      if (data["coins"] != null && data["coins"].isNotEmpty) {

        final coin = data["coins"].firstWhere(
          (c) => c["symbol"].toString().toLowerCase() == clean,
          orElse: () => data["coins"][0],
        );

        final id = coin["id"];
        dynamicIdCache[clean] = id;

        return id;
      }

    } catch (_) {}

    return null;
  }

  // =========================================================
  // 🔥 MAIN LIVE PRICE ENGINE (FINAL FIXED)
  // =========================================================

  static Future<Map<String, dynamic>> getLivePricesAdvanced(
    List<Map<String, dynamic>> tokens,
    String network,
  ) async {

    Map<String, dynamic> result = {};
    final client = Client();

    for (var token in tokens) {

      final symbol = token["symbol"];
      final contract = token["contract"]?.toString() ?? "";

      double price = 0;
      double change = 0;

      // ================= STABLE COIN FIX =================
      if (isStableCoin(symbol)) {
        try {
          final res = await client.get(
            Uri.parse("https://api.binance.com/api/v3/ticker/24hr?symbol=${symbol}USDT"),
          );

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            price = double.tryParse(data["lastPrice"]) ?? 1.0;
            change = double.tryParse(data["priceChangePercent"]) ?? 0;
          } else {
            price = 1.0;
          }
        } catch (_) {
          price = 1.0;
        }
      }

      // ================= BINANCE =================
      if (price == 0) {
        try {
          final pair = "${symbol.toUpperCase()}USDT";

          final res = await client.get(
            Uri.parse("https://api.binance.com/api/v3/ticker/24hr?symbol=$pair"),
          );

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);

            price = double.tryParse(data["lastPrice"]) ?? 0;
            change = double.tryParse(data["priceChangePercent"]) ?? 0;
          }
        } catch (_) {}
      }

      // ================= DEXSCREENER =================
      if (price == 0 && contract.isNotEmpty) {
        try {
          final res = await client.get(
            Uri.parse("https://api.dexscreener.com/latest/dex/tokens/$contract"),
          );

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);

            if (data["pairs"] != null && data["pairs"].isNotEmpty) {
              final pair = data["pairs"][0];

              price = double.tryParse(pair["priceUsd"] ?? "0") ?? 0;
              change = double.tryParse(
                pair["priceChange"]?["h24"]?.toString() ?? "0",
              ) ?? 0;
            }
          }

        } catch (_) {}
      }

      // ================= COINGECKO =================
      if (price == 0) {
        try {
          final id = await resolveCoinGeckoId(symbol);

          if (id != null) {
            final res = await client.get(
              Uri.parse(
                "https://api.coingecko.com/api/v3/simple/price"
                "?ids=$id&vs_currencies=usd&include_24hr_change=true",
              ),
            );

            final data = jsonDecode(res.body);

            if (data[id] != null) {
              price = (data[id]["usd"] ?? 0).toDouble();
              change = (data[id]["usd_24h_change"] ?? 0).toDouble();
            }
          }

        } catch (_) {}
      }

      result[symbol] = {
        "price": price,
        "change": change,
      };
    }

    return result;
  }

  // =========================================================
  // 🔥 PORTFOLIO
  // =========================================================

  static double calculatePortfolio(
    List<Map<String, dynamic>> tokens,
    Map<String, String> balances,
    Map<String, dynamic> prices,
  ) {
    double total = 0;

    for (var t in tokens) {
      final symbol = t["symbol"];
      final bal = double.tryParse(balances[symbol] ?? "0") ?? 0;
      final price = prices[symbol]?["price"] ?? 0;

      total += bal * price;
    }

    return total;
  }

  // =========================================================
  // 🔐 MNEMONIC + WALLET
  // =========================================================

  static String generateMnemonic() {
    String mnemonic;
    do {
      mnemonic = bip39.generateMnemonic();
    } while (!bip39.validateMnemonic(mnemonic));
    return mnemonic;
  }

  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  static Future<Map<String, String>> createWallet(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("m/44'/60'/0'/0/0");

    final privateKeyHex = HEX.encode(child.privateKey!);
    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final address = await credentials.extractAddress();

    final wallets = await StorageService.getWallets();
    final walletName = "Wallet ${wallets.length + 1}";

    await StorageService.saveWallet(
      name: walletName,
      privateKey: privateKeyHex,
      address: address.hex,
      mnemonic: mnemonic, // 🔥 ADD THIS
    );

    return {"address": address.hex};
  }

  // =========================================================
  // 💰 BALANCE
  // =========================================================

  static Future<String> getBalance(String address, String network) async {
    try {
      final rpc = networks[network]?["rpc"];
      if (rpc == null) return "0.00";

      final client = Web3Client(rpc, Client());
      final ethAddress = EthereumAddress.fromHex(address);
      final balance = await client.getBalance(ethAddress);
      client.dispose();

      return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(6);

    } catch (e) {
      return "0.00";
    }
  }

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
      final result = await client.call(
        contract: contractObj,
        function: contractObj.function("balanceOf"),
        params: [userAddr],
      );

      client.dispose();

      final raw = result.first as BigInt;
      final divisor = BigInt.from(10).pow(decimals);

      final value = raw / divisor;
      return value.toStringAsFixed(6);

    } catch (e) {
      return "0.00";
    }
  }

  // =========================================================
  // ICONS
  // =========================================================

  static String resolveLocalIcon(String symbol) {
    final clean = symbol.toLowerCase().trim();
    final mapped = symbolMap[clean] ?? clean;
    return "assets/tokens/$mapped.svg";
  }

  static String resolveFallbackIcon({
    required String network,
    required String contract,
    required bool isNative,
  }) {
    final folder = networks[network]?["chainFolder"] ?? "";

    if (isNative || contract.isEmpty) {
      return "https://assets.trustwallet.com/blockchains/$folder/info/logo.png";
    }

    final cleanContract = contract.toLowerCase();

    return "https://assets.trustwallet.com/blockchains/$folder/assets/$cleanContract/logo.png";
  }

  // =========================================================
  // 🔥 REAL TRANSACTION HISTORY (ETHERSCAN V2 FINAL)
  // =========================================================

  static Future<List<Map<String, dynamic>>> getTransactionHistory({
    required String address,
    required String network,
  }) async {

    List<Map<String, dynamic>> txs = [];

    try {

      final chainId = explorerChainIds[network];
      if (chainId == null) return [];

      final url = Uri.parse(
        "https://api.etherscan.io/api"
        "?chainid=$chainId"
        "&module=account"
        "&action=txlist"
        "&address=$address"
        "&startblock=0"
        "&endblock=99999999"
        "&sort=desc"
        "&apikey=$explorerApiKey",
      );

      final res = await Client().get(url);

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);

      if (data["status"] != "1") return [];

      final list = data["result"] as List;

      for (var tx in list.take(30)) {

        final isSent =
            tx["from"].toString().toLowerCase() ==
            address.toLowerCase();

        final valueWei = BigInt.tryParse(tx["value"]) ?? BigInt.zero;

        final valueEth =
            valueWei / BigInt.from(10).pow(18);

        txs.add({
          "hash": tx["hash"],
          "from": tx["from"],
          "to": tx["to"],
          "value": valueEth.toStringAsFixed(6),
          "time": DateTime.fromMillisecondsSinceEpoch(
            int.parse(tx["timeStamp"]) * 1000,
          ),
          "isSent": isSent,
          "status": tx["txreceipt_status"] == "1",
        });
      }

    } catch (e) {
      // silent fail
    }

    return txs;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  static String getSymbol(String network) {
    return networks[network]?["symbol"] ?? "";
  }

  static List<Map<String, dynamic>> getDefaultTokens(String network) {
    return defaultTokens[network] ?? [];
  }
}