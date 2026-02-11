/// Product Bloc Provider
/// Provides ProductBloc to widget tree

import 'package:flutter/material.dart';

/// Placeholder widget to show bloc is ready
class ProductBlocPlaceholder extends StatelessWidget {
  const ProductBlocPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Product feature coming soon! 🎯\nProducts = ...'),
      ),
    );
  }
}
