import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/condition.dart';
import 'condition_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Condition> _conditions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(title: const Text("Search")),
      body: Padding(
        padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 0),
        child: Column(children: [
          SizedBox(
            height: 45.h,
            width: double.infinity,
            child: Card(
              elevation: 12,
              child: Padding(
                padding: EdgeInsets.all(2.h),
                child: Column(
                  children: [
                    const Text("Conditions"),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _conditions.length,
                        itemBuilder: conditionCard,
                      ),
                    ),
                    FloatingActionButton.extended(
                      onPressed: addCondition,
                      label: const Text("Add Condition"),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget conditionCard(context, int index) {
    return const Placeholder();
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
      });
    }
  }
}
