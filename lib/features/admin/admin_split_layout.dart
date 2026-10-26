import 'package:flutter/material.dart';

class AdminSplitLayout extends StatelessWidget {
  const AdminSplitLayout({
    super.key,
    required this.listPanel,
    required this.formPanel,
  });

  final Widget listPanel;
  final Widget formPanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              Expanded(flex: 2, child: listPanel),
              const SizedBox(height: 12),
              Expanded(flex: 3, child: SingleChildScrollView(child: formPanel)),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: listPanel),
            const SizedBox(width: 18),
            Expanded(child: SingleChildScrollView(child: formPanel)),
          ],
        );
      },
    );
  }
}
