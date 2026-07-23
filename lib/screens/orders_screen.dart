import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      // Check if logged in
      final ping = await api.apiPost('auth/ping', {});
      if (ping['authenticated'] != true) {
        setState(() { _loading = false; });
        return;
      }
      final resp = await api.apiGet('orders');
      if (resp['success'] == true) {
        setState(() {
          _orders = (resp['orders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      } else {
        setState(() { _error = resp['error']?.toString() ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5000)))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFCCCCCC)),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Color(0xFF999999), fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
                  ],
                )))
              : _orders.isEmpty
                  ? _loginPrompt()
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: const Color(0xFFFF5000),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final o = _orders[i];
                          final status = o['status']?.toString() ?? 'pending';
                          final statusLabels = {
                            'pending': 'Pending', 'processing': 'Processing',
                            'shipped': 'Shipped', 'delivered': 'Delivered',
                            'cancelled': 'Cancelled', 'payment_pending': 'Pay Pending',
                            'payment_failed': 'Failed', 'purchased': 'Purchased',
                            'in_transit': 'In Transit',
                          };
                          final statusColors = {
                            'pending': const Color(0xFFFF9800), 'processing': const Color(0xFF2196F3),
                            'shipped': const Color(0xFF9C27B0), 'delivered': const Color(0xFF4CAF50),
                            'cancelled': const Color(0xFFF44336), 'payment_pending': const Color(0xFFFF9800),
                            'payment_failed': const Color(0xFFF44336), 'purchased': const Color(0xFF9C27B0),
                            'in_transit': const Color(0xFF795548),
                          };
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text('#${o['order_no']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: (statusColors[status] ?? const Color(0xFF999999)).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Text(statusLabels[status] ?? status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColors[status] ?? const Color(0xFF999999))),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text(o['items_summary']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text(o['created_at']?.toString().substring(0, 16) ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
                                const Spacer(),
                                Text('\$${double.tryParse(o['total_usd']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFFFF0036))),
                              ]),
                              // Track button
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Open tracking page in webview/url
                                    final orderNo = o['order_no']?.toString() ?? '';
                                    // Use url_launcher to open tracking page
                                  },
                                  icon: const Icon(Icons.local_shipping, size: 16),
                                  label: const Text('Track Order', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1B2A4A),
                                    side: const BorderSide(color: Color(0xFF1B2A4A)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _loginPrompt() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.person_outline, size: 64, color: Color(0xFFDDDDDD)),
        const SizedBox(height: 16),
        const Text('Login to see your orders', style: TextStyle(fontSize: 15, color: Color(0xFF999999))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5000), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          child: const Text('Login', style: TextStyle(fontSize: 15)),
        )),
      ]),
    ));
  }
}
