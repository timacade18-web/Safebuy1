import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String _oneBoundBase = 'https://api-gw.onebound.cn';
  static const String _backendBase = 'https://safebuy1.com/api/index.php';
  static const String _proxy = 'https://safebuy1.com/api/onebound_proxy.php';
  static const double _exchangeRate = 6.7;

  // OneBound credentials (loaded from backend)
  static String _oneBoundKey = '';
  static String _oneBoundSecret = '';
  static bool _credentialsLoaded = false;

  // Session & CSRF
  static String _cookies = '';
  static String _csrfToken = '';

  /// Load OneBound credentials from backend
  Future<void> _ensureCredentials() async {
    if (_credentialsLoaded) return;
    try {
      final url = Uri.parse('$_backendBase?route=config/onebound');
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      final data = json.decode(resp.body);
      if (data['key'] != null && (data['key'] as String).isNotEmpty) {
        _oneBoundKey = data['key'] as String;
        _oneBoundSecret = data['secret'] as String;
      }
    } catch (e) {
      debugPrint('Credential load failed: $e');
    }
    _credentialsLoaded = true;
  }

  /// Store PHPSESSID from response cookies
  void _saveCookies(http.Response r) {
    final setCookie = r.headers['set-cookie'];
    if (setCookie != null) {
      final match = RegExp(r'(PHPSESSID=[^;]+)').firstMatch(setCookie);
      if (match != null) {
        _cookies = match.group(1)!;
      }
    }
  }

  /// Build headers with cookies and CSRF token
  Map<String, String> _headers({Map<String, String>? extra}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_cookies.isNotEmpty) h['Cookie'] = _cookies;
    if (_csrfToken.isNotEmpty) h['X-CSRF-Token'] = _csrfToken;
    if (extra != null) h.addAll(extra);
    return h;
  }

  /// Fetch a fresh CSRF token from the server
  Future<bool> fetchCsrfToken() async {
    try {
      final r = await http.post(
        Uri.parse('$_backendBase?route=auth/csrf_token'),
        headers: {'Content-Type': 'application/json'},
        body: '{}',
      ).timeout(const Duration(seconds: 10));
      _saveCookies(r);
      final d = json.decode(r.body);
      if (d['success'] == true && d['csrf_token'] != null) {
        _csrfToken = d['csrf_token'];
        return true;
      }
    } catch (e) {
      debugPrint('fetchCsrfToken error: $e');
    }
    return false;
  }

  /// Search products — calls backend proxy (handles translation + sorting)
  Future<List<Product>> searchProducts(String query, {int page = 1, int? pageSize, String plat = 'taobao'}) async {
      final ps = pageSize ?? (plat == '1688' ? 20 : 40);
      final url = '$_proxy?action=search&platform=$plat&q=${Uri.encodeComponent(query)}&page=$page&page_size=$ps&sort=price_asc';
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      final data = json.decode(resp.body);
      final items = data['items']?['item'] ?? data['items'] ?? [];
      final list = (items is List ? items : [items]).cast<Map<String, dynamic>>();
      return list.map((j) => Product.fromOneBound(j)).toList();
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  /// Get product detail — tries proxy first, falls back to direct OneBound call
  Future<Product?> getProductDetail(String itemId, {String platform = 'taobao'}) async {
    // Try proxy first (has cache, respects our IP)
    try {
      final proxyUrl = '$_proxy?action=detail&num_iid=$itemId&platform=$platform&lang=en';
      final resp = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 25));
      final data = json.decode(resp.body);
      final item = data['item'];
      // Check if detail returned valid data
      if (item != null && item['title'] != null && item['title'].toString().isNotEmpty && item['format_check'] != 'fail') {
        return Product.fromOneBoundDetail(item);
      }
      // If proxy detail failed, try search fallback (same as WAP)
      if (item == null || item['format_check'] == 'fail') {
        final searchUrl = '$_proxy?action=search&q=$itemId&platform=$platform&page=1&page_size=3';
        final searchResp = await http.get(Uri.parse(searchUrl)).timeout(const Duration(seconds: 20));
        final searchData = json.decode(searchResp.body);
        final items = searchData['items']?['item'] ?? searchData['items'] ?? [];
        final list = (items is List ? items : [items]).cast<Map<String, dynamic>>();
        if (list.isNotEmpty) {
          return Product.fromOneBound(list.first);
        }
      }
    } catch (e) {
      debugPrint('Proxy detail attempt failed: $e');
    }

    // Fallback: call OneBound directly from device
    await _ensureCredentials();
    if (_oneBoundKey.isEmpty) return null;
    try {
      final url = Uri.parse(
        '$_oneBoundBase/taobao/item_get?key=$_oneBoundKey&secret=$_oneBoundSecret&num_iid=$itemId&lang=en',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 25));
      final data = json.decode(resp.body);
      if (data['error_code'] == '0000' && data['item'] != null) {
        return Product.fromOneBoundDetail(data['item']);
      }
    } catch (e) {
      debugPrint('Direct OneBound detail failed: $e');
    }
    return null;
  }

  /// Get trending products
  Future<List<Product>> getTrending() async {
    final url = '$_proxy?action=trending&platform=taobao';
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      final data = json.decode(resp.body);
      final items = data['items']?['item'] ?? data['items'] ?? [];
      final list = (items is List ? items : [items]).cast<Map<String, dynamic>>();
      return list.map((j) => Product.fromOneBound(j)).toList();
    } catch (e) {
      debugPrint('Trending error: $e');
      return [];
    }
  }

  /// Backend API calls with CSRF token support
  Future<Map<String, dynamic>> apiPost(String route, Map<String, dynamic> body) async {
    final url = Uri.parse('$_backendBase?route=${Uri.encodeComponent(route)}');
    try {
      final resp = await http.post(
        url,
        headers: _headers(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
      _saveCookies(resp);
      final d = json.decode(resp.body);
      // Retry once if CSRF fails
      if (d['error']?.toString().contains('CSRF') == true) {
        debugPrint('CSRF token invalid, retrying...');
        await fetchCsrfToken();
        final retry = await http.post(
          url,
          headers: _headers(),
          body: json.encode(body),
        ).timeout(const Duration(seconds: 15));
        _saveCookies(retry);
        return json.decode(retry.body);
      }
      return d;
    } catch (e) {
      debugPrint('apiPost error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> apiGet(String route) async {
    final url = Uri.parse('$_backendBase?route=${Uri.encodeComponent(route)}');
    try {
      final resp = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 10));
      _saveCookies(resp);
      return json.decode(resp.body);
    } catch (e) {
      debugPrint('apiGet error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── Auth methods ───

  Future<Map<String, dynamic>> login(String email, String password) async {
    await fetchCsrfToken();
    final result = await apiPost('auth/login', {'email': email, 'password': password});
    if (result['success'] == true) await fetchCsrfToken();
    return result;
  }

  Future<Map<String, dynamic>> register(String name, String email, String phone, String password) async {
    await fetchCsrfToken();
    final result = await apiPost('auth/register', {
      'name': name, 'email': email, 'phone': phone, 'password': password,
    });
    if (result['success'] == true) await fetchCsrfToken();
    return result;
  }

  Future<Map<String, dynamic>> logout() async {
    final result = await apiPost('auth/logout', {});
    _cookies = '';
    _csrfToken = '';
    return result;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final result = await apiPost('auth/ping', {});
    if (result['csrf_token'] != null) _csrfToken = result['csrf_token'];
    if (result['authenticated'] == true) return result['user'];
    return null;
  }

  // ─── Addresses ───
  /// List user addresses (GET — POST creates/updates)
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final result = await apiGet('user/addresses');
    if (result['success'] == true && result['addresses'] != null) {
      return List<Map<String, dynamic>>.from(result['addresses']);
    }
    return [];
  }

  Future<Map<String, dynamic>> saveAddress({
    required String name,
    required String phone,
    String city = '',
    String state = '',
    String address = '',
    String country = 'Somalia',
    int isDefault = 0,
  }) async {
    return await apiPost('user/addresses', {
      'name': name, 'phone': phone, 'city': city, 'state': state,
      'address': address, 'country': country, 'is_default': isDefault,
    });
  }

  /// Search products by image (upload base64 image or use imgid)
  Future<List<Product>> searchByImage(String imgBase64, {String platform = 'taobao', int page = 1}) async {
    try {
      final url = Uri.parse('$_backendBase?route=image_search&platform=$platform&page=$page');
      final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'img': imgBase64}),
      ).timeout(const Duration(seconds: 45));

      final data = json.decode(resp.body);
      if (data['success'] == true) {
        final items = data['items'] as List? ?? [];
        return items.map((item) => Product(
          itemId: item['num_iid']?.toString() ?? '',
          title: item['title']?.toString() ?? '',
          imageUrl: item['pic_url']?.toString() ?? '',
          priceCny: (item['price_cny'] ?? item['price'] ?? 0).toDouble(),
          priceUsd: (item['price_usd'] ?? 0).toDouble(),
          sales: (item['sales'] ?? 0).toInt(),
          platform: item['platform']?.toString() ?? platform,
        )).toList();
      } else {
        throw Exception(data['error'] ?? 'Search failed');
      }
    } catch (e) {
      debugPrint('Image search failed: $e');
      rethrow;
    }
  }

  // ── App config (logo, splash, popup) — fetched once at startup ──
  static final ValueNotifier<String?> appLogoUrl = ValueNotifier(null);
  static bool _appConfigLoaded = false;

  Future<void> fetchAppConfig() async {
    if (_appConfigLoaded) return;
    try {
      final url = Uri.parse('$_backendBase?route=app/config');
      final resp = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 10));
      final data = json.decode(resp.body);
      if (data['success'] == true) {
        final logoUrl = data['app_logo']?.toString();
        appLogoUrl.value = logoUrl;
        _appConfigLoaded = true;
      }
    } catch (e) {
      debugPrint('App config fetch failed: $e');
    }
  }
}
