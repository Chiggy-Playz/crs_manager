import 'package:crs_manager/screens/assets/outer_asset_list.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';

import '../../models/asset.dart';

class ChooseAsset extends StatelessWidget {
  const ChooseAsset({
    super.key,
    this.multiple = true,
    this.outwards = true,
    required this.onAssetSelected,
  });

  final bool multiple;
  final void Function(List<Asset>) onAssetSelected;
  final bool outwards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("Choose Asset"),
      ),
      body: OuterAssetListWidget(
        multiple: multiple,
        onAssetSelected: onAssetSelected,
        outwards: outwards,
      ),
    );
  }
}
