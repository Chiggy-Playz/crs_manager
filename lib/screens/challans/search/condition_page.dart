import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';

import '../../../models/buyer.dart';
import '../../../models/condition.dart';

class ConditionPage extends StatefulWidget {
  const ConditionPage({super.key, required this.condition});

  final Condition condition;

  @override
  State<ConditionPage> createState() => _ConditionPageState();
}

class _ConditionPageState extends State<ConditionPage> {

  @override
  Widget build(BuildContext context) {
    late Widget body;

    switch (widget.condition.type) {
      case ConditionType.buyers:
        body = BuyerConditionPage(
            condition: widget.condition as Condition<List<Buyer>>);
        break;
      case ConditionType.fields:
        body = FieldConditionPage(condition: widget.condition);
        break;
      default:
        body = const Placeholder();
    }

    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("Edit Condition"),
      ),
      body: body,
    );
  }
}

class BuyerConditionPage extends StatefulWidget {
  const BuyerConditionPage({super.key, required this.condition});

  final Condition<List<Buyer>> condition;

  @override
  State<BuyerConditionPage> createState() => _BuyerConditionPageState();
}

class _BuyerConditionPageState extends State<BuyerConditionPage> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.condition.value.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 12,
          child: ListTile(
            title: Text(widget.condition.value[index].name),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                setState(() {
                  widget.condition.value.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }
}

class FieldConditionPage extends StatefulWidget {
  const FieldConditionPage({super.key, required this.condition});

  final Condition condition;

  @override
  State<FieldConditionPage> createState() => _FieldConditionPageState();
}

class _FieldConditionPageState extends State<FieldConditionPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
