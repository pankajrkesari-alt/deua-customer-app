import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://cvbubouqkoladwhemzcf.supabase.co',
    anonKey: 'sb_publishable_gSYtFINdgJzEQwYLJ9M8pg_zxMs6SK5',
  );
  runApp(const DeuaCustomerApp());
}

class DeuaCustomerApp extends StatelessWidget {
  const DeuaCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEUA FRESH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7A2B),
          primary: const Color(0xFF1B7A2B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const StoreHomeScreen(),
    );
  }
}

class MainCategory {
  final String id;
  final String name;
  final String hindiName;
  final String emoji;

  const MainCategory({
    required this.id,
    required this.name,
    required this.hindiName,
    required this.emoji,
  });
}

class SubCategory {
  final String id;
  final String mainCategoryId;
  final String name;
  final String emoji;
  final Color bgColor;

  const SubCategory({
    required this.id,
    required this.mainCategoryId,
    required this.name,
    required this.emoji,
    required this.bgColor,
  });
}

class PackOption {
  final String label;
  final double price;
  final double mrp;

  const PackOption({
    required this.label,
    required this.price,
    required this.mrp,
  });
}

class ProductItem {
  final String id;
  final String mainCategoryId;
  final String subCategoryId;
  final String name;
  final int discountPercent;
  final String imageUrl;
  final String fallbackEmoji;
  final Color cardBg;
  final List<PackOption> packs;

