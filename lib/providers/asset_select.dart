import 'package:flutter/foundation.dart';

import '../models/asset.dart';
import '../utils/classes.dart';

typedef VoidACallback = void Function(List<Asset> assets);

class AssetSelectionProvider extends ChangeNotifier {
  Map<MapKey, List<Asset>> selectedAssets = {};
  final VoidACallback onAssetSelected;
  final bool multiple;
  final bool outwards;
  final String? comingFrom;

  AssetSelectionProvider({
    required this.onAssetSelected,
    this.multiple = false,
    this.outwards = true,
    this.comingFrom,
  });

  void addAsset(List<Asset> assets) {
    var key = MapKey(assets.first.rawCustomFields);
    selectedAssets[key] = assets;

    notifyListeners();
  }

  void removeAsset(List<Asset> assets) {
    var key = MapKey(assets.first.rawCustomFields);
    selectedAssets.remove(key);
    notifyListeners();
  }
}
