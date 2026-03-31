import 'package:bip39/bip39.dart' as bip39;

class WalletService {

  // 🔐 Generate new seed phrase
  static String generateMnemonic() {
    return bip39.generateMnemonic(); // 12 words
  }

  // ✅ Validate mnemonic
  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }
}