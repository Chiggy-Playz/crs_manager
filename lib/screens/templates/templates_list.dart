import 'package:crs_manager/providers/database.dart';
import 'package:crs_manager/screens/templates/template_page.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class TemplatesList extends StatefulWidget {
  const TemplatesList({super.key});

  @override
  State<TemplatesList> createState() => _TemplatesListState();
}

class _TemplatesListState extends State<TemplatesList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseModel>(builder: (context, value, child) {
      var templates = value.templates..sort((a, b) => a.name.compareTo(b.name));

      return Scaffold(
        appBar: TransparentAppBar(
          title: const Text("Templates"),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 4,
                child: ListTile(
                    title: Text(templates[index].name),
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TemplatePage(
                              template: templates[index],
                            ),
                          ),
                        )),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const TemplatePage(),
          )),
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}
