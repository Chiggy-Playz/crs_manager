import 'package:crs_manager/models/challan.dart';
import 'package:crs_manager/screens/challans/product_page.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ProductWidget extends StatefulWidget {
  const ProductWidget({
    super.key,
    required this.products,
    this.viewOnly = false,
    this.outwards = true,
    this.onAddProduct,
    this.onEditProduct,
    this.onUpdate,
  });

  final List<Product> products;
  final bool viewOnly;
  final Function? onAddProduct;
  final Function(int index)? onEditProduct;
  final Function? onUpdate;
  final bool outwards;

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  List<Product> get products => widget.products;
  bool get viewOnly => widget.viewOnly;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45.h,
      width: double.infinity,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(
            children: [
              Text(
                "Products",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return productCard(index);
                  },
                ),
              ),
              SizedBox(height: 2.h),
              FloatingActionButton.extended(
                heroTag: "addProduct",
                onPressed: viewOnly ? null : onAddProduct,
                label: const Text("Add Product"),
                icon: const Icon(Icons.add),
              )
            ],
          ),
        ),
      ),
    );
  }

  Card productCard(int index) {
    String subtitle =
        "${products[index].additionalDescription}\n${products[index].quantity} ${products[index].quantityUnit}\n${products[index].serial}"
            .trim();
    return Card(
      elevation: 12,
      child: ListTile(
        title: Text(products[index].description),
        subtitle: Text(
          subtitle,
        ),
        isThreeLine: subtitle.contains("\n"),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
          onPressed: viewOnly
              ? null
              : () {
                  setState(() {
                    products.removeAt(index);
                  });
                  if (widget.onUpdate != null) widget.onUpdate!();
                },
        ),
        onTap: viewOnly
            ? null
            : (widget.onEditProduct == null
                ? () => onEditProduct(index)
                : widget.onEditProduct!(index)),
      ),
    );
  }

  void onAddProduct() async {
    // null represents backed out
    Product? result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProductPage(outwards: widget.outwards,),
    ));

    if (result != null) {
      setState(() {
        products.add(result);
      });
    }
    if (widget.onUpdate != null) widget.onUpdate!();
  }

  void onEditProduct(int index) async {
    // null represents backed out
    Product? result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProductPage(product: products[index], outwards: widget.outwards,),
    ));

    if (result != null) {
      setState(() {
        products[index] = result;
      });
    }
    if (widget.onUpdate != null) widget.onUpdate!();
  }
}
