// app/lib/screens/add_token_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import '../core/storage_service.dart';
import '../core/wallet_service.dart';

class AddTokenScreen extends StatefulWidget {
  final String network;

  const AddTokenScreen({
    super.key,
    required this.network,
  });

  @override
  State<AddTokenScreen> createState() => _AddTokenScreenState();
}

class _AddTokenScreenState extends State<AddTokenScreen> {

  final contractController = TextEditingController();
  final nameController = TextEditingController();
  final symbolController = TextEditingController();
  final decimalsController = TextEditingController();

  bool isLoading = false;
  bool isFetching = false;

  String selectedNetwork = "BSC";

  @override
  void initState() {
    super.initState();
    selectedNetwork = widget.network;

    contractController.addListener(() {
      if (contractController.text.length > 20) {
        fetchTokenDetails();
      }
    });
  }

  // 🔥 NETWORK ICONS
  Widget getNetworkIcon(String network) {
    switch (network) {
      case "Ethereum":
        return const CircleAvatar(
          radius: 10,
          backgroundImage: NetworkImage(
              "https://cryptologos.cc/logos/ethereum-eth-logo.png"),
        );
      case "Polygon":
        return const CircleAvatar(
          radius: 10,
          backgroundImage: NetworkImage(
              "https://cryptologos.cc/logos/polygon-matic-logo.png"),
        );
      default:
        return const CircleAvatar(
          radius: 10,
          backgroundImage: NetworkImage(
              "https://cryptologos.cc/logos/bnb-bnb-logo.png"),
        );
    }
  }

  // 🔥 AUTO FETCH TOKEN DETAILS
  Future<void> fetchTokenDetails() async {
    final contract = contractController.text.trim();

    if (contract.isEmpty) return;

    setState(() => isFetching = true);

    try {
      final rpc = WalletService.networks[selectedNetwork]!["rpc"]!;
      final client = Web3Client(rpc, Client());

      final contractAddr = EthereumAddress.fromHex(contract);

      final abi = ContractAbi.fromJson(
        '''
        [
          {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},
          {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},
          {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"}
        ]
        ''',
        "ERC20",
      );

      final contractObj = DeployedContract(abi, contractAddr);

      final nameResult = await client.call(
        contract: contractObj,
        function: contractObj.function("name"),
        params: [],
      );

      final symbolResult = await client.call(
        contract: contractObj,
        function: contractObj.function("symbol"),
        params: [],
      );

      final decimalsResult = await client.call(
        contract: contractObj,
        function: contractObj.function("decimals"),
        params: [],
      );

      client.dispose();

      setState(() {
        nameController.text = nameResult.first.toString();
        symbolController.text = symbolResult.first.toString();
        decimalsController.text = decimalsResult.first.toString();
      });

    } catch (e) {}

    setState(() => isFetching = false);
  }

  Future<void> pasteAddress() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null) {
      contractController.text = data.text ?? "";
    }
  }

  Future<void> addToken() async {

    final contract = contractController.text.trim();
    final name = nameController.text.trim();
    final symbol = symbolController.text.trim();
    final decimals = decimalsController.text.trim();

    if (contract.isEmpty || name.isEmpty || symbol.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await StorageService.addCustomToken({
        "contract": contract,
        "name": name,
        "symbol": symbol,
        "decimals": decimals.isEmpty ? "18" : decimals,
        "network": selectedNetwork,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token Added ✔")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() => isLoading = false);
  }

  Widget buildInput({
    required TextEditingController controller,
    required String label,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Crypto"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔥 NETWORK DROPDOWN WITH ICON
            DropdownButtonFormField<String>(
              value: selectedNetwork,
              items: ["BSC", "Ethereum", "Polygon"].map((net) {
                return DropdownMenuItem(
                  value: net,
                  child: Row(
                    children: [
                      getNetworkIcon(net),
                      const SizedBox(width: 10),
                      Text(net),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedNetwork = val;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: "Network",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 CONTRACT + PREMIUM PASTE BUTTON
            buildInput(
              controller: contractController,
              label: "Contract Address",
              suffix: GestureDetector(
                onTap: pasteAddress,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3375BB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Paste",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            if (isFetching)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),

            const SizedBox(height: 15),

            buildInput(
              controller: nameController,
              label: "Token Name",
            ),

            const SizedBox(height: 15),

            buildInput(
              controller: symbolController,
              label: "Symbol",
            ),

            const SizedBox(height: 15),

            buildInput(
              controller: decimalsController,
              label: "Decimals",
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: isLoading ? null : addToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3375BB),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Add Crypto",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}