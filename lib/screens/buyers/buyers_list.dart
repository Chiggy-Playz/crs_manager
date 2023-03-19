import 'package:crs_manager/providers/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/buyer.dart';

class BuyersList extends StatefulWidget {
  const BuyersList({super.key});

  @override
  State<BuyersList> createState() => _BuyersListState();
}

Text _text(BuildContext context, String text) {
  return Text(
    text,
    style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
  );
}

class _BuyersListState extends State<BuyersList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseModel>(
      builder: (context, value, child) {
        List<Buyer> buyers = value.buyers;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: buyers.length,
            itemBuilder: (context, index) {
              Buyer buyer = buyers[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                padding: EdgeInsets.all(6),
                margin:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                child: ListTile(
                  title: _text(
                    context,
                    buyer.name,
                  ),
                  subtitle: _text(context, buyer.address.split("\n")[0]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
