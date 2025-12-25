import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/app_drawer.dart';

class PremiumUpgradeScreen extends StatelessWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Upgrade', style: AppTheme.headingSmall),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(currentIndex: 9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upgrade to Premium',
                    style: AppTheme.headingMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock all features and take your business to the next level',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Pricing Cards
            Text(
              'Choose Your Plan',
              style: AppTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Monthly Plan
            _buildPlanCard(
              context,
              title: 'Monthly',
              price: 'PKR 499',
              period: '/month',
              features: [
                'Unlimited Products',
                'Unlimited Sales',
                'Advanced Reports',
                'Cloud Backup',
                'Priority Support',
              ],
              isPopular: false,
              onTap: () => _showPurchaseDialog(context, 'Monthly', 499),
            ),

            const SizedBox(height: 16),

            // Yearly Plan (Popular)
            _buildPlanCard(
              context,
              title: 'Yearly',
              price: 'PKR 3,999',
              period: '/year',
              savings: 'Save PKR 1,989',
              features: [
                'Everything in Monthly',
                '2 Months FREE',
                'Multi-User Access',
                'Custom Branding',
                'API Access',
                'Dedicated Support',
              ],
              isPopular: true,
              onTap: () => _showPurchaseDialog(context, 'Yearly', 3999),
            ),

            const SizedBox(height: 16),

            // Lifetime Plan
            _buildPlanCard(
              context,
              title: 'Lifetime',
              price: 'PKR 9,999',
              period: 'one-time',
              savings: 'Best Value',
              features: [
                'Everything in Yearly',
                'One-Time Payment',
                'Lifetime Updates',
                'All Future Features',
                'White-Label Option',
                'VIP Support Forever',
              ],
              isPopular: false,
              isLifetime: true,
              onTap: () => _showPurchaseDialog(context, 'Lifetime', 9999),
            ),

            const SizedBox(height: 32),

            // Free Features Comparison
            Text(
              'Free vs Premium',
              style: AppTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            _buildComparisonTable(),

            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: AppTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              'Can I cancel anytime?',
              'Yes! You can cancel your subscription at any time. Your premium features will remain active until the end of your billing period.',
            ),
            _buildFAQItem(
              'Is my data secure?',
              'Absolutely! We use industry-standard encryption and your data is backed up securely in the cloud.',
            ),
            _buildFAQItem(
              'What payment methods do you accept?',
              'We accept all major payment methods including credit/debit cards, JazzCash, Easypaisa, and bank transfers.',
            ),
            _buildFAQItem(
              'Can I switch plans?',
              'Yes, you can upgrade or downgrade your plan at any time. We\'ll prorate any differences.',
            ),

            const SizedBox(height: 32),

            // Contact Support
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 48,
                    color: AppTheme.infoColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Need Help?',
                    style: AppTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact our support team for any questions',
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Open support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support: support@smartpos.com'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.email),
                    label: const Text('Contact Support'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    String? savings,
    required List<String> features,
    required bool isPopular,
    bool isLifetime = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? AppTheme.accentColor : AppTheme.dividerColor,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                '🔥 MOST POPULAR',
                style: AppTheme.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  title,
                  style: AppTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: AppTheme.priceLarge.copyWith(
                        color: isPopular ? AppTheme.accentColor : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        period,
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                if (savings != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      savings,
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: isPopular ? AppTheme.accentColor : AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular 
                          ? AppTheme.accentColor 
                          : isLifetime 
                              ? AppTheme.primaryColor 
                              : AppTheme.primaryLight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Get ${title} Plan',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final features = [
      {'name': 'Products', 'free': '50', 'premium': 'Unlimited'},
      {'name': 'Sales/Month', 'free': '100', 'premium': 'Unlimited'},
      {'name': 'Basic Reports', 'free': true, 'premium': true},
      {'name': 'Advanced Reports', 'free': false, 'premium': true},
      {'name': 'Cloud Backup', 'free': false, 'premium': true},
      {'name': 'Multi-User', 'free': false, 'premium': true},
      {'name': 'PDF Export', 'free': false, 'premium': true},
      {'name': 'Priority Support', 'free': false, 'premium': true},
    ];

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Feature',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Free',
                    style: AppTheme.labelMedium.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium',
                    style: AppTheme.labelMedium.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...features.map((feature) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    feature['name'] as String,
                    style: AppTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: _buildComparisonValue(feature['free']),
                ),
                Expanded(
                  child: _buildComparisonValue(feature['premium']),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildComparisonValue(dynamic value) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle : Icons.cancel,
        color: value ? AppTheme.successColor : AppTheme.textLight,
        size: 20,
      );
    }
    return Text(
      value.toString(),
      style: AppTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTheme.titleMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, String plan, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Upgrade to $plan', style: AppTheme.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to purchase the $plan plan for PKR $price.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a demo. Payment integration coming soon!',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment integration coming soon!'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

