import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:market_system_client/core/routes/app_routes.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Introduction',
              _getPrivacyIntro(),
              theme,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Data Collection',
              _getDataCollection(),
              theme,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Data Usage',
              _getDataUsage(),
              theme,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Data Security',
              _getDataSecurity(),
              theme,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Your Rights',
              _getYourRights(),
              theme,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Contact Information',
              _getContactInfo(),
              theme,
            ),
            const SizedBox(height: 40),
            _buildFooter(context, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
          ),
        ),
      ],
    );
  }

  String _getPrivacyIntro() {
    return 'This Privacy Policy describes how MarketSystem collects, uses, and protects your personal information. By using our application, you agree to the terms of this policy.';
  }

  String _getDataCollection() {
    return 'We collect the following types of information:\n\n'
        '1. Personal Information: Name, email address, phone number\n'
        '2. Usage Data: How you interact with the application\n'
        '3. Device Information: Device type, operating system, unique device identifiers\n'
        '4. Business Data: Sales, inventory, customer information (if you are a business user)';
  }

  String _getDataUsage() {
    return 'We use the collected information for:\n\n'
        '• Providing and maintaining our services\n'
        '• Improving user experience\n'
        '• Processing transactions\n'
        '• Sending notifications about important updates\n'
        '• Analyzing usage patterns to enhance our services';
  }

  String _getDataSecurity() {
    return 'We take data security seriously and implement appropriate measures to protect your information:\n\n'
        '• Encryption of sensitive data in transit and at rest\n'
        '• Regular security audits\n'
        '• Access controls and authentication\n'
        '• Secure data storage and backup systems';
  }

  String _getYourRights() {
    return 'You have the following rights regarding your data:\n\n'
        '• Access to your personal information\n'
        '• Request correction of inaccurate data\n'
        '• Request deletion of your account and data\n'
        '• Opt-out of marketing communications\n'
        '• Export your data';
  }

  String _getContactInfo() {
    return 'If you have questions about this Privacy Policy or your data, please contact us at:\n\n'
        'Email: support@strotech.uz\n'
        'Website: https://strotech.uz';
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, AppLocalizations? l10n) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
          children: [
            const TextSpan(text: "Don't have an account? "),
            TextSpan(
              text: l10n?.register ?? 'Register',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.register);
                },
            ),
          ],
        ),
      ),
    );
  }
}
