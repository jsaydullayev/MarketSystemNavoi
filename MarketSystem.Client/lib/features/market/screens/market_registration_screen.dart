import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../data/services/market_service.dart';
import '../../../core/providers/auth_provider.dart';

class MarketRegistrationScreen extends StatefulWidget {
  const MarketRegistrationScreen({super.key});

  @override
  State<MarketRegistrationScreen> createState() =>
      _MarketRegistrationScreenState();
}

class _MarketRegistrationScreenState extends State<MarketRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subdomainController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _registerMarket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final marketService = MarketService(authProvider: authProvider);

      final response = await marketService.registerMarket(
        name: _nameController.text.trim(),
        subdomain: _subdomainController.text.trim().isEmpty
            ? null
            : _subdomainController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // ✅ NEW: Update access token if provided
      if (response.accessToken != null) {
        await authProvider.updateToken(response.accessToken!);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Show success dialog
        _showSuccessDialog(response);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(dynamic response) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        title: Text(l10n.marketRegisteredSuccess),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.marketName}: ${response.market.name}'),
            const SizedBox(height: 8),
            Text(
              l10n.nowYouCanAddUsers,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketRegistration),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  const Icon(
                    Icons.store,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    l10n.createYourMarket,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    l10n.enterMarketDetails,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Market Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.marketName,
                      hintText: l10n.exampleMyStore,
                      prefixIcon: const Icon(Icons.store),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterMarketName;
                      }
                      if (value.trim().length < 3) {
                        return l10n.marketNameTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subdomain (Optional)
                  TextFormField(
                    controller: _subdomainController,
                    decoration: InputDecoration(
                      labelText: l10n.subdomainOptional,
                      hintText: l10n.exampleMyStore,
                      prefixIcon: const Icon(Icons.link),
                      border: const OutlineInputBorder(),
                      helperText: l10n.canBeLeftEmpty,
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          !RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
                        return l10n.subdomainRules;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description (Optional)
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionOptional,
                      hintText: l10n.marketShortInfo,
                      prefixIcon: const Icon(Icons.description),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      return null; // Optional field
                    },
                  ),
                  const SizedBox(height: 32),

                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.afterMarketRegisterInfo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerMarket,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            l10n.registerMarket,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
