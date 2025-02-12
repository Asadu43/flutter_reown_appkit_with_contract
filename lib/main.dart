import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:trail_task_flutter/home_page/HomePage.dart';

void main() {
  runApp(const MyApp());
}

/// This map now includes BSC Testnet plus the other test networks.
Map<String, List<ReownAppKitModalNetworkInfo>> test = {
  'eip155': [
    // 1) BSC Testnet
    ReownAppKitModalNetworkInfo(
      name: 'BSC Testnet',
      chainId: '97',
      currency: 'BNB',
      rpcUrl: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      explorerUrl: 'https://testnet.bscscan.com',
      isTestNetwork: true,
    ),
    // 2) Sepolia
    ReownAppKitModalNetworkInfo(
      name: 'Sepolia',
      chainId: '11155111',
      currency: 'SEP',
      rpcUrl: 'https://ethereum-sepolia.publicnode.com',
      explorerUrl: 'https://sepolia.etherscan.io/',
      isTestNetwork: true,
    ),
    // 3) Holesky
    ReownAppKitModalNetworkInfo(
      name: 'Holesky',
      chainId: '17000',
      currency: 'ETH',
      rpcUrl: 'https://rpc.holesky.test',
      explorerUrl: 'https://explorer.holesky.test',
      isTestNetwork: true,
    ),
    // 4) Mumbai
    ReownAppKitModalNetworkInfo(
      name: 'Mumbai',
      chainId: '80001',
      currency: 'MATIC',
      rpcUrl: 'https://polygon-mumbai-bor-rpc.publicnode.com',
      extraRpcUrls: [
        'https://rpc.ankr.com/polygon_mumbai',
        'https://polygon-testnet.public.blastapi.io',
        'https://polygon-mumbai.blockpi.network/v1/rpc/public',
      ],
      explorerUrl: 'https://mumbai.polygonscan.com',
      isTestNetwork: true,
    ),
    // 5) Amoy
    ReownAppKitModalNetworkInfo(
      name: 'Amoy',
      chainId: '80002',
      currency: 'MATIC',
      rpcUrl: 'https://rpc-amoy.polygon.technology/',
      extraRpcUrls: [],
      explorerUrl: 'https://amoy.polygonscan.com',
      isTestNetwork: true,
    )
  ],
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trail Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Trail Project'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// Example migration from web3modal to Reown AppKit, plus custom test networks.
class _MyHomePageState extends State<MyHomePage> {
  late ReownAppKitModal _appKitModal;

  @override
  void initState() {
    super.initState();
    // Create ReownAppKitModal
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: '6f427ccb9e72b1453b0e3c76b70a8741',
      metadata: const PairingMetadata(
        name: 'Example App',
        description: 'Example app description',
        url: 'https://reown.com/',
        icons: ['https://reown.com/logo.png'],
        redirect: Redirect(
          native: 'exampleapp://',
          universal: 'https://reown.com/exampleapp',
        ),
      ),
    );

    // Initialize the modal, then do setState
    _appKitModal.init().then((_) {
      setState(() {});
      // If you want to auto-add test networks after init:
      // _addBscTestnet();
    });
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Network selector (pulls from Reown's registry)
            AppKitModalNetworkSelectButton(
              appKit: _appKitModal,
              context: context,
            ),

            // Connect button
            AppKitModalConnectButton(
              appKit: _appKitModal,
              context: context,
            ),

            // If connected, show account button
            Visibility(
              visible: _appKitModal.isConnected,
              child: AppKitModalAccountButton(
                appKit: _appKitModal,
                context: context,
                appKitModal: _appKitModal,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_appKitModal.isConnected) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HomePage(appKitModal: _appKitModal),
                      ));
                }else {
                  const snackBar = SnackBar(content: Text('Please connect metamask'));

                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: const Text("Go to Next screen"),
            )
          ],
        ),
      ),
    );
  }
}
