import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final double amount;
  const PaymentScreen({super.key, required this.paymentUrl, this.amount = 0});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-open the payment URL after a short delay
    Future.delayed(const Duration(milliseconds: 500), _openPaymentUrl);
  }

  Future<void> _openPaymentUrl() async {
    var url = widget.paymentUrl;
    // Ensure full URL
    if (!url.startsWith('http')) {
      url = 'https://safebuy1.com$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    // Return to orders page after a brief delay
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse order info from URL
    String orderNo = '', amount = '0';
    try {
      final uri = Uri.parse(widget.paymentUrl.startsWith('http') ? widget.paymentUrl : 'https://safebuy1.com${widget.paymentUrl}');
      orderNo = uri.queryParameters['order_id'] ?? '';
      amount = uri.queryParameters['amount'] ?? widget.amount.toStringAsFixed(2);
    } catch (_) {
      amount = widget.amount.toStringAsFixed(2);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFFF5000)),
              ),
              const SizedBox(height: 24),
              Text(
                '\$${double.tryParse(amount)?.toStringAsFixed(2) ?? amount}',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFFFF5000)),
              ),
              if (orderNo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Order #$orderNo', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
              ],
              const SizedBox(height: 24),
              const Text(
                'Opening WaafiPay...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete payment in your browser.\nYou will be redirected back after.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _openPaymentUrl,
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: const Text('Open Payment Page', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => false),
                child: const Text('View My Orders', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
