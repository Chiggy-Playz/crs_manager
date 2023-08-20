import 'package:crs_manager/providers/asset_select.dart';
import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/assets/asset_page.dart';
import 'package:crs_manager/screens/assets/optical_textformfield.dart';
import 'package:crs_manager/screens/challans/challan_widget.dart';
import 'package:crs_manager/utils/template_string.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/asset.dart';
import '../../utils/constants.dart';

class AssetList extends StatefulWidget {
  const AssetList({super.key});

  @override
  State<AssetList> createState() => AssetListState();
}

class AssetListState extends State<AssetList> {
  String filter = "";
  var filterController = TextEditingController();
  late Offset _tapDownPosition;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseModel>(builder: (context, db, child) {
      List<Asset> assets = db.assets.values.toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
      if (filter.isNotEmpty) {
        assets = (assets.where(
          (asset) {
            return asset.uuid.contains(filter);
          },
        ).toList()
          ..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          ));
      }

      return Consumer<AssetSelectionProvider>(
        builder: (context, selector, child) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.h),
          child: Column(
            children: [
              SizedBox(
                height: 10.h,
                child: OpticalTextFormField(
                  initialValue: "",
                  labelText: "Search by asset uuid",
                  onChanged: (value) async {
                    setState(() {
                      if (value == null || value.isEmpty) {
                        filter = value!;
                      } else {
                        filter = value;
                      }
                    });
                  },
                ),
              ),
              assets.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: assets.length,
                        itemBuilder: (context, index) {
                          Asset asset = assets[index];

                          return GestureDetector(
                            onTapDown: (TapDownDetails details) {
                              _tapDownPosition = details.globalPosition;
                            },
                            onSecondaryTapDown: (details) {
                              _tapDownPosition = details.globalPosition;
                            },
                            onSecondaryTapCancel: () =>
                                showContextMenu(asset: asset),
                            onLongPress: () => showContextMenu(asset: asset),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6.0, horizontal: 6.0),
                              elevation: 4,
                              child: selector.multiple
                                  ? CheckboxListTile(
                                      title: Text(asset.template.name),
                                      subtitle: asset.template.metadata.isEmpty
                                          ? Text(asset.uuid)
                                          : Text(TemplateString(
                                                  asset.template.metadata)
                                              .format(asset.customFields
                                                  .map((key, value) => MapEntry(
                                                        key,
                                                        value.getValue(),
                                                      )))),
                                      isThreeLine: asset.template.metadata
                                          .contains("\n"),
                                      value: selector.selectedAssets.contains(
                                        asset,
                                      ),
                                      onChanged: (value) {
                                        if (value!) {
                                          selector.addAsset(asset);
                                        } else {
                                          selector.removeAsset(asset);
                                        }
                                      },
                                    )
                                  : ListTile(
                                      title: Text(asset.template.name),
                                      subtitle: asset.template.metadata.isEmpty
                                          ? Text(asset.uuid)
                                          : Text(TemplateString(
                                                  asset.template.metadata)
                                              .format(asset.customFields
                                                  .map((key, value) => MapEntry(
                                                        key,
                                                        value.getValue(),
                                                      )))),
                                      isThreeLine: asset.template.metadata
                                          .contains("\n"),
                                      trailing: Text(
                                          formatter.format(asset.createdAt)),
                                      onTap: () =>
                                          selector.onAssetSelected(asset),
                                    ),
                            ),
                          );
                        },
                      ),
                    )
                  : Expanded(
                      child: Center(
                          child: Column(
                        children: [
                          brokenMagnifyingGlassSvg,
                          SizedBox(height: 2.h),
                          const Text("No assets found :("),
                        ],
                      )),
                    )
            ],
          ),
        ),
      );
    });
  }

  void showContextMenu({
    TapUpDetails? details,
    required Asset asset,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    if (details != null) {
      _tapDownPosition = details.globalPosition;
    }

    var value = await showMenu<int>(
      context: context,
      items: [
        const PopupMenuItem(value: 0, child: Text("Clone Asset")),
      ],
      position: RelativeRect.fromLTRB(
        _tapDownPosition.dx,
        _tapDownPosition.dy,
        overlay.size.width - _tapDownPosition.dx,
        overlay.size.height - _tapDownPosition.dy,
      ),
    );

    if (value == null) {
      return;
    }
    if (!mounted) return;
    if (value == 0) {
      // Copy challan
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AssetPage(
            copyFromAsset: asset,
          ),
        ),
      );
    }
  }
}
