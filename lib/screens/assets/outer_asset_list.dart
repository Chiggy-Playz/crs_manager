import 'package:crs_manager/models/asset.dart';
import 'package:crs_manager/models/template.dart';
import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/assets/inner_asset_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/asset_select.dart';
import 'asset_page.dart';

class OuterAssetListWidget extends StatefulWidget {
  const OuterAssetListWidget({
    super.key,
    this.multiple = true,
    this.outwards = true,
    this.comingFrom,
    required this.onAssetSelected,
  });

  final bool multiple;
  final void Function(List<Asset>) onAssetSelected;
  final bool outwards;
  final String? comingFrom;

  @override
  State<OuterAssetListWidget> createState() => _OuterAssetListWidgetState();
}

class _OuterAssetListWidgetState extends State<OuterAssetListWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseModel>(
      builder: (context, db, child) {
        var allAssets = db.assets.values;
        Map<int, List<Asset>> assetsGroupedByTemplate = {};

        for (var asset in allAssets) {
          if (assetsGroupedByTemplate[asset.template.id] == null) {
            assetsGroupedByTemplate[asset.template.id] = [];
          }
          assetsGroupedByTemplate[asset.template.id]!.add(asset);
        }

        var templates = List<Template>.from(db.templates)
            .where(
                (element) => assetsGroupedByTemplate.keys.contains(element.id))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.h),
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              var template = templates[index];
              List<Asset> assets = assetsGroupedByTemplate[template.id] ?? [];
              return Card(
                elevation: 4,
                child: ListTile(
                  title: Text(template.name),
                  trailing: Text("${assets.length} assets"),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => AssetSelectionProvider(
                          onAssetSelected: widget.onAssetSelected,
                          multiple: widget.multiple,
                          outwards: widget.outwards,
                          comingFrom: widget.comingFrom),
                      child: InnerAssetListPage(
                        template: template,
                      ),
                    ),
                  )),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
