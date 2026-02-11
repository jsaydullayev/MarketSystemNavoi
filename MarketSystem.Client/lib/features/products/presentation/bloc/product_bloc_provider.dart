/// Product Bloc Provider
/// Provides ProductBloc to widget tree
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/product_bloc.dart';

/// Product Bloc Provider
class ProductBlocProvider extends BlocProvider<ProductBloc, ProductState> {
  ProductBlocProvider({required super.key})
      : super(
          key: key,
          create: (_) => ProductBloc(
            // Dependencies will be injected via DI later
          ),
        );
}

/// Placeholder widget to show bloc is ready
class ProductBlocPlaceholder extends StatelessWidget {
  const ProductBlocPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Product Bloc Ready! 🎯\nProducts = ...'),
      ),
    );
  }
}
