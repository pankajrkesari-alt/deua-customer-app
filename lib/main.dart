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
  final List packs;

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
  State createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State {
  final _supabase = Supabase.instance.client;

  int _currentTab = 0;
  bool _isLoading = true;
  String? _errorMessage;

  List _mainCategories = [];
  List _allSubCategories = [];
  List _allProducts = [];

  String _selectedMainCatId = 'fruits';
  String _selectedSubCatId = 'all';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profilePhoneController = TextEditingController();
  final TextEditingController _profileAddrController =
      TextEditingController(text: 'Deua Village, Bihar');

  final Set _wishlist = {};
  final Map _selectedPackIndex = {};
  final Map _cartQuantities = {};

  String _savedName = '';
  String _savedPhone = '';
  String _savedAddress = 'Deua Village, Bihar';

  @override
  void initState() {
    super.initState();
    _loadSavedCustomer();
    _fetchCatalog();
  }

  Future _loadSavedCustomer() async {
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
    });
  }

  Future _saveCustomer(String name, String phone, String address) async {
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
    for (final item in _allProducts) {
      final p = item as ProductItem;
      if (p.id == id) return p;
    }
    return null;
  }

  Future _fetchCatalog() async {
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

      final List loadedMain = [];
      for (final item in (mainRes as List)) {
        final row = Map.from(item as Map);
        loadedMain.add(MainCategory(
          id: row['id'].toString(),
          name: (row['name'] ?? '').toString(),
          hindiName: (row['hindi_name'] ?? '').toString(),
          emoji: (row['emoji'] ?? '🧺').toString(),
        ));
      }

      final List loadedSub = [];
      for (final item in (subRes as List)) {
        final row = Map.from(item as Map);
        loadedSub.add(SubCategory(
          id: row['id'].toString(),
          mainCategoryId: (row['main_category_id'] ?? '').toString(),
          name: (row['name'] ?? '').toString(),
          emoji: (row['emoji'] ?? '🌿').toString(),
          bgColor: _parseHexColor(
            row['bg_color']?.toString(),
            const Color(0xFFE8F5E9),
          ),
        ));
      }

      final List loadedProducts = [];
      for (final item in (prodRes as List)) {
        final row = Map.from(item as Map);
        final rawPacks = row['packs'] is List ? List.from(row['packs'] as List) : [];
        final List packs = [];
        for (final p in rawPacks) {
          final m = Map.from(p as Map);
          packs.add(PackOption(
            label: (m['label'] ?? '1 pack').toString(),
            price: (m['price'] as num? ?? 0).toDouble(),
            mrp: (m['mrp'] as num? ?? 0).toDouble(),
          ));
        }

        if (packs.isEmpty) {
          packs.add(const PackOption(label: '1 unit', price: 0, mrp: 0));
        }

        loadedProducts.add(ProductItem(
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
        ));
      }

      setState(() {
        _mainCategories = loadedMain;
        _allSubCategories = loadedSub;
        _allProducts = loadedProducts;
        if (_mainCategories.isNotEmpty) {
          bool found = false;
          for (final item in _mainCategories) {
            if ((item as MainCategory).id == _selectedMainCatId) {
              found = true;
              break;
            }
          }
          if (!found) {
            _selectedMainCatId = (_mainCategories.first as MainCategory).id;
          }
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
    for (final val in _cartQuantities.values) {
      total += (val as int);
    }
    return total;
  }

  double get _totalCartPrice {
    double sum = 0;
    for (final entry in _cartQuantities.entries) {
      final parts = entry.key.toString().split('::');
      final product = _findProductById(parts[0]);
      if (product != null) {
        final packIdx = int.parse(parts[1]);
        if (packIdx < product.packs.length) {
          final pack = product.packs[packIdx] as PackOption;
          sum += pack.price * (entry.value as int);
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
            final int packIdx = (_selectedPackIndex[item.id] as int?) ?? 0;
            final currentPack = item.packs[packIdx] as PackOption;
            final cartKey = '${item.id}::$packIdx';
            final int qty = (_cartQuantities[cartKey] as int?) ?? 0;
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
                      final p = item.packs[idx] as PackOption;
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
        final int currentIdx = (_selectedPackIndex[product.id] as int?) ?? 0;
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
                final pack = product.packs[idx] as PackOption;
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
            final entries =
                _cartQuantities.entries.where((e) => (e.value as int) > 0).toList();
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
                      final parts = entry.key.toString().split('::');
                      final product = _findProductById(parts[0]);
                      if (product == null) return const SizedBox.shrink();
                      final pack = product.packs[int.parse(parts[1])] as PackOption;
                      final int itemQty = entry.value as int;
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
                              '₹${(pack.price * itemQty).toStringAsFixed(2)}',
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
                                        if (itemQty <= 1) {
                                          _cartQuantities.remove(entry.key);
                                        } else {
                                          _cartQuantities[entry.key] = itemQty - 1;
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
                                    '$itemQty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _cartQuantities[entry.key] = itemQty + 1;
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

                                  final List orderItems = [];
                                  for (final e in entries) {
                                    final parts = e.key.toString().split('::');
                                    final prod = _findProductById(parts[0])!;
                                    final pack = prod.packs[int.parse(parts[1])] as PackOption;
                                    final int q = e.value as int;
                                    orderItems.add({
                                      'product_id': prod.id,
                                      'name': prod.name,
                                      'pack': pack.label,
                                      'price': pack.price,
                                      'qty': q,
                                      'subtotal': pack.price * q,
                                    });
                                  }

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
