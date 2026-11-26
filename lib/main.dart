import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
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
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7A2B),
          primary: const Color(0xFF1B7A2B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationScreen(),
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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final _supabase = Supabase.instance.client;

  int _currentTab = 0;
  bool _isLoading = true;
  String? _errorMessage;

  List<MainCategory> _mainCategories = [];
  List<SubCategory> _allSubCategories = [];
  List<ProductItem> _allProducts = [];

  String _selectedMainCatId = 'fruits';
  String _selectedSubCatId = 'all';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ordersPhoneController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profilePhoneController = TextEditingController();
  final TextEditingController _profileAddrController =
      TextEditingController(text: 'Deua Village, Bihar');

  final Set<String> _wishlist = {};
  final Map<String, int> _selectedPackIndex = {};
  final Map<String, int> _cartQuantities = {};

  String _savedName = '';
  String _savedPhone = '';
  String _savedAddress = 'Deua Village, Bihar';

  @override
  void initState() {
    super.initState();
    _loadSavedCustomer();
    _fetchCatalog();
  }

  Future<void> _loadSavedCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('cust_name') ?? '';
    final phone = prefs.getString('cust_phone') ?? '';
    final addr = prefs.getString('cust_address') ?? 'Deua Village, Bihar';

    setState(() {
      _savedName = name;
      _savedPhone = phone;
      _savedAddress = addr.isNotEmpty ? addr : 'Deua Village, Bihar';
      _profileNameController.text = _savedName;
      _profilePhoneController.text = _savedPhone;
      _profileAddrController.text = _savedAddress;
      _ordersPhoneController.text = _savedPhone;
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
      _profileNameController.text = name;
      _profilePhoneController.text = phone;
      _profileAddrController.text = address;
      _ordersPhoneController.text = phone;
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

  ProductItem? _findProductById(String id) {
    for (final p in _allProducts) {
      if (p.id == id) return p;
    }
    return null;
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

      final loadedMain = List.from(mainRes).map((item) {
        final row = Map.from(item as Map);
        return MainCategory(
          id: row['id'].toString(),
          name: (row['name'] ?? '').toString(),
          hindiName: (row['hindi_name'] ?? '').toString(),
          emoji: (row['emoji'] ?? '🧺').toString(),
        );
      }).toList();

      final loadedSub = List.from(subRes).map((item) {
        final row = Map.from(item as Map);
        return SubCategory(
          id: row['id'].toString(),
          mainCategoryId: (row['main_category_id'] ?? '').toString(),
          name: (row['name'] ?? '').toString(),
          emoji: (row['emoji'] ?? '🌿').toString(),
          bgColor: _parseHexColor(
            row['bg_color']?.toString(),
            const Color(0xFFE8F5E9),
          ),
        );
      }).toList();

      final loadedProducts = List.from(prodRes).map((item) {
        final row = Map.from(item as Map);
        final rawPacks = row['packs'] is List ? List.from(row['packs'] as List) : [];
        final packs = rawPacks.map((p) {
          final m = Map.from(p as Map);
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
          cardBg: _parseHexColor(
            row['card_bg']?.toString(),
            const Color(0xFFF1F8E9),
          ),
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
      final product = _findProductById(parts[0]);
      if (product != null) {
        final packIdx = int.parse(parts[1]);
        if (packIdx < product.packs.length) {
          sum += product.packs[packIdx].price * entry.value;
        }
      }
    }
    return sum;
  }

  void _openCategory(String mainCatId, {String subCatId = 'all'}) {
    setState(() {
      _selectedMainCatId = mainCatId;
      _selectedSubCatId = subCatId;
      _searchQuery = '';
      _searchController.clear();
      _currentTab = 1;
    });
  }

  void _showProductDetailSheet(ProductItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final packIdx = _selectedPackIndex[item.id] ?? 0;
            final currentPack = item.packs[packIdx];
            final cartKey = '${item.id}::$packIdx';
            final qty = _cartQuantities[cartKey] ?? 0;
            final savings = currentPack.mrp - currentPack.price;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 210,
                      width: double.infinity,
                      color: item.cardBg,
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  item.fallbackEmoji,
                                  style: const TextStyle(fontSize: 72),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                item.fallbackEmoji,
                                style: const TextStyle(fontSize: 72),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.discountPercent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.discountPercent}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Farm-fresh quality • Fast doorstep delivery',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select Pack Size:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: List.generate(item.packs.length, (idx) {
                      final p = item.packs[idx];
                      final selected = idx == packIdx;
                      return ChoiceChip(
                        label: Text('${p.label} • ₹${p.price.toStringAsFixed(0)}'),
                        selected: selected,
                        selectedColor: const Color(0xFFE8F5E9),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? const Color(0xFF1B7A2B)
                              : Colors.black87,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedPackIndex[item.id] = idx);
                          setModalState(() {});
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '₹${currentPack.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (currentPack.mrp > currentPack.price)
                                Text(
                                  '₹${currentPack.mrp.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          if (savings > 0)
                            Text(
                              'You save ₹${savings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF1B7A2B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                        width: 150,
                        height: 44,
                        child: qty == 0
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B7A2B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _cartQuantities[cartKey] = 1);
                                  setModalState(() {});
                                },
                                child: const Text(
                                  'Add to Cart',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B7A2B),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          if (qty <= 1) {
                                            _cartQuantities.remove(cartKey);
                                          } else {
                                            _cartQuantities[cartKey] = qty - 1;
                                          }
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _cartQuantities[cartKey] = qty + 1;
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
    final messenger = ScaffoldMessenger.of(context);
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
          builder: (modalContext, setModalState) {
            final entries = _cartQuantities.entries.where((e) => e.value > 0).toList();
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(modalContext).viewInsets.bottom + 16,
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
                      final product = _findProductById(parts[0]);
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
                                  messenger.showSnackBar(
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
                                    final prod = _findProductById(parts[0])!;
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
                                    _currentTab = 2;
                                  });
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Order Confirm Ho Gaya! Hum jald hi delivery karenge.',
                                      ),
                                      backgroundColor: Color(0xFF1B7A2B),
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  messenger.showSnackBar(
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

  Widget _buildProductCard(ProductItem item) {
    final packIdx = _selectedPackIndex[item.id] ?? 0;
    final currentPack = item.packs[packIdx];
    final cartKey = '${item.id}::$packIdx';
    final qty = _cartQuantities[cartKey] ?? 0;
    final isFav = _wishlist.contains(item.id);

    return GestureDetector(
      onTap: () => _showProductDetailSheet(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Container(
                      width: double.infinity,
                      color: item.cardBg,
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1B7A2B),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  item.fallbackEmoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                item.fallbackEmoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                    ),
                  ),
                  if (item.discountPercent > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
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
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFav ? Colors.red : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentPack.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
                        onTap: () => _showPackSelector(item),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
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
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${currentPack.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 5),
                            if (currentPack.mrp > currentPack.price)
                              Flexible(
                                child: Text(
                                  '₹${currentPack.mrp.toStringAsFixed(0)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B7A2B),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _cartQuantities[cartKey] = 1;
                                    });
                                  },
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B7A2B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (qty <= 1) {
                                              _cartQuantities.remove(cartKey);
                                            } else {
                                              _cartQuantities[cartKey] = qty - 1;
                                            }
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _cartQuantities[cartKey] = qty + 1;
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.add,
                                            size: 16,
                                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildHomeTab() {
    final searchResults = _searchQuery.isEmpty
        ? <ProductItem>[]
        : _allProducts
            .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final bestDeals = _allProducts.where((p) => p.discountPercent >= 18).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchCatalog,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF145E20), Color(0xFF1B7A2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.amberAccent, size: 22),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _currentTab = 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'DEUA FRESH • Express Delivery',
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down,
                                      color: Colors.amberAccent, size: 16),
                                ],
                              ),
                              Text(
                                _savedAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _currentTab = 3),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search "Apple", "Tamatar", "Badam"...',
                        hintStyle: const TextStyle(fontSize: 13.5, color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF1B7A2B)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_searchQuery.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'Search Results (${searchResults.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (searchResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Koi item nahi mila.')),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: searchResults.length,
                  itemBuilder: (_, i) => _buildProductCard(searchResults[i]),
                ),
            ] else ...[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFE8F5E9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B7A2B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'UP TO 25% OFF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Taaza Phal, Hari Sabzi & Dry Fruits',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Seedha aapke ghar tak • Cash & UPI available',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B7A2B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _openCategory('fruits'),
                            child: const Text(
                              'Shop Now >',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🧺', style: TextStyle(fontSize: 56)),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Shop by Category',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: _mainCategories.map((cat) {
                    final cardColors = {
                      'fruits': const Color(0xFFFFEBEE),
                      'vegetables': const Color(0xFFE8F5E9),
                      'dry': const Color(0xFFFFF8E1),
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _openCategory(cat.id),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cardColors[cat.id] ?? Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            children: [
                              Text(cat.emoji, style: const TextStyle(fontSize: 34)),
                              const SizedBox(height: 6),
                              Text(
                                cat.hindiName.isNotEmpty ? cat.hindiName : cat.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Best Deals Today',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    InkWell(
                      onTap: () => setState(() => _currentTab = 1),
                      child: const Text(
                        'See All >',
                        style: TextStyle(
                          color: Color(0xFF1B7A2B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: bestDeals.length > 6 ? 6 : bestDeals.length,
                itemBuilder: (_, i) => _buildProductCard(bestDeals[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final subList = _allSubCategories
        .where((s) => s.mainCategoryId == _selectedMainCatId)
        .toList();

    final subCats = [
      SubCategory(
        id: 'all',
        mainCategoryId: _selectedMainCatId,
        name: 'All Items',
        emoji: '🧺',
        bgColor: const Color(0xFFFFF3E0),
      ),
      ...subList,
    ];

    final products = _allProducts.where((item) {
      final matchesMain = item.mainCategoryId == _selectedMainCatId;
      final matchesSub =
          _selectedSubCatId == 'all' || item.subCategoryId == _selectedSubCatId;
      return matchesMain && matchesSub;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        title: const Text(
          'All Categories',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            height: 52,
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            color: Colors.white,
            child: ListView.builder(
              itemCount: subCats.length,
              itemBuilder: (context, index) {
                final cat = subCats[index];
                final isSelected = cat.id == _selectedSubCatId;
                final count = cat.id == 'all'
                    ? _allProducts
                        .where((p) => p.mainCategoryId == _selectedMainCatId)
                        .length
                    : _allProducts
                        .where((p) =>
                            p.mainCategoryId == _selectedMainCatId &&
                            p.subCategoryId == cat.id)
                        .length;
                return InkWell(
                  onTap: () => setState(() => _selectedSubCatId = cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
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
                                : cat.
