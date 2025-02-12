// import 'package:external_app_launcher/external_app_launcher.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:url_launcher/url_launcher_string.dart';
// import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
//
// import '../utils/AppColors.dart';
// import '../utils/app_button.dart';
//
// class MetaMaskScreen extends StatefulWidget {
//   const MetaMaskScreen({super.key});
//
//   @override
//   State<MetaMaskScreen> createState() => _MetaMaskScreenState();
// }
//
// class _MetaMaskScreenState extends State<MetaMaskScreen>
//     with SingleTickerProviderStateMixin {
//   /// The WalletConnect V2 Web3App instance.
//   static Web3App? _walletConnect;
//   static String? _url;
//   static SessionData? _sessionData;
//
//   String? account;
//   String? signature;
//
//   /// Constants
//   static const String kShortChainId = 'eip155';
//   static const String kFullChainId = 'eip155:1';
//   static const String launchError = 'Metamask wallet not installed';
//
//   /// Construct a deep link URL for MetaMask
//   String get deepLinkUrl => 'metamask://wc?uri=$_url';
//
//   /// Initialize the Web3App instance if needed.
//   Future<void> _initWalletConnect() async {
//     _walletConnect = await Web3App.createInstance(
//       projectId: 'b8ff9c52a3433ab288836f7402d5d323',
//       metadata: const PairingMetadata(
//         name: 'Flutter WalletConnect',
//         description: 'Flutter WalletConnect Dapp',
//         url: 'https://walletconnect.com/',
//         icons: [
//           'https://walletconnect.com/walletconnect-logo.png',
//         ],
//       ),
//     );
//   }
//
//   /// Creates a WalletConnect session, requesting Ethereum mainnet as required
//   /// and offering BSC Testnet + Polygon mainnet as optional.
//   Future<String?> createSession() async {
//     // (Optional) check if MetaMask is installed.
//     // 1) Initialize if null
//     if (_walletConnect == null) {
//       await _initWalletConnect();
//     }
//
//     // 2) Connect with required and optional namespaces
//     final ConnectResponse connectResponse = await _walletConnect!.connect(
//
//         /// requiredNamespaces:
//         ///   This is the chain or chains the wallet must support to approve the connection.
//         requiredNamespaces: {
//           kShortChainId: const RequiredNamespace(
//             /// We only 'require' Ethereum Mainnet here.
//             chains: ['eip155:1'],
//             methods: [
//               'eth_sign',
//               'eth_signTransaction',
//               'eth_sendTransaction',
//               'personal_sign',
//               'wallet_addEthereumChain',
//               'wallet_switchEthereumChain',
//             ],
//             events: [
//               'chainChanged',
//               'accountsChanged',
//             ],
//           ),
//         },
//
//         /// optionalNamespaces:
//         ///   Additional chains the wallet may optionally support.
//         optionalNamespaces: {
//           kShortChainId: const RequiredNamespace(
//             chains: ['eip155:97', 'eip155:137'],
//             methods: [
//               'eth_sign',
//               'eth_signTransaction',
//               'eth_sendTransaction',
//               'personal_sign',
//               'wallet_addEthereumChain',
//               'wallet_switchEthereumChain',
//             ],
//             events: [
//               'chainChanged',
//               'accountsChanged',
//             ],
//           ),
//         });
//
//     // If the user needs to approve the session in MetaMask, open the deep link
//     final Uri? uri = connectResponse.uri;
//     if (uri != null) {
//       final String encodedUrl = Uri.encodeComponent('$uri');
//       _url = encodedUrl;
//
//       await launchUrlString(
//         deepLinkUrl,
//         mode: LaunchMode.externalApplication,
//       );
//     }
//
//     // 3) Wait for user approval
//     _sessionData = await connectResponse.session.future;
//
//     // 4) Retrieve the connected account: "eip155:1:0x12...AB" => "0x12...AB"
//     final String accountWithPrefix =
//         _sessionData!.namespaces.values.first.accounts.first;
//     final String address = accountWithPrefix.split(':').last;
//
//     setState(() {
//       account = address;
//     });
//     return account;
//   }
//
//   /// Check if the MetaMask app is installed on the device.
//   Future metamaskIsInstalled() async {
//     return await LaunchApp.isAppInstalled(
//       androidPackageName: 'io.metamask',
//       iosUrlScheme: 'metamask://',
//     );
//   }
//
//   /// Request to add or switch to another chain (e.g., BSC Testnet, Polygon).
//   Future<void> addChain(String chain) async {
//     // Optionally bring the user back to MetaMask if they are not in it.
//     await launchUrlString(
//       deepLinkUrl,
//       mode: LaunchMode.externalApplication,
//     );
//
//     Map<String, dynamic> params;
//     String targetChainId;
//
//     // 1) Evaluate which chain to add
//     if (chain == 'BSC Testnet') {
//       targetChainId = "eip155:97";
//       params = {
//         'chainId': '0x61', // 97 in hex
//         'chainName': 'Binance Smart Chain Testnet',
//         'nativeCurrency': {
//           'name': 'Binance Coin',
//           'symbol': 'BNB',
//           'decimals': 18,
//         },
//         'rpcUrls': ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
//         'blockExplorerUrls': ['https://testnet.bscscan.com'],
//       };
//     } else if (chain == 'Polygon') {
//       targetChainId = "eip155:137";
//       params = {
//         'chainId': '0x89', // 137 in hex
//         'chainName': 'Polygon Mainnet',
//         'nativeCurrency': {
//           'name': 'MATIC',
//           'symbol': 'MATIC',
//           'decimals': 18,
//         },
//         'rpcUrls': ['https://polygon-rpc.com/'],
//         'blockExplorerUrls': ['https://polygonscan.com'],
//       };
//     } else {
//       // Default to Ethereum Mainnet
//       targetChainId = "eip155:1";
//       params = {
//         'chainId': '0x1',
//         'chainName': 'Ethereum Mainnet',
//         'nativeCurrency': {
//           'name': 'Ether',
//           'symbol': 'ETH',
//           'decimals': 18,
//         },
//         'rpcUrls': ['https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID'],
//         'blockExplorerUrls': ['https://etherscan.io'],
//       };
//     }
//
//     // 2) Send wallet_addEthereumChain request
//     final Future<dynamic> chainResponse = await _walletConnect!.request(
//       topic: _sessionData!.topic,
//       chainId: targetChainId,
//       request: SessionRequestParams(
//         method: "wallet_addEthereumChain",
//         params: [params],
//       ),
//     );
//
//     // 3) Handle the result (for debugging, we just print to console)
//     final Stream chainStream = chainResponse.asStream();
//     chainStream.listen((dynamic event) {
//       print('$event connectChain');
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Example UI
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             const SizedBox(height: 100),
//             Center(
//               child: SizedBox(
//                 height: 220,
//                 width: 220,
//                 child: Image.asset("assets/images/metamask.png",
//                     fit: BoxFit.cover),
//               ),
//             ),
//             const Spacer(),
//             Center(
//               child: Text(
//                 "Connect to Metamask",
//                 style: GoogleFonts.barlow(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.buttonColor,
//                 ),
//               ),
//             ),
//             Center(
//               child: Text(
//                 "Connect your metamask wallet",
//                 style: GoogleFonts.barlow(fontSize: 14),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 70),
//
//             // Show the connected address if available
//             if (account != null) Text("$account"),
//
//             // If already connected, show OK button; else, show "Connect"
//             (account != null)
//                 ? AppButton(
//                     text: "OK",
//                     onPressed: () async {
//                       // Example OK logic
//                     },
//                   )
//                 : AppButton(
//                     text: "Connect",
//                     onPressed: () async {
//                       await createSession();
//                     },
//                   ),
//             const SizedBox(height: 16),
//
//             // Additional chain buttons if connected
//             if (account != null)
//               Column(
//                 children: [
//                   AppButton(
//                     text: "Add Binance Smart Chain Testnet",
//                     onPressed: () async {
//                       await addChain("BSC Testnet");
//                     },
//                   ),
//                   AppButton(
//                     text: "Add Polygon Mainnet",
//                     onPressed: () async {
//                       await addChain("Polygon");
//                     },
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
