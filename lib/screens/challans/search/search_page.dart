import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/buyers/choose_buyer.dart';
import 'package:crs_manager/screens/challans/search/table_view.dart';
import 'package:crs_manager/screens/challans/search/tree_view.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../models/buyer.dart';
import '../../../models/challan.dart';
import '../../../models/condition.dart';
import '../../../providers/buyer_select.dart';
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
  List<ChallanBase> _challans = [];
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
    switch (condition.type) {
      case ConditionType.buyers:
      case ConditionType.fields:
        // Condition is mutated...
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConditionPage(
              condition: condition,
            ),
          ),
        );
        // If all buyers removed, remove the condition
        if (condition.type == ConditionType.buyers) {
          if (condition.value.isEmpty) {
            setState(() {
              _conditions.remove(condition);
              _searched = false;
            });
            return;
          }
        }
        break;
      case ConditionType.product:
      case ConditionType.raw:
        String? keyword = await getKeyword(initialText: condition.value);
        if (keyword == null) return;
        setState(() {
          condition.value = keyword;
        });
        break;
      case ConditionType.date:
        var newCondition = await getDateRange();
        if (newCondition == null) return;
        setState(() {
          condition.value = newCondition.value;
        });
        break;
    }
  }

  void addCondition() async {
    // show radiolist as dialog
    var dialog = AlertDialog(
      title: const Center(child: Text("Add condition")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("If buyer is one of specified Buyers"),
            onTap: () => Navigator.pop(context, ConditionType.buyers),
          ),
          ListTile(
            title: const Text(
                "If product's description or serial number contains keyword"),
            onTap: () => Navigator.pop(context, ConditionType.product),
          ),
          ListTile(
            title: const Text("If the challan was created between"),
            onTap: () => Navigator.pop(context, ConditionType.date),
          ),
          ListTile(
            title: const Text("Raw search"),
            onTap: () => Navigator.pop(context, ConditionType.raw),
          ),
          ListTile(
            title: const Text("If the fields contains the values"),
            onTap: () => Navigator.pop(context, ConditionType.fields),
          ),
        ],
      ),
    );

    ConditionType? conditionType = await showDialog<ConditionType>(
      context: context,
      builder: (context) => dialog,
    );

    if (conditionType == null) return;
    if (!mounted) return;

    Condition? condition;

    switch (conditionType) {
      case ConditionType.buyers:
        condition = await chooseBuyers();
        break;
      case ConditionType.date:
        condition = await getDateRange();
        break;
      case ConditionType.product:
      case ConditionType.raw:
        String? keyword = await getKeyword();
        if (keyword == null) return;
        condition = Condition<String>(
          type: conditionType,
          value: keyword,
        );
        break;
      case ConditionType.fields:
        // : Handle this case.
        break;
    }

    if (condition != null) {
      setState(() {
        _conditions.add(condition!);
        _searched = false;
      });
    }
  }

  Future<Condition<List<Buyer>>?> chooseBuyers() async {
    Buyer? buyer;
    List<Buyer>? buyers = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => BuyerSelectionProvider(
            multiple: true,
            onBuyerSelected: (b) {
              buyer = b;
              Navigator.of(context).pop();
            },
          ),
          child: const ChooseBuyer(),
        ),
      ),
    );
    if (buyers == null && buyer == null) {
      return null;
    }

    return Condition<List<Buyer>>(
      type: ConditionType.buyers,
      value: buyers ?? [buyer!],
    );
  }

  Future<String?> getKeyword({String initialText = ""}) async {
    String? keyword = await showDialog<String>(
        context: context,
        builder: (context) {
          String keyword = "";
          return AlertDialog(
            title: const Text("Enter keyword"),
            content: TextFormField(
              initialValue: initialText,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Keyword",
              ),
              onChanged: (value) {
                keyword = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, keyword);
                },
                child: const Text("OK"),
              ),
            ],
          );
        });

    if (keyword == null) return null;

    return keyword;
  }

  Future<Condition<DateTimeRange>?> getDateRange() async {
    DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 01, 01, 00, 00, 00),
      lastDate: DateTime.now(),
    );

    if (range == null) return null;
    
    return Condition<DateTimeRange>(
      type: ConditionType.date,
      value: range,
    );
  }
}
