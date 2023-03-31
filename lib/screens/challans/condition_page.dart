import 'package:crs_manager/providers/buyer_select.dart';
import 'package:crs_manager/screens/buyers/choose_buyer.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/buyer.dart';
import '../../models/condition.dart';
import '../../utils/constants.dart';

List<DropdownMenuItem<ConditionType>> conditionOptions = const [
  DropdownMenuItem(
    value: ConditionType.buyers,
    child: Text("Buyer(s)"),
  ),
  DropdownMenuItem(
    value: ConditionType.date,
    child: Text("Date Range"),
  ),
  DropdownMenuItem(
    value: ConditionType.product,
    child: Text("Product"),
  ),
  DropdownMenuItem(
    value: ConditionType.fields,
    child: Text("Fields"),
  ),
  DropdownMenuItem(
    value: ConditionType.raw,
    child: Text("Raw"),
  ),
];

class ConditionPage extends StatefulWidget {
  const ConditionPage({super.key, this.condition});

  final Condition? condition;

  @override
  State<ConditionPage> createState() => _ConditionPageState();
}

class _ConditionPageState extends State<ConditionPage> {
  ConditionType? _selectedCondition;
  dynamic _value;

  @override
  void initState() {
    super.initState();
    if (widget.condition != null) {
      _selectedCondition = widget.condition!.type;
      _value = widget.condition!.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title:
            Text(widget.condition == null ? "Add Condition" : "Edit Condition"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _onSavePressed,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
        child: Column(
          children: [
            SpacedRow(
                widget1: Text(
                  "Condition Type",
                  style: font(22),
                ),
                widget2: SizedBox(
                  width: 50.w,
                  child: DropdownButton(
                    items: conditionOptions,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedCondition = value;
                      });
                    },
                    value: _selectedCondition,
                  ),
                )),
            if (_selectedCondition != null) _conditionWidget()
          ],
        ),
      ),
      floatingActionButton: _fab(),
    );
  }

  void _onSavePressed() {
    // Validate value

    String errorMessage = "";
    switch (_selectedCondition) {
      case ConditionType.buyers:
        if (_value is! List<Buyer> || (_value as List<Buyer>).isEmpty) {
          errorMessage = "Please select at least 1 buyer";
        }
        break;
      case ConditionType.date:
        if (_value is! DateTimeRange) {
          errorMessage = "Please select a date range";
        }
        break;
      case ConditionType.product:
        if (_value is! String || _value.isEmpty) {
          errorMessage = "Please type in a value";
        }
        break;
      case ConditionType.fields:
        if (_value is! List<String>) {
          print(
              "Change validation here for field later (type above from List<String>)");
          errorMessage = "Please define at least 1 field";
        }
        break;
      case ConditionType.raw:
        if (_value is! String) {
          errorMessage = "Please type in a value";
        }
        break;
      case null:
        errorMessage = "Please select a condition type";
    }

    if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
      return;
    }

    Condition condition = Condition(
      _selectedCondition!,
      _value,
    );
    Navigator.of(context).pop(condition);
  }

  FloatingActionButton? _fab() {
    if ([
      ConditionType.buyers,
      ConditionType.date,
      ConditionType.fields,
    ].contains(_selectedCondition)) {
      return FloatingActionButton(
        heroTag: "fab",
        onPressed: _fabPress,
        child: Icon(
          _selectedCondition == ConditionType.date
              ? Icons.calendar_month
              : Icons.add,
        ),
      );
    }
    return null;
  }

  void _fabPress() async {
    switch (_selectedCondition) {
      case ConditionType.buyers:
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
          return;
        }

        setState(() {
          if (_value is! List<Buyer>) {
            _value = <Buyer>[];
          }

          if (buyers != null) {
            for (Buyer buyer in buyers) {
              if (!_value.contains(buyer)) {
                _value.add(buyer);
              }
            }
          } else {
            if (!_value.contains(buyer)) {
              _value.add(buyer);
            }
          }
        });
        break;

      case ConditionType.date:
        DateTimeRange? range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020, 01, 01, 00, 00, 00),
          lastDate: DateTime.now(),
        );

        if (range == null) {
          return;
        }

        setState(() {
          _value = range;
        });

        break;
    }
  }

  Widget _conditionWidget() {
    switch (_selectedCondition) {
      case ConditionType.buyers:
        return _buyersWidget();
      case ConditionType.date:
        return _dateWidget();
      case ConditionType.product:
        return _productWidget();
      case ConditionType.fields:
        return _fieldsWidget();
      case ConditionType.raw:
        return _rawWidget();
      // Shouldn't reach here like, ever
      case null:
        return const Placeholder();
    }
  }

  Widget _buyersWidget() {
    // Since buyers, the value will be of type List<Buyer>
    _value ??= <Buyer>[];
    var buyers = _value as List<Buyer>;
    if (_value == null || buyers.isEmpty) {
      return const ListTile(
        title: Text("Use the + button to select buyers"),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: buyers.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 12,
          child: ListTile(
            title: Text(buyers[index].name),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                setState(() {
                  buyers.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _dateWidget() {
    if (_value == null) {
      return const ListTile(
        title: Text("Use the edit button to select a date range"),
      );
    }
    var range = _value as DateTimeRange;
    return ListTile(
        title: Text(
            "Challans between ${formatterDate.format(range.start)} and ${formatterDate.format(range.end)}"));
  }

  Widget _productWidget() {
    return TextFormField(
      onChanged: (value) {
        _value = value;
      },
      initialValue: _value as String?,
      decoration: const InputDecoration(
        labelText: "Product",
        hintText: "Enter description, serial, or additional description",
      ),
    );
  }

  Widget _fieldsWidget() {
    return const Placeholder();
  }

  Widget _rawWidget() {
    return const Placeholder();
  }
}
