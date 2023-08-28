import 'package:flutter/material.dart';

import '../../models/asset.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key, required this.assets});

  final List<Asset> assets;

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
