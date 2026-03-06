// lib/features/customers/presentation/screens/customers_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/features/customers/presentation/widgets/add_customer_sheet.dart';
import 'package:market_system_client/features/customers/presentation/widgets/customers_card.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import '../bloc/customers_bloc.dart';
import '../bloc/events/customers_event.dart';
import '../bloc/states/customers_state.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(const GetCustomersEvent());
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      Future.delayed(Duration.zero, () {
        context.read<CustomersBloc>().add(const GetCustomersEvent());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterCustomers(
      List<Map<String, dynamic>> customers) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return customers;
    return customers.where((c) {
      return (c['fullName'] ?? '').toLowerCase().contains(query) ||
          (c['phone'] ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CustomersBloc>(),
        child: const AddCustomerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<CustomersBloc, CustomersState>(
      listener: (context, state) {
        if (state is CustomerDeleted || state is CustomerCreated) {
          final msg = state is CustomerDeleted
              ? l10n.customerDeleted
              : l10n.customerAdded;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
          );
          context.read<CustomersBloc>().add(const GetCustomersEvent());
        } else if (state is CustomersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: NetworkWrapper(
        onRetry: () =>
            context.read<CustomersBloc>().add(const GetCustomersEvent()),
        child: Scaffold(
          backgroundColor: AppColors.getBg(isDark),
          appBar: CommonAppBar(
            title: l10n.customers,
            onRefresh: () =>
                context.read<CustomersBloc>().add(const GetCustomersEvent()),
          ),
          body: Column(
            children: [
              _SearchBar(controller: _searchController),
              Expanded(child: _CustomersList(filter: _filterCustomers)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddSheet,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: Text(l10n.addNewCustomer,
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.searchCustomer,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: controller.clear,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _CustomersList extends StatelessWidget {
  const _CustomersList({required this.filter});
  final List<Map<String, dynamic>> Function(List<Map<String, dynamic>>) filter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersBloc, CustomersState>(
      builder: (context, state) {
        if (state is CustomersLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CustomersError) {
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<CustomersBloc>().add(const GetCustomersEvent()),
          );
        }

        if (state is CustomersLoaded) {
          final filtered =
              filter(state.customers.map((e) => e.toJson()).toList());

          if (filtered.isEmpty) {
            return _EmptyView(isSearching: false);
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<CustomersBloc>().add(const GetCustomersEvent()),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => CustomersCard(customer: filtered[i]),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry)),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isSearching});
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isSearching ? l10n.customerNotFound : l10n.noCustomers,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
