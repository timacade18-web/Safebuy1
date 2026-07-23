import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
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
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final profile = await api.getProfile();
    setState(() { _user = profile; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFF5000))),
      );
    }

    if (_user == null) {
      return _loginScreen();
    }

    final api = context.read<ApiService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(child: CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFFF5000),
            child: Text((_user!['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 36, color: Colors.white)),
          )),
          const SizedBox(height: 12),
          Center(child: Text(_user!['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          Center(child: Text(_user!['email'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF999999)))),
          if (_user!['phone'] != null) ...[
            const SizedBox(height: 4),
            Center(child: Text(_user!['phone'], style: const TextStyle(fontSize: 13, color: Color(0xFF999999)))),
          ],
          const SizedBox(height: 24),
          // Menu items
          _menuItem(Icons.receipt_long, 'My Orders', () => Navigator.pushNamed(context, '/orders')),
          _menuItem(Icons.local_shipping, 'Track Order', () => Navigator.pushNamed(context, '/track')),
          _menuItem(Icons.account_balance_wallet, 'Wallet', () {}),
          _menuItem(Icons.card_giftcard, 'Referrals', () {}),
          _menuItem(Icons.settings, 'Settings', () {}),
          const SizedBox(height: 16),
          // Logout
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async {
              await api.logout();
              setState(() => _user = null);
            },
            icon: const Icon(Icons.logout, color: Color(0xFFF44336)),
            label: const Text('Logout', style: TextStyle(color: Color(0xFFF44336))),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFF44336)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          )),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF5000)),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _loginScreen() {
    final api = context.read<ApiService>();
    final emailCtl = TextEditingController();
    final passCtl = TextEditingController();
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    bool isLogin = true;
    bool loading = false;

    return StatefulBuilder(builder: (context, setSt) {
      return Scaffold(
        appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (!isLogin) ...[
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),),
              const SizedBox(height: 12),
              TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
            ],
            TextField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: passCtl, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 24),
            if (loading) const CircularProgressIndicator(color: Color(0xFFFF5000)) else
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                setSt(() => loading = true);
                try {
                  Map<String, dynamic> resp;
                  if (isLogin) {
                    resp = await api.login(emailCtl.text.trim(), passCtl.text);
                  } else {
                    resp = await api.register(nameCtl.text.trim(), emailCtl.text.trim(), phoneCtl.text.trim(), passCtl.text);
                  }
                  if (resp['success'] == true) {
                    _checkAuth();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['error']?.toString() ?? 'Failed')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
                setSt(() => loading = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5000), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(isLogin ? 'Login' : 'Sign Up'),
            )),
            const SizedBox(height: 16),
            TextButton(onPressed: () => setSt(() => isLogin = !isLogin), child: Text(isLogin ? 'Don\'t have an account? Sign up' : 'Already have an account? Login')),
          ]),
        ),
      );
    });
  }
}
