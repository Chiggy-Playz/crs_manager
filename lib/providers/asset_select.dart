import 'package:flutter/foundation.dart';

import '../models/asset.dart';

typedef VoidACallback = void Function(Asset asset);

class AssetSelectionProvider extends ChangeNotifier {
  List<Asset> selectedAssets = [];
  final VoidACallback onAssetSelected;
  final bool multiple;

  AssetSelectionProvider({required this.onAssetSelected, this.multiple = false});

  void addAsset(Asset asset) {
    selectedAssets.add(asset);
    notifyListeners();
  }

  void removeAsset(Asset asset) {
    selectedAssets.remove(asset);
    notifyListeners();
  }
}