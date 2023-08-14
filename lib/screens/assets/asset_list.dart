import 'package:crs_manager/screens/assets/asset_page.dart';
import 'package:crs_manager/screens/assets/optical_textformfield.dart';
import 'package:crs_manager/screens/challans/challan_widget.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/asset.dart';
import '../../utils/constants.dart';

class AssetList extends StatefulWidget {
  const AssetList({super.key, required this.allAssets});

  final List<Asset> allAssets;

  @override
  State<AssetList> createState() => AssetListState();
}

class AssetListState extends State<AssetList> {
  String filter = "";
  var filterController = TextEditingController();
  var recentAssets = <Asset>[];

  @override
  void initState() {
    super.initState();
    recentAssets = (widget.allAssets
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .toList()
        .sublist(
            0, widget.allAssets.length >= 50 ? 50 : widget.allAssets.length);
  }

  @override
  Widget build(BuildContext context) {
    List<Asset> assets;
    if (filter.isNotEmpty) {
      assets = (widget.allAssets.where(
        (asset) {
          return asset.uuid.contains(filter);
        },
      ).toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ));
    } else {
      assets = recentAssets;
    }

    return Padding(
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

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6.0, horizontal: 6.0),
                        elevation: 4,
                        child: ListTile(
                          title: Text(asset.template.name),
                          subtitle: Text(asset.uuid),
                          trailing: Text(formatter.format(asset.createdAt)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssetPage(
                                  asset: asset,
                                ),
                              ),
                            );
                          },
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
    );
  }
}
