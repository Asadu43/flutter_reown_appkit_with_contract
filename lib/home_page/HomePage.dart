import 'dart:convert';
import 'dart:math' show pow;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/web3dart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  final ReownAppKitModal appKitModal;
  const HomePage({super.key, required this.appKitModal});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _contractAddress =
      "0x8083b21AE4ca53419F164e2eAb4e92F2E37bd447";

  // Store user info and token metadata
  String? _userAddress;
  String? _userBalance;
  String? _tokenName;
  String? _tokenSymbol;
  int? _tokenDecimals;

  Map<String, dynamic> _coinPrices = {};
  bool _loadingCoins = false;

  // API URL for fetching coin prices
  static const String _coinApiUrl =
      "https://coins.llama.fi/prices/current/coingecko:ethereum,coingecko:bitcoin,coingecko:solana,coingecko:bsc,bsc:0x762539b45a1dcce3d36d080f74d1aed37844b878,bsc:0xba2ae424d960c26247dd6c32edc70b295c744c43?searchWidth=4h";
  static const String _bscScanApiKey = "TKCVJ71434RPNHGYKFHWIVKZJ4UGBZGE8F";
  static const String _bscScanApiUrl =
      "https://api.bscscan.com/api?module=account&action=txlist&address=";

  static const String _bscScanTxBaseUrl = "https://bscscan.com/tx/";

  bool _loadingBalance = false;
  bool _loadingInfo = false;
  bool _sendingTokens = false;

  List<dynamic> _transactions = [];

  // For sending tokens
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserData();
    _fetchCoinPrices();
    _fetchTransactions();
  }

  void _getUserData() {
    final session = widget.appKitModal.session;
    if (session != null) {
      _userAddress = session.getAddress('eip155');
      if (_userAddress != null) {
        _fetchTokenInfo();
      }
    }
  }

  /// A helper to handle array-like results from readContract.
  dynamic _handleSingleValue(dynamic result) {
    if (result == null) return null;
    if (result == 'Error') return 'Error';

    if (result is List) {
      if (result.isEmpty) return 'Error';
      return result.first;
    }
    return result;
  }

  /// Utility to insert decimal point into a BigInt
  String _bigIntToDecimalString(BigInt amount, int decimals) {
    final str = amount.toString();
    if (decimals == 0) return str;

    if (str.length <= decimals) {
      final leadingZeros = decimals - str.length;
      return "0.${'0' * leadingZeros}$str";
    } else {
      final offset = str.length - decimals;
      final integerPart = str.substring(0, offset);
      final fractionalPart = str.substring(offset);
      return "$integerPart.$fractionalPart";
    }
  }

  /// 1) Fetch name, symbol, decimals, then fetch user balance
  Future<void> _fetchTokenInfo() async {
    setState(() => _loadingInfo = true);
    try {
      // name()
      final nameRes = await _callReadFunction('name');
      final nameVal = _handleSingleValue(nameRes);
      _tokenName = (nameVal is String) ? nameVal : 'Unknown';

      // symbol()
      final symbolRes = await _callReadFunction('symbol');
      final symbolVal = _handleSingleValue(symbolRes);
      _tokenSymbol = (symbolVal is String) ? symbolVal : '???';

      // decimals()
      final decimalsRes = await _callReadFunction('decimals');
      final decimalsVal = _handleSingleValue(decimalsRes);
      if (decimalsVal is String) {
        _tokenDecimals = int.tryParse(decimalsVal);
      } else if (decimalsVal is int) {
        _tokenDecimals = decimalsVal;
      } else {
        _tokenDecimals = 18; // fallback
      }

      // Then fetch user token balance
      await _fetchBalance();
    } catch (e) {
      debugPrint("Error fetching token info: $e");
    } finally {
      setState(() => _loadingInfo = false);
    }
  }

  /// 2) Fetch user’s ERC-20 balance
  Future<void> _fetchBalance() async {
    if (_userAddress == null) return;
    setState(() => _loadingBalance = true);

    try {
      final balanceRaw = await _callReadFunction(
        'balanceOf',
        [EthereumAddress.fromHex(_userAddress!)],
      );
      final extractedVal = _handleSingleValue(balanceRaw);

      if (extractedVal == null || extractedVal == 'Error') {
        debugPrint("Failed to get valid balance from contract");
        return;
      }

      final rawBigInt = BigInt.parse(extractedVal.toString());
      final decimals = _tokenDecimals ?? 18;
      final decimalString = _bigIntToDecimalString(rawBigInt, decimals);
      final converted = double.parse(decimalString);

      _userBalance = converted.toStringAsFixed(4);
      debugPrint("Balance after conversion: $_userBalance");
    } catch (e) {
      debugPrint("Error fetching balance: $e");
    } finally {
      setState(() => _loadingBalance = false);
    }
  }

  /// 3) Transfer tokens
  Future<void> _sendTokens() async {
    final recipient = _recipientController.text.trim();
    final amountStr = _amountController.text.trim();

    if (recipient.isEmpty || amountStr.isEmpty) {
      _showErrorDialog("Recipient or amount cannot be empty.");
      return;
    }

    if (_userAddress == null) {
      _showErrorDialog("No connected wallet found.");
      return;
    }

    final decimals = _tokenDecimals ?? 18;
    setState(() => _sendingTokens = true);

    try {
      // Convert decimal amount to BigInt
      final decimalValue = double.parse(amountStr);
      final BigInt weiValue =
          BigInt.parse((decimalValue * pow(10, decimals)).toStringAsFixed(0));

      // Load contract ABI
      final abi = await rootBundle.loadString("assets/abi/abi.json");
      final deployedContract = DeployedContract(
        ContractAbi.fromJson(abi, 'AsadToken'),
        EthereumAddress.fromHex(_contractAddress),
      );

      debugPrint("Sending $weiValue tokens to $recipient from $_userAddress");
      widget.appKitModal.launchConnectedWallet();
      final result = await widget.appKitModal.requestWriteContract(
        topic: widget.appKitModal.session!.topic,
        chainId: widget.appKitModal.selectedChain!.chainId,
        deployedContract: deployedContract,
        functionName: 'transfer',
        transaction: Transaction(
          from: EthereumAddress.fromHex(_userAddress!), // sender address
        ),
        parameters: [
          EthereumAddress.fromHex(recipient), // Use user input
          weiValue, // Use calculated value
        ],
      );

      debugPrint("\n\n\n\n\n\n\n\n\n\n");
      debugPrint("Transfer token result: $result");
      debugPrint("\n\n\n\n\n\n\n\n\n\n");

      _recipientController.clear();
      _amountController.clear();
    } catch (e) {
      debugPrint("Error sending tokens: $e");
      _showErrorDialog("Error sending tokens:\n$e");
    } finally {
      setState(() => _sendingTokens = false);
    }
  }

  /// Show an error message in a dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