  const ProductItem({
    required this.id,
    required this.mainCategoryId,
    required this.subCategoryId,
    required this.name,
    required this.discountPercent,
    required this.imageUrl,
    required this.fallbackEmoji,
    required this.cardBg,
    required this.packs,
  });
}

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  List<MainCategory> _mainCategories = [];
  List<SubCategory> _allSubCategories = [];
  List<ProductItem> _allProducts = [];

  String _selectedMainCatId = 'fruits';
  String _selectedSubCatId = 'all';
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _wishlist = {};
  final Map<String, int> _selectedPackIndex = {};
  final Map<String, int> _cartQuantities = {};

  String _savedName = '';
  String _savedPhone = '';
  String _savedAddress = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCustomer();
    _fetchCatalog();
  }

  Future<void> _loadSavedCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedName = prefs.getString('cust_name') ?? '';
      _savedPhone = prefs.getString('cust_phone') ?? '';
      _savedAddress = prefs.getString('cust_address') ?? '';
    });
  }

  Future<void> _saveCustomer(String name, String phone, String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cust_name', name);
    await prefs.setString('cust_phone', phone);
    await prefs.setString('cust_address', address);
    setState(() {
      _savedName = name;
      _savedPhone = phone;
      _savedAddress = address;
    });
  }

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  Future<void> _fetchCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mainRes = await _supabase
          .from('deua_main_categories')
          .select()
          .order('sort_order', ascending: true);

      final subRes = await _supabase
          .from('deua_sub_categories')
          .select()
          .order('sort_order', ascending: true);

      final prodRes = await _supabase
          .from('deua_products')
          .select()
          .eq('in_stock', true)
          .order('created_at', ascending: true);

      final loadedMain = List>.from(mainRes).map((row) {
        return MainCategory(
          id: row['id'].toString(),
          name: (row['name'] ?? '').toString(),
          hindiName: (row['hindi_name'] ?? '').toString(),
          emoji: (row['emoji'] ?? '🧺').toString(),
        );
      }).toList();

      final loadedSub = List>.from(subRes).map((row) {
        return SubCategory(
          id: row['id'].toString(),
          mainCategoryId: (row['main_category_id'] ?? '').toString(),
          name: (row['name'] ?? '').toString(),
          emoji: (row['emoji'] ?? '🌿').toString(),
          bgColor: _parseHexColor(row['bg_color']?.toString(), const Color(0xFFE8F5E9)),
        );
      }).toList();

      final loadedProducts = List>.from(prodRes).map((row) {
        final rawPacks = row['packs'] as List<dynamic>? ?? [];
        final packs = rawPacks.map((p) {
          final m = Map<String, dynamic>.from(p as Map);
          return PackOption(
            label: (m['label'] ?? '1 pack').toString(),
            price: (m['price'] as num? ?? 0).toDouble(),
            mrp: (m['mrp'] as num? ?? 0).toDouble(),
          );
        }).toList();

        if (packs.isEmpty) {
          packs.add(const PackOption(label: '1 unit', price: 0, mrp: 0));
        }

        return ProductItem(
          id: row['id'].toString(),
          mainCategoryId: (row['main_category_id'] ?? '').toString(),
          subCategoryId: (row['sub_category_id'] ?? '').toString(),
          name: (row['name'] ?? '').toString(),
          discountPercent: (row['discount_percent'] as num? ?? 0).toInt(),
          imageUrl: (row['image_url'] ?? '').toString(),
          fallbackEmoji: (row['fallback_emoji'] ?? '🧺').toString(),
          cardBg: _parseHexColor(row['card_bg']?.toString(), const Color(0xFFF1F8E9)),
          packs: packs,
        );
      }).toList();

      setState(() {
        _mainCategories = loadedMain;
        _allSubCategories = loadedSub;
        _allProducts = loadedProducts;
        if (_mainCategories.isNotEmpty &&
            !_mainCategories.any((m) => m.id == _selectedMainCatId)) {
          _selectedMainCatId = _mainCategories.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Internet connection check karein aur Retry dabayein.';
        _isLoading = false;
      });
    }
  }

  List<SubCategory> get _currentSubCategories {
    final list = _allSubCategories
        .where((s) => s.mainCategoryId == _selectedMainCatId)
        .toList();
    return [
      SubCategory(
        id: 'all',
        mainCategoryId: _selectedMainCatId,
        name: 'All Items',
        emoji: '🧺',
        bgColor: const Color(0xFFFFF3E0),
      ),
      ...list,
    ];
  }

  int _countForSubCategory(String subId) {
    if (subId == 'all') {
      return _allProducts.where((p) => p.mainCategoryId == _selectedMainCatId).length;
    }
    return _allProducts
        .where((p) => p.mainCategoryId == _selectedMainCatId && p.subCategoryId == subId)
        .length;
  }

  List<ProductItem> get _filteredProducts {
    return _allProducts.where((item) {
      if (_searchQuery.isNotEmpty) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      final matchesMain = item.mainCategoryId == _selectedMainCatId;
      final matchesSub =
          _selectedSubCatId == 'all' || item.subCategoryId == _selectedSubCatId;
      return matchesMain && matchesSub;
    }).toList();
  }

  int get _totalCartItems {
    int total = 0;
    for (final qty in _cartQuantities.values) {
      total += qty;
    }
    return total;
  }

  double get _totalCartPrice {
    double sum = 0;
    for (final entry in _cartQuantities.entries) {
      final parts = entry.key.split('::');
      final product = _allProducts.where((p) => p.id == parts[0]).firstOrNull;
      if (product != null) {
        final packIdx = int.parse(parts[1]);
        if (packIdx < product.packs.length) {
          sum += product.packs[packIdx].price * entry.value;
        }
      }
    }
    return sum;
  }

  void _showPackSelector(ProductItem product) {
    if (product.packs.length <= 1) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final currentIdx = _selectedPackIndex[product.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...List.generate(product.packs.length, (idx) {
                final pack = product.packs[idx];
                final isSelected = idx == currentIdx;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(pack.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      Text(
                        '₹${pack.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (pack.mrp > pack.price)
                        Text(
                          '₹${pack.mrp.toStringAsFixed(2)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: const Color(0xFF1B7A2B),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedPackIndex[product.id] = idx;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showCheckoutSheet() {
    final nameCtrl = TextEditingController(text: _savedName);
    final phoneCtrl = TextEditingController(text: _savedPhone);
    final addressCtrl = TextEditingController(text: _savedAddress);
    String paymentMethod = 'Cash on Delivery';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final entries = _cartQuantities.entries.where((e) => e.value > 0).toList();
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Basket & Delivery',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$_totalCartItems items',
                          style: const TextStyle(
                            color: Color(0xFF1B7A2B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ...entries.map((entry) {
                      final parts = entry.key.split('::');
                      final product =
                          _allProducts.where((p) => p.id == parts[0]).firstOrNull;
                      if (product == null) return const SizedBox.shrink();
                      final pack = product.packs[int.parse(parts[1])];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${pack.label} • ₹${pack.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${(pack.price * entry.value).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B7A2B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (entry.value <= 1) {
                                          _cartQuantities.remove(entry.key);
                                        } else {
                                          _cartQuantities[entry.key] = entry.value - 1;
                                        }
                                      });
                                      setModalState(() {});
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Icon(Icons.remove, size: 15, color: Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _cartQuantities[entry.key] = entry.value + 1;
                                      });
                                      setModalState(() {});
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Icon(Icons.add, size: 15, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    const Text(
                      'Delivery Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Aapka Naam',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Gaon / Mohalla / Landmark (Address)',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Cash on Delivery'),
                            selected: paymentMethod == 'Cash on Delivery',
                            selectedColor: const Color(0xFFE8F5E9),
                            onSelected: (_) =>
                                setModalState(() => paymentMethod = 'Cash on Delivery'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('UPI on Delivery'),
                            selected: paymentMethod == 'UPI on Delivery',
                            selectedColor: const Color(0xFFE8F5E9),
                            onSelected: (_) =>
                                setModalState(() => paymentMethod = 'UPI on Delivery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B7A2B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: (entries.isEmpty || isSubmitting)
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();
                                final addr = addressCtrl.text.trim();

                                if (name.isEmpty || phone.length < 10 || addr.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kripya naam, 10-digit mobile number aur address bharein.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                try {
                                  await _saveCustomer(name, phone, addr);

                                  final orderItems = entries.map((e) {
                                    final parts = e.key.split('::');
                                    final prod = _allProducts
                                        .firstWhere((p) => p.id == parts[0]);
                                    final pack = prod.packs[int.parse(parts[1])];
                                    return {
                                      'product_id': prod.id,
                                      'name': prod.name,
                                      'pack': pack.label,
                                      'price': pack.price,
                                      'qty': e.value,
                                      'subtotal': pack.price * e.value,
                                    };
                                  }).toList();

                                  await _supabase.from('deua_orders').insert({
                                    'customer_name': name,
                                    'customer_phone': phone,
                                    'delivery_address': addr,
                                    'items': orderItems,
                                    'total_amount': _totalCartPrice,
                                    'payment_method': paymentMethod,
                                    'status': 'Pending',
                                  });

                                  if (!mounted) return;
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _cartQuantities.clear();
                                  });
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Order Confirm Ho Gaya! Hum jald hi delivery karenge.',
                                      ),
                                      backgroundColor: Color(0xFF1B7A2B),
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Order bhejne mein samasya aayi, dobara try karein.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Confirm Order • ₹${_totalCartPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMyOrdersSheet() {
    final phoneCtrl = TextEditingController(text: _savedPhone);
    List> orders = [];
    bool loadingOrders = false;
    bool searched = false;

    Future<void> fetchOrders(StateSetter setModalState) async {
      final phone = phoneCtrl.text.trim();
      if (phone.isEmpty) return;
      setModalState(() {
        loadingOrders = true;
        searched = true;
      });
      try {
        final res = await _supabase
            .from('deua_orders')
            .select()
            .eq('customer_phone', phone)
            .order('created_at', ascending: false);
        setModalState(() {
          orders = List>.from(res);
          loadingOrders = false;
        });
      } catch (_) {
        setModalState(() => loadingOrders = false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool initialized = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!initialized && _savedPhone.isNotEmpty) {
              initialized = true;
              Future.microtask(() => fetchOrders(setModalState));
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Orders (Live Status)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Apna Mobile Number dalein',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B7A2B),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => fetchOrders(setModalState),
                          child: const Text('Check'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loadingOrders
                          ? const Center(child: CircularProgressIndicator())
                          : orders.isEmpty
                              ? Center(
                                  child: Text(
                                    searched
                                        ? 'Is number par koi order nahi mila.'
                                        : 'Orders dekhne ke liye mobile number dalein.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: orders.length,
                                  itemBuilder: (_, idx) {
                                    final ord = orders[idx];
                                    final status = (ord['status'] ?? 'Pending').toString();
                                    final items = ord['items'] as List<dynamic>? ?? [];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Total: ₹${ord['total_amount']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: status == 'Delivered'
                                                        ? const Color(0xFFE8F5E9)
                                                        : const Color(0xFFFFF3E0),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: status == 'Delivered'
                                                          ? const Color(0xFF1B7A2B)
                                                          : Colors.orange[900],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              items
                                                  .map((i) =>
                                                      '${i['name']} (${i['pack']}) x${i['qty']}')
                                                  .join(', '),
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Address: ${ord['delivery_address']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subCats = _currentSubCategories;
    final products = _filteredProducts;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Phal, Sabzi ya Dry fruits khojein...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🥬', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEUA FRESH',
                        style: TextStyle(
                          color: Color(0xFF1B7A2B),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        'Fresh Fruits • Sabzi • Dry Items',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: 'My Orders',
            icon: const Icon(Icons.receipt_long, color: Color(0xFF1B7A2B)),
            onPressed: _showMyOrdersSheet,
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF1B7A2B),
              size: 26,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            height: 54,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _mainCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final mCat = _mainCategories[index];
                final isSelected = mCat.id == _selectedMainCatId;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMainCatId = mCat.id;
                      _selectedSubCatId = 'all';
                      _isSearching = false;
                      _searchQuery = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1B7A2B)
                          : const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(mCat.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          mCat.hindiName.isNotEmpty
                              ? '${mCat.hindiName} (${mCat.name})'
                              : mCat.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B7A2B)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchCatalog,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCatalog,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Sub-Category Sidebar
                      Container(
                        width: 86,
                        color: Colors.white,
                        child: ListView.builder(
                          itemCount: subCats.length,
                          itemBuilder: (context, index) {
                            final cat = subCats[index];
                            final isSelected = cat.id == _selectedSubCatId;
                            final itemCount = _countForSubCategory(cat.id);
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedSubCatId = cat.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE8F5E9)
                                      : Colors.white,
                                  border: Border(
                                    right: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF1B7A2B)
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF1B7A2B)
                                            : cat.bgColor,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        cat.emoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF1B7A2B)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F3F5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$itemCount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Right 2-Column Product Grid
                      Expanded(
                        child: products.isEmpty
                            ? const Center(child: Text('Is category mein abhi items nahi hain.'))
                            : GridView.builder(
                                padding: const EdgeInsets.all(8),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.56,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final item = products[index];
                                  final packIdx = _selectedPackIndex[item.id] ?? 0;
                                  final currentPack = item.packs[packIdx];
                                  final cartKey = '${item.id}::$packIdx';
                                  final qty = _cartQuantities[cartKey] ?? 0;
                                  final isFav = _wishlist.contains(item.id);

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0D000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Image + Overlays
                                        Expanded(
                                          flex: 5,
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                                child: Container(
                                                  width: double.infinity,
                                                  color: item.cardBg,
                                                  child: item.imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          item.imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) =>
                                                              Center(
                                                            child: Text(
                                                              item.fallbackEmoji,
                                                              style: const TextStyle(
                                                                  fontSize: 48),
                                                            ),
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Text(
                                                            item.fallbackEmoji,
                                                            style: const TextStyle(
                                                                fontSize: 48),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              if (item.discountPercent > 0)
                                                Positioned(
                                                  top: 6,
                                                  left: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE53935),
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${item.discountPercent}% OFF',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      if (isFav) {
                                                        _wishlist.remove(item.id);
                                                      } else {
                                                        _wishlist.add(item.id);
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(5),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      isFav
                                                          ? Icons.favorite
                                                          : Icons.favorite_border,
                                                      size: 16,
                                                      color: isFav
                                                          ? Colors.red
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 6,
                                                left: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    currentPack.label,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (item.packs.length > 1)
                                                Positioned(
                                                  bottom: 6,
                                                  right: 6,
                                                  child: InkWell(
                                                    onTap: () =>
                                                        _showPackSelector(item),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(3),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(6),
                                                      ),
                                                      child: const Icon(
                                                        Icons.keyboard_arrow_down,
                                                        size: 18,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Details + Price + Add Button
                                        Expanded(
                                          flex: 4,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  item.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '₹${currentPack.price.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            fontSize: 13.5,
                                                            fontWeight: FontWeight.w800,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        if (currentPack.mrp >
                                                            currentPack.price)
                                                          Flexible(
                                                            child: Text(
                                                              '₹${currentPack.mrp.toStringAsFixed(2)}',
                                                              overflow:
                                                                  TextOverflow.ellipsis,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: Colors.grey,
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      height: 32,
                                                      child: qty == 0
                                                          ? ElevatedButton(
                                                              style: ElevatedButton
                                                                  .styleFrom(
                                                                backgroundColor:
                                                                    const Color(
                                                                        0xFF1B7A2B),
                                                                foregroundColor:
                                                                    Colors.white,
                                                                padding: EdgeInsets.zero,
                                                                elevation: 0,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(7),
                                                                ),
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _cartQuantities[
                                                                      cartKey] = 1;
                                                                });
                                                              },
                                                              child: const Text(
                                                                'Add',
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                ),
                                                              ),
                                                            )
                                                          : Container(
                                                              decoration: BoxDecoration(
                                                                color: const Color(
                                                                    0xFF1B7A2B),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(7),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceEvenly,
                                                                children: [
                                                                  InkWell(
                                                                    onTap: () {
                                                                      setState(() {
                                                                        if (qty <= 1) {
                                                                          _cartQuantities
                                                                              .remove(
                                                                                  cartKey);
                                                                        } else {
                                                                          _cartQuantities[
                                                                                  cartKey] =
                                                                              qty - 1;
                                                                        }
                                                                      });
                                                                    },
                                                                    child: const Padding(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              6),
                                                                      child: Icon(
                                                                        Icons.remove,
                                                                        size: 16,
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    '$qty',
                                                                    style:
                                                                        const TextStyle(
                                                                      color:
                                                                          Colors.white,
                                                                      fontWeight:
                                                                          FontWeight.bold,
                                                                      fontSize: 13,
                                                                    ),
                                                                  ),
                                                                  InkWell(
                                                                    onTap: () {
                                                                      setState(() {
                                                                        _cartQuantities[
                                                                                cartKey] =
                                                                            qty + 1;
                                                                      });
                                                                    },
                                                                    child: const Padding(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              6),
                                                                      child: Icon(
                                                                        Icons.add,
                                                                        size: 16,
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _totalCartItems > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: InkWell(
                  onTap: _showCheckoutSheet,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B7A2B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_totalCartItems Items • ₹${_totalCartPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'Checkout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
