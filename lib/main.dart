import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/cart_service.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/search_results_screen.dart';

const Color kOrange = Color(0xFFFF6A00);
const Color kNavy = Color(0xFF06265C);

void main() {
  runApp(const SafeBuyApp());
}

class SafeBuyApp extends StatelessWidget {
  const SafeBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'SAFEBUY',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kOrange,
            primary: kOrange,
            secondary: kNavy,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1A1A1A),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: kOrange,
            unselectedItemColor: Color(0xFF999999),
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 10),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: kOrange,
              side: const BorderSide(color: kOrange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kOrange, width: 1.5),
            ),
            labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
          ),
        ),
        home: const MainShell(),
        routes: {
          '/payment': (ctx) {
            final args = ModalRoute.of(ctx)?.settings.arguments;
            if (args is String) return PaymentScreen(paymentUrl: args);
            if (args is Map) return PaymentScreen(paymentUrl: args['url']?.toString() ?? '', amount: (args['amount'] ?? 0).toDouble());
            return const PaymentScreen(paymentUrl: '');
          },
          '/search': (ctx) {
            final args = ModalRoute.of(ctx)?.settings.arguments;
            return SearchResultsScreen(
              query: args is Map ? (args['q']?.toString() ?? '') : '',
              platform: args is Map ? (args['plat']?.toString() ?? 'taobao') : 'taobao',
            );
          },
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int currentIndex = 0;

  void goToTab(int index) {
    if (index == 1) {
      // Categories tab - show modal instead
      showCategoriesModal(context);
      return;
    }
    // Convert bottom-nav index to IndexedStack index:
    // nav: Home(0), Categories(1=modal), Cart(2->stack 1), Account(3->stack 2)
    int stackIndex;
    if (index == 0) {
      stackIndex = 0; // Home
    } else if (index == 2) {
      stackIndex = 1; // Cart
    } else if (index == 3) {
      stackIndex = 2; // Account
    } else {
      stackIndex = index;
    }
    setState(() => currentIndex = stackIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeScreen(onNavigateTab: goToTab),
          const CartScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex == 0 ? 0 : currentIndex == 1 ? 2 : 3,
        onTap: goToTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: kOrange,
        unselectedItemColor: const Color(0xFF999999),
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.apps_outlined), activeIcon: Icon(Icons.apps), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

void showCategoriesModal(BuildContext context) {
  final cats = [
    {'name': 'Electronics', 'emoji': '📱', 'color': 0xFFFFF0F0, 'query': 'electronics'},
    {'name': 'Fashion', 'emoji': '👗', 'color': 0xFFFFF0F5, 'query': 'fashion'},
    {'name': 'Shoes', 'emoji': '👟', 'color': 0xFFF0FFF4, 'query': 'shoes'},
    {'name': 'Beauty', 'emoji': '💄', 'color': 0xFFFFF5F0, 'query': 'beauty'},
    {'name': 'Bags', 'emoji': '👜', 'color': 0xFFF5F0FF, 'query': 'bag'},
    {'name': 'Home', 'emoji': '🏠', 'color': 0xFFFFF8E1, 'query': 'home'},
    {'name': 'Sports', 'emoji': '⚽', 'color': 0xFFF0FFF8, 'query': 'sports'},
    {'name': 'Watches', 'emoji': '⌚', 'color': 0xFFF5F5F5, 'query': 'watches'},
    {'name': 'Jewelry', 'emoji': '💍', 'color': 0xFFFFF0F5, 'query': 'jewelry'},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(margin: const EdgeInsets.only(top: 8), width: 36, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                GestureDetector(onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF999999))),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: cats.map((c) => GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/search', arguments: {
                    'q': c['query'] as String,
                    'plat': '1688',
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Color(c['color'] as int),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(c['emoji'] as String, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(height: 6),
                    Text(c['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
