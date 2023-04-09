import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/challans/search/table_view.dart';
import 'package:crs_manager/screens/challans/search/tree_view.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../models/challan.dart';
import '../../../models/condition.dart';
import '../../../utils/constants.dart';
import '../challans_list.dart';
import 'condition_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // ignore: prefer_final_fields
  List<Condition> _conditions = [];
  List<Challan> _challans = [];
  bool _searched = false;
  bool _treeView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("Search"),
        actions: [
          IconButton(
            icon: !_treeView
                ? const Icon(Icons.park_outlined)
                : Icon(Icons.park,
                    color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              setState(() {
                _treeView = !_treeView;
              });
            },
          ),
          if (_challans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.grid_on),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TableViewPage(challans: _challans),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(2.w, 0, 2.w, 0),
        child: SingleChildScrollView(
          child: Column(children: [
            SizedBox(
              height: 30.h,
              width: double.infinity,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(2.h),
                  child: Column(
                    children: [
                      Text("Conditions", style: font(24)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _conditions.length,
                          itemBuilder: conditionCard,
                        ),
                      ),
                      FloatingActionButton.extended(
                        heroTag: "addCondition",
                        onPressed: addCondition,
                        label: const Text("Add Condition"),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            if (_challans.isNotEmpty) ...[
              Text("${_challans.length} Challans", style: font(20)),
            ],
            // If challans is empty and condition also empty, ask user to add a condition and search
            // If challans is empty, condition is not empty and not yet searched for, ask user to search
            // If challans is empty, condition is not empty and searched for, show no challans found
            // If challans is not empty, show the list of challans
            // This is totally readable, was written by me, and not by copilot. Totally.
            _challans.isEmpty
                ? _conditions.isEmpty
                    ? Text("Add some conditions!", style: font(25))
                    : _searched
                        ? Center(
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              brokenMagnifyingGlassSvg,
                              SizedBox(height: 2.h),
                              const Text("No challans found :("),
                            ],
                          ))
                        : Text("Search for challans", style: font(25))
                : _treeView
                    ? treeView()
                    : ChallansList(challans: _challans)
          ]),
        ),
      ),
      floatingActionButton: _conditions.isNotEmpty
          ? FloatingActionButton(
              heroTag: "fab",
              child: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _challans = Provider.of<DatabaseModel>(context, listen: false)
                      .filterChallan(conditions: _conditions);
                  _searched = true;
                });
              },
            )
          : null,
    );
  }

  Widget treeView() {
    return TreeViewWidget(
      challans: _challans,
    );
  }

  Widget conditionCard(context, int index) {
    Condition condition = _conditions[index];
    Icon? leading;
    String title = "";
    String? value = "";

    switch (condition.type) {
      case ConditionType.buyers:
        leading = const Icon(Icons.groups);
        title = "If buyer is one of specified Buyers";
        value = null;
        break;
      case ConditionType.product:
        title = "If product's description or serial number contains: ";
        value = condition.value as String;
        break;
      case ConditionType.date:
        var range = condition.value as DateTimeRange;
        title = "If the challan was created between: ";
        value =
            "${formatterDate.format(range.start)} and ${formatterDate.format(range.end)}";
        break;
      case ConditionType.raw:
        title = "If challan contains the keyword: ";
        break;
      case ConditionType.fields:
        title = "If the fields contains the values: ";
        break;
    }

    return Card(
      elevation: 12,
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: value != null ? Text(value) : null,
        isThreeLine: value != null,
        trailing: IconButton(
          icon: Icon(
            Icons.delete,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            setState(() {
              _conditions.removeAt(index);
              _searched = false;
            });
          },
        ),
        onTap: () async {
          await onConditionTap(condition);
        },
      ),
    );
  }

  Future<void> onConditionTap(Condition condition) async {
    Condition? newCondition = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConditionPage(condition: condition),
      ),
    );

    if (newCondition != null) {
      setState(() {
        _conditions[_conditions.indexOf(condition)] = newCondition;
        _searched = false;
      });
    }
  }

  void addCondition() async {
    Condition? condition = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConditionPage(),
      ),
    );

    if (condition != null) {
      setState(() {
        _conditions.add(condition);
        _searched = false;
      });
    }
  }
}