// Function to show receive token screen
  void _showReceiveTokenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Receive Tokens"),
        content: SizedBox(
          width: 300, // Define a width to avoid layout errors
          child: Column(
            mainAxisSize: MainAxisSize.min, // Avoid taking unnecessary space
            children: [
              if (_userAddress != null) ...[
                const Text(
                  "Wallet Address:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SelectableText(
                  _userAddress!,
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                QrImageView(
                  data: _userAddress!,
                  version: QrVersions.auto,
                  size: 200.0, // Ensure QR code has a defined size
                ),
              ] else
                const Text("No connected wallet found"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  /// Helper for calling read-only function
  Future<dynamic> _callReadFunction(String fnName,
      [List<dynamic> params = const []]) async {
    try {
      final abi = await rootBundle.loadString("assets/abi/abi.json");
      final deployedContract = DeployedContract(
        ContractAbi.fromJson(abi, 'AsadToken'),
        EthereumAddress.fromHex(_contractAddress),
      );
      final result = await widget.appKitModal.requestReadContract(
        deployedContract: deployedContract,
        functionName: fnName,
        parameters: params,
        topic: widget.appKitModal.session?.topic,
        chainId: '11155111',
      );
      return result;
    } catch (e) {
      debugPrint("Error calling $fnName: $e");
      return 'Error';
    }
  }

  /// Fetch latest coin prices from the API
  Future<void> _fetchCoinPrices() async {
    setState(() => _loadingCoins = true);
    try {
      final response = await http.get(Uri.parse(_coinApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _coinPrices = data['coins'];
        });
      } else {
        debugPrint("Failed to fetch coin prices: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching coin prices: $e");
    } finally {
      setState(() => _loadingCoins = false);
    }
  }

  /// Build the coin prices UI
  Widget _buildCoinPrices() {
    if (_loadingCoins) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coinPrices.isEmpty) {
      return const Text("No coin data available.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Crypto Prices",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._coinPrices.entries.map((entry) {
          final key = entry.key;
          final coin = entry.value;
          return Card(
            child: ListTile(
              title: Text(
                "${coin['symbol'].toUpperCase()} - \$${coin['price']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Updated: ${coin['timestamp']}"),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Fetch transaction history from BscScan
  Future<void> _fetchTransactions() async {
    if (_userAddress == null) return;

    setState(() => _loadingCoins = true);

    final apiUrl =
        "https://api.bscscan.com/api?module=account&action=txlist&address=0xF426a8d0A94bf039A35CEE66dBf0227A7a12D11e&startblock=0&endblock=latest&page=1&offset=10&sort=desc&apikey=TKCVJ71434RPNHGYKFHWIVKZJ4UGBZGE8F";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "1") {
          setState(() {
            _transactions = data["result"];
          });
        } else {
          debugPrint("Error: ${data["message"]}");
        }
      } else {
        debugPrint("Failed to fetch transactions: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    } finally {
      setState(() => _loadingCoins = false);
    }
  }

  /// Format timestamp to readable date
  String _formatTimestamp(String timestamp) {
    final int timeInSeconds = int.parse(timestamp);
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timeInSeconds * 1000);
    return DateFormat("dd MMM yyyy, HH:mm").format(date);
  }

  /// Open transaction in BscScan
  Future<void> _openTransactionLink(String txHash) async {
    final Uri url = Uri.parse("$_bscScanTxBaseUrl$txHash");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not open $url");
    }
  }

  /// Build transaction history list
  Widget _buildTransactionHistory() {
    if (_loadingCoins) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return const Text("No transactions found.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Transaction History",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._transactions.map((tx) {
          return Card(
            child: ListTile(
              title: GestureDetector(
                  onTap: () => _openTransactionLink(tx["hash"]),
                  child: Text(
                    "Txn Hash: ${tx["hash"].substring(0, 10)}...",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  )),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("From: ${tx["from"]}"),
                  Text("To: ${tx["to"]}"),
                  Text("Gas Used: ${tx["gasUsed"]}"),
                  Text("Value: ${tx["value"]} Wei"),
                  Text("Date: ${_formatTimestamp(tx["timeStamp"])}"),
                ],
              ),
              trailing: Icon(
                tx["txreceipt_status"] == "1" ? Icons.check : Icons.close,
                color:
                    tx["txreceipt_status"] == "1" ? Colors.green : Colors.red,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInfoLoading = _loadingInfo;
    final isBalanceLoading = _loadingBalance;
    final hasAddress = _userAddress != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Welcome to Decentralized App",
                  style: TextStyle(fontSize: 25),
                ),
                const SizedBox(height: 20),

                if (!hasAddress) ...[
                  const Text(
                    "No connected wallet found",
                    style: TextStyle(fontSize: 16),
                  ),
                ] else ...[
                  Text(
                    "Connected Address:",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  Text(_userAddress!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),
                  if (isInfoLoading) ...[
                    const CircularProgressIndicator(),
                  ] else ...[
                    Text(
                      "${_tokenName ?? '--'} (${_tokenSymbol ?? '--'})",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_tokenDecimals != null)
                      Text("Decimals: $_tokenDecimals",
                          style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 20),
                    const Text("Token Balance:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (isBalanceLoading) ...[
                      const CircularProgressIndicator(),
                    ] else ...[
                      Text(_userBalance ?? '0',
                          style: const TextStyle(
                              fontSize: 24, color: Colors.blue)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchBalance,
                      child: const Text("Refresh Balance"),
                    ),
                    const Divider(height: 40),
                    const Text(
                      "Send Token:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _recipientController,
                      decoration: const InputDecoration(
                        labelText: "Recipient Address (0x...)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Amount in ${_tokenSymbol ?? 'Token'}",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _sendingTokens
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _sendTokens,
                            child: const Text("Send"),
                          ),
                  ],
                ],

                ElevatedButton(
                  onPressed: () => _showReceiveTokenDialog(context),
                  child: const Text("Receive Tokens"),
                ),

                const SizedBox(height: 20),
                // Reown UI elements
                AppKitModalNetworkSelectButton(appKit: widget.appKitModal),
                AppKitModalAccountButton(appKitModal: widget.appKitModal),
                const SizedBox(height: 20),
                _buildCoinPrices(),
                const SizedBox(height: 20),
                _buildTransactionHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
