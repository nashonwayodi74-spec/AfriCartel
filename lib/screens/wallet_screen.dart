import 'package:flutter/material.dart';
import '../services/afripay_service.dart';

/// Afripay Wallet Screen - Digital wallet for cross-Africa payments
class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final AfripayService _afripayService = AfripayService();
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  String _selectedCurrency = 'KES';

  final List<String> _currencies = ['KES', 'NGN', 'GHS', 'TZS', 'UGX', 'ZAR'];
  final Map<String, String> _currencySymbols = {
    'KES': 'KSh',
    'NGN': '₦',
    'GHS': 'GH₵',
    'TZS': 'TSh',
    'UGX': 'USh',
    'ZAR': 'R',
  };

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    final wallet = await _afripayService.getWallet();
    setState(() {
      _walletData = wallet;
      _isLoading = false;
    });
  }

  double _getBalance() {
    if (_walletData == null) return 0.0;
    final balances = _walletData!['balances'] as Map<String, dynamic>;
    return (balances[_selectedCurrency] ?? 0.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Afripay Wallet'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWallet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWalletCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildCurrencyBalances(),
                      const SizedBox(height: 24),
                      _buildKYCStatus(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              DropdownButton<String>(
                value: _selectedCurrency,
                dropdownColor: Colors.green[800],
                underline: Container(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: _currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCurrency = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_currencySymbols[_selectedCurrency]} ${_getBalance().toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedCurrency,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              icon: Icons.add_circle,
              label: 'Add Funds',
              color: Colors.green,
              onTap: () => _showAddFundsDialog(),
            ),
            _buildActionButton(
              icon: Icons.send,
              label: 'Send Money',
              color: Colors.blue,
              onTap: () => _showSendMoneyDialog(),
            ),
            _buildActionButton(
              icon: Icons.history,
              label: 'History',
              color: Colors.orange,
              onTap: () => _navigateToHistory(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBalances() {
    if (_walletData == null) return const SizedBox();
    final balances = _walletData!['balances'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Currencies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...balances.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Text(
                  _currencySymbols[entry.key] ?? entry.key,
                  style: TextStyle(color: Colors.green[700]),
                ),
              ),
              title: Text(entry.key),
              trailing: Text(
                '${_currencySymbols[entry.key]} ${(entry.value as num).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildKYCStatus() {
    if (_walletData == null) return const SizedBox();
    final kycStatus = _walletData!['kycStatus'] as String;
    final dailyLimit = _walletData!['dailyLimit'] as double;

    Color statusColor;
    String statusText;
    switch (kycStatus) {
      case 'enhanced':
        statusColor = Colors.green;
        statusText = 'Enhanced KYC';
        break;
      case 'standard':
        statusColor = Colors.orange;
        statusText = 'Standard KYC';
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Basic KYC';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Daily Limit: \$${dailyLimit.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (kycStatus == 'basic') ..[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showUpgradeKYCDialog(),
                child: const Text('Upgrade to increase limits'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddFundsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds'),
        content: const Text('Add funds feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSendMoneyDialog() {
    Navigator.pushNamed(context, '/send-money');
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/transaction-history');
  }

  void _showUpgradeKYCDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade KYC'),
        content: const Text('KYC upgrade feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
