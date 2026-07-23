import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _shipMethod = 'air';
  double _shippingPerKg = 13;
  bool _payCargo = true;
  bool _placing = false;
  bool _initialized = false;

  // Address fields
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _stateCtl = TextEditingController();
  final _addrCtl = TextEditingController();
  final _countryCtl = TextEditingController(text: 'Somalia');

  // Saved addresses
  List<Map<String, dynamic>> _addresses = [];
  int? _selectedAddrId;
  bool _loadingAddrs = false;
  bool _useNewAddr = false;

  final Map<String, double> _shipRates = {'air': 13, 'express': 18, 'sea': 6};

  double get _serviceFee => context.read<CartService>().subtotal * 0.05;
  double get _cargoCost => context.read<CartService>().totalWeight * _shippingPerKg;
  double get _total => context.read<CartService>().subtotal + _serviceFee + (_payCargo ? _cargoCost : 0);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadAddresses();
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _cityCtl.dispose();
    _stateCtl.dispose();
    _addrCtl.dispose();
    _countryCtl.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddrs = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final addrs = await api.getAddresses();
    if (!mounted) return;
    setState(() {
      _addresses = addrs;
      _loadingAddrs = false;
      // Auto-select default address
      final def = addrs.cast<Map<String, dynamic>?>().firstWhere(
        (a) => a?['is_default'] == 1,
        orElse: () => addrs.isNotEmpty ? addrs.first : null,
      );
      if (def != null) _selectedAddrId = def['id'];
    });
  }

  bool _validateAddress() {
    if (_useNewAddr || _selectedAddrId == null) {
      final name = _nameCtl.text.trim();
      final phone = _phoneCtl.text.trim();
      final addr = _addrCtl.text.trim();
      if (name.isEmpty || phone.isEmpty || addr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in name, phone and address'), backgroundColor: Colors.red),
        );
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _buildAddressPayload() {
    if (!_useNewAddr && _selectedAddrId != null) {
      return {'address_id': _selectedAddrId};
    }
    return {
      'one_time_address': {
        'name': _nameCtl.text.trim(),
        'phone': _phoneCtl.text.trim(),
        'city': _cityCtl.text.trim(),
        'state': _stateCtl.text.trim(),
        'address': _addrCtl.text.trim(),
        'country': _countryCtl.text.trim().isEmpty ? 'Somalia' : _countryCtl.text.trim(),
      }
    };
  }

  Future<void> _placeOrder() async {
    if (!_validateAddress()) return;

    setState(() => _placing = true);
    try {
      final api = context.read<ApiService>();
      final cart = context.read<CartService>();
      final items = cart.items.map((i) => {
        'product_id': i.product.itemId,
        'title': i.product.title,
        'spec': i.spec,
        'image': i.product.imageUrl,
        'price_cny': (i.priceUsd > 0 ? i.priceUsd : i.product.displayPrice) * 6.7,
        'qty': i.qty,
        'weight': i.product.weight,
      }).toList();

      final body = {
        'items': items,
        'shipping_method': _shipMethod,
        'pay_cargo_now': _payCargo,
        'payment_method': 'mobilewallet',
        ..._buildAddressPayload(),
      };

      final resp = await api.apiPost('orders', body);

      if (resp['success'] == true && mounted) {
        cart.clear();
        final payUrl = resp['redirect_url'] ?? '';
        final orderTotal = resp['order']?['total'] ?? _total;
        if (payUrl.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed! Opening payment...'), backgroundColor: Colors.green),
          );
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          Navigator.of(context).pushNamed('/payment', arguments: {
            'url': payUrl,
            'amount': (orderTotal is num) ? orderTotal.toDouble() : _total,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushReplacementNamed('/orders');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp['error'] ?? 'Order failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Cart is empty', style: TextStyle(color: Color(0xFF999999))))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Progress steps
                Row(
                  children: [
                    _step('Cart', true),
                    _stepDot(),
                    _step('Checkout', true),
                    _stepDot(),
                    _step('Pay', false),
                  ],
                ),
                const SizedBox(height: 20),

                // Delivery Address
                _sectionCard('📍 Delivery Address', [
                  if (_loadingAddrs)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else ...[
                    if (_addresses.isNotEmpty) ...[
                      ...(_addresses as List).map((a) => _addressTile(a)),
                      const SizedBox(height: 8),
                    ],
                    // New address toggle
                    if (_addresses.isNotEmpty)
                      InkWell(
                        onTap: () => setState(() => _useNewAddr = !_useNewAddr),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(_useNewAddr ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 20, color: _useNewAddr ? const Color(0xFFFF5000) : const Color(0xFFCCCCCC)),
                              const SizedBox(width: 8),
                              Text(_useNewAddr ? 'Use new address' : 'Add new address',
                                  style: TextStyle(fontSize: 13, color: _useNewAddr ? const Color(0xFFFF5000) : const Color(0xFF666666))),
                            ],
                          ),
                        ),
                      ),
                    // Address form (always show if no saved addrs, or when toggled)
                    if (_addresses.isEmpty || _useNewAddr) ...[
                      const SizedBox(height: 8),
                      TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 8),
                      TextField(controller: _phoneCtl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), keyboardType: TextInputType.phone),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _cityCtl, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), textCapitalization: TextCapitalization.words)),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _stateCtl, decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), textCapitalization: TextCapitalization.words)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: _addrCtl, decoration: const InputDecoration(labelText: 'Full Address (street, building)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), maxLines: 2, textCapitalization: TextCapitalization.sentences),
                      const SizedBox(height: 8),
                      TextField(controller: _countryCtl, decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), textCapitalization: TextCapitalization.words),
                    ],
                  ],
                ]),
                const SizedBox(height: 12),

                // Order items
                _sectionCard('🛒 Order Items', cart.items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item.product.imageUrl, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 48)),
                  ),
                  title: Text(item.product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(item.spec, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  trailing: Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                )).toList()),
                const SizedBox(height: 12),

                // Shipping
                _sectionCard('✈ Shipping', [
                  _shipOption('air', 'Air Freight', '7-15 days', 13),
                  _shipOption('express', 'Express', '3-7 days', 18),
                  _shipOption('sea', 'Sea Freight', '25-40 days', 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pay cargo fees now', style: TextStyle(fontSize: 13)),
                    subtitle: Text('Estimated \$${_cargoCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                    value: _payCargo,
                    activeColor: const Color(0xFFFF5000),
                    onChanged: (v) => setState(() => _payCargo = v),
                  ),
                ]),
                const SizedBox(height: 12),

                // Payment method
                _sectionCard('💳 Payment', [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50))),
                    title: const Text('WaafiPay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('EVC Plus · Zaad · Sahal', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.check_circle, color: Color(0xFFFF5000)),
                  ),
                ]),
                const SizedBox(height: 12),

                // Summary
                _sectionCard('📊 Summary', [
                  _summaryRow('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
                  _summaryRow('Service Fee (5%)', '\$${_serviceFee.toStringAsFixed(2)}'),
                  if (_payCargo) _summaryRow('Cargo (${cart.totalWeight.toStringAsFixed(1)}kg)', '\$${_cargoCost.toStringAsFixed(2)}'),
                  const Divider(),
                  _summaryRow('Total', '\$${_total.toStringAsFixed(2)}', isTotal: true),
                ]),
                const SizedBox(height: 80),
              ],
            ),

      bottomNavigationBar: cart.items.isEmpty ? null : Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))]),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _placing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: _placing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('🔒 Pay Now \$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressTile(Map<String, dynamic> a) {
    final selected = _selectedAddrId == a['id'] && !_useNewAddr;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: selected ? const Color(0xFFFFF5F0) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? const Color(0xFFFF5000) : const Color(0xFFE8E8E8), width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() {
          _selectedAddrId = a['id'];
          _useNewAddr = false;
        }),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? const Color(0xFFFF5000) : const Color(0xFFCCCCCC), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${a['phone'] ?? ''} · ${a['address'] ?? ''}, ${a['city'] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF999999)), maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _shipOption(String value, String name, String eta, double rate) {
    final selected = _shipMethod == value;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: selected ? const Color(0xFFFFF5F0) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? const Color(0xFFFF5000) : const Color(0xFFE8E8E8), width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() { _shipMethod = value; _shippingPerKg = rate; }),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? const Color(0xFFFF5000) : const Color(0xFFCCCCCC), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Text(eta, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
              const SizedBox(width: 8),
              Text('\$$rate/kg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400)),
          Text(value, style: TextStyle(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500, color: isTotal ? const Color(0xFFFF5000) : null)),
        ],
      ),
    );
  }

  Widget _step(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFF5000) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF999999))),
    );
  }

  Widget _stepDot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Text('›', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14)),
  );
}
