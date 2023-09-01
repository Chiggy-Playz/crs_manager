import 'package:crs_manager/models/asset.dart';
import 'package:crs_manager/providers/asset_select.dart';
import 'package:crs_manager/utils/classes.dart';
import 'package:crs_manager/utils/template_string.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'asset_page.dart';

class InnerAssetListPage extends StatefulWidget {
  const InnerAssetListPage({super.key, required this.assets});

  final List<Asset> assets;

  @override
  State<InnerAssetListPage> createState() => _InnerAssetListPageState();
}

class _InnerAssetListPageState extends State<InnerAssetListPage> {
  Map<MapKey, List<Asset>> groupedAssets = {};

  @override
  void initState() {
    super.initState();

    for (var asset in widget.assets) {
      var key = MapKey(asset.rawCustomFields);
      if (groupedAssets[key] == null) {
        groupedAssets[key] = [];
      }
      groupedAssets[key]!.add(asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetSelectionProvider>(
      builder: (context, selector, child) => Scaffold(
        appBar: TransparentAppBar(
          title: const Text("Choose Asset"),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.h),
          child: ListView.builder(
            itemCount: groupedAssets.length,
            itemBuilder: (context, index) {
              var key = groupedAssets.keys.toList()[index];
              var assets = groupedAssets[key]!;

              var asset = assets.first;
              var metadata = asset.template.metadata;
              String title = asset.uuid;
              String? subtitle = "";

              int inStockCount = assets
                  .where((element) => element.location == "Office")
                  .length;

              bool assetsInStock =
                  assets.any((element) => element.location == "Office");

              if (metadata.isNotEmpty) {
                title = TemplateString(metadata.split("\n").first)
                    .format(asset.rawCustomFields);

                if (metadata.contains("\n")) {
                  subtitle = TemplateString(metadata.split("\n").last)
                      .format(asset.rawCustomFields);
                }
              } else {
                title += " - ${assets.last.uuid}";
                subtitle = TemplateString(metadata).format(asset.customFields);
              }

              Widget inStockWidget = SizedBox(
                width: 15.w,
                child: Text(
                  assetsInStock ? "In Stock" : "Out of Stock",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: assetsInStock
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              );

              Widget secondary = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("$inStockCount / ${assets.length}"),
                  inStockWidget,
                ],
              );

              return Card(
                elevation: 4,
                //  Only show checkbox list tile if its a single asset
                //  Since there shouldn't be merging of different types of assets in a single product
                child: selector.multiple && assets.length == 1
                    ? CheckboxListTile(
                        value: selector.selectedAssets
                            .containsKey(MapKey(assets.first.rawCustomFields)),
                        onChanged: (val) async {
                          if (val!) {
                            await onTap(assets, selector);
                          } else {
                            selector.removeAsset(assets);
                          }
                        },
                        title: Text(title),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                        controlAffinity: ListTileControlAffinity.leading,
                        secondary: secondary,
                      )
                    : ListTile(
                        title: Text(title),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                        trailing: secondary,
                        onTap: () async => await onTap(assets, selector),
                      ),
              );
            },
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (selector.multiple)
              FloatingActionButton(
                heroTag: "Save",
                onPressed: () {
                  // This is only called when individual assets are selected
                  // Return the selected assets as List<Asset>
                  selector.onAssetSelected(
                    selector.selectedAssets.values.expand((e) => e).toList(),
                  );
                  // Navigator.of(context).pop(selector.selectedAssets.values);
                },
                child: const Icon(Icons.check),
              ),
            SizedBox(height: 2.h),
            FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AssetPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onTap(
      List<Asset> assets, AssetSelectionProvider selector) async {
    // Determine assets first
    List<Asset> selectedAssets;

    if (!selector.multiple) {
      selectedAssets = assets;
    } else {
      selectedAssets =
          assets.length == 1 ? assets : (await selectAssets(assets) ?? []);
    }

    // means that the user pressed cancel while selecting assets
    if (selectedAssets.isEmpty) {
      return;
    }

    if (selector.multiple) {
      selector.addAsset(selectedAssets);

      // If an asset group was selected, then we're done and need to pop
      // Since we don't need to select any more assets ( they'd be going in a new product )
      if (assets.length > 1) {
        selector.onAssetSelected(selectedAssets);
      }
    } else {
      selector.onAssetSelected(selectedAssets);
    }
  }

  Future<List<Asset>?> selectAssets(List<Asset> assets) async {
    // Show a dialogbox asking how many to select
    // Just input a number between 1 and the length of asset
    // Also validate input
    // Then return the selected assets

    int selectedCount = 1;

    int maxCount =
        assets.where((element) => element.location == "Office").length;

    selectedCount = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Multiple Assets"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How many assets would you like to create?"),
            SizedBox(height: 2.h),
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(labelText: "Number of Assets"),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a number';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (int.parse(value) < 1) {
                  return 'Please enter a number greater than or equal to 1';
                }
                if (int.parse(value) > maxCount) {
                  return 'Please enter a number less than or equal to $maxCount';
                }
                return null;
              },
              onChanged: (value) =>
                  selectedCount = int.tryParse(value) ?? selectedCount,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(0),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (selectedCount <= 0 || selectedCount > maxCount) {
                return;
              }
              Navigator.of(context).pop(selectedCount);
            },
            child: const Text("Select"),
          ),
        ],
      ),
    );

    // Check if the user pressed cancel
    if (selectedCount == 0) {
      return null;
    }
    // Return only those assets which are in Office and only the first selectedCount
    return assets
        .where((element) => element.location == "Office")
        .take(selectedCount)
        .toList();
  }
}
