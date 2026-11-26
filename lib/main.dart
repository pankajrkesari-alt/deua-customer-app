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
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainCategory {
  final String id, name, hindiName, imageUrl;
  const MainCategory({required this.id, required this.name, required this.hindiName, required this.imageUrl});
}

class SubCategory {
  final String id, mainCategoryId, name, imageUrl;
  final Color bgColor;
  const SubCategory({required this.id, required this.mainCategoryId, required this.name, required this.imageUrl, required this.bgColor});
}

class PackOption {
  final String label;
  final double price, mrp;
  const PackOption({required this.label, required this.price, required this.mrp});
}

class ProductItem {
  final String id, mainCategoryId, subCategoryId, name, imageUrl;
  final int discountPercent;
  final Color cardBg;
  final List packs;
  const ProductItem({
    required this.id,
    required this.mainCategoryId,
    required this.subCategoryId,
    required this.name,
    required this.discountPercent,
    required this.imageUrl,
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

  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController(text: 'Deua Village, Bihar');

  final Set _wishlist = {};
  final Map _selectedPackIdx = {};
  final Map _cart = {};

  String _savedName = '';
  String _savedPhone = '';
  String _savedAddress = 'Deua Village, Bihar';

  static const String _basketBannerUrl = 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400';

  @override
  void initState() {
    super.initState();
    _loadCustomer();
    _fetchCatalog();
  }

  Future _loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedName = prefs.getString('cust_name') ?? '';
      _savedPhone = prefs.getString('cust_phone') ?? '';
      final addr = prefs.getString('cust_address') ?? '';
      if (addr.isNotEmpty) _savedAddress = addr;
      _nameCtrl.text = _savedName;
      _phoneCtrl.text = _savedPhone;
      _addrCtrl.text = _savedAddress;
    });
  }

  Future _saveCustomer(String name, String phone, String addr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cust_name', name);
    await prefs.setString('cust_phone', phone);
    await prefs.setString('cust_address', addr);
    setState(() {
      _savedName = name;
      _savedPhone = phone;
      _savedAddress = addr;
      _nameCtrl.text = name;
      _phoneCtrl.text = phone;
      _addrCtrl.text = addr;
    });
  }

  Color _hexColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final v = int.tryParse('FF$clean', radix: 16);
      if (v != null) return Color(v);
    }
    return fallback;
  }

  ProductItem? _findProduct(String id) {
    for (final item in _allProducts) {
      final p = item as ProductItem;
      if (p.id == id) return p;
    }
    return null;
  }

  Widget _netImg(String url, {double? width, double? height, double iconSize = 28}) {
    if (url.isEmpty) {
      return Icon(Icons.eco, color: const Color(0xFF1B7A2B), size: iconSize);
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(Icons.eco, color: const Color(0xFF1B7A2B), size: iconSize),
    );
  }

  Future _fetchCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final mRes = await _supabase.from('deua_main_categories').select().order('sort_order');
      final sRes = await _supabase.from('deua_sub_categories').select().order('sort_order');
      final pRes = await _supabase.from('deua_products').select().eq('in_stock', true).order('created_at');

      final List mains = [];
      for (final x in (mRes as List)) {
        final r = Map.from(x as Map);
        mains.add(MainCategory(
          id: r['id'].toString(),
          name: (r['name'] ?? '').toString(),
          hindiName: (r['hindi_name'] ?? '').toString(),
          imageUrl: (r['image_url'] ?? _basketBannerUrl).toString(),
        ));
      }

      final List subs = [];
      for (final x in (sRes as List)) {
        final r = Map.from(x as Map);
        subs.add(SubCategory(
          id: r['id'].toString(),
          mainCategoryId: (r['main_category_id'] ?? '').toString(),
          name: (r['name'] ?? '').toString(),
          imageUrl: (r['image_url'] ?? _basketBannerUrl).toString(),
          bgColor: _hexColor(r['bg_color']?.toString(), const Color(0xFFE8F5E9)),
        ));
      }

      final List prods = [];
      for (final x in (pRes as List)) {
        final r = Map.from(x as Map);
        final rawPacks = r['packs'] is List ? List.from(r['packs'] as List) : [];
        final List packs = [];
        for (final p in rawPacks) {
          final m = Map.from(p as Map);
          packs.add(PackOption(
            label: (m['label'] ?? '1 pack').toString(),
            price: (m['price'] as num? ?? 0).toDouble(),
            mrp: (m['mrp'] as num? ?? 0).toDouble(),
          ));
        }
        if (packs.isEmpty) packs.add(const PackOption(label: '1 unit', price: 0, mrp: 0));
        prods.add(ProductItem(
          id: r['id'].toString(),
          mainCategoryId: (r['main_category_id'] ?? '').toString(),
          subCategoryId: (r['sub_category_id'] ?? '').toString(),
          name: (r['name'] ?? '').toString(),
          discountPercent: (r['discount_percent'] as num? ?? 0).toInt(),
          imageUrl: (r['image_url'] ?? '').toString(),
          cardBg: _hexColor(r['card_bg']?.toString(), const Color(0xFFF1F8E9)),
          packs: packs,
        ));
      }

      setState(() {
        _mainCategories = mains;
        _allSubCategories = subs;
        _allProducts = prods;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Internet connection check karein aur Retry dabayein.';
        _isLoading = false;
      });
    }
  }

  int get _cartCount {
    int total = 0;
    for (final v in _cart.values) {
      total += (v as int);
    }
    return total;
  }

  double get _cartTotal {
    double sum = 0;
    for (final e in _cart.entries) {
      final parts = e.key.toString().split('::');
      final p = _findProduct(parts[0]);
      if (p != null) {
        final pack = p.packs[int.parse(parts[1])] as PackOption;
        sum += pack.price * (e.value as int);
      }
    }
    return sum;
  }

  void _openCategory(String mainId) {
    setState(() {
      _selectedMainCatId = mainId;
      _selectedSubCatId = 'all';
      _searchQuery = '';
      _searchCtrl.clear();
      _currentTab = 1;
    });
  }

  void _showPackSheet(ProductItem product) {
    if (product.packs.length <= 1) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final int cur = (_selectedPackIdx[product.id] as int?) ?? 0;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...List.generate(product.packs.length, (i) {
                final pack = product.packs[i] as PackOption;
                return ListTile(
                  title: Text(pack.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('₹${pack.price.toStringAsFixed(0)}  (MRP ₹${pack.mrp.toStringAsFixed(0)})'),
                  trailing: Icon(i == cur ? Icons.radio_button_checked : Icons.radio_button_off, color: const Color(0xFF1B7A2B)),
                  onTap: () {
                    setState(() => _selectedPackIdx[product.id] = i);
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

  void _showProductDetail(ProductItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) {
          final int pIdx = (_selectedPackIdx[item.id] as int?) ?? 0;
          final pack = item.packs[pIdx] as PackOption;
          final key = '${item.id}::$pIdx';
          final int qty = (_cart[key] as int?) ?? 0;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    color: item.cardBg,
                    child: _netImg(item.imageUrl, iconSize: 56),
                  ),
                ),
                const SizedBox(height: 12),
                Text(item.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: List.generate(item.packs.length, (i) {
                    final p = item.packs[i] as PackOption;
                    return ChoiceChip(
                      label: Text('${p.label} • ₹${p.price.toStringAsFixed(0)}'),
                      selected: i == pIdx,
                      selectedColor: const Color(0xFFE8F5E9),
                      onSelected: (_) {
                        setState(() => _selectedPackIdx[item.id] = i);
                        setModal(() {});
                      },
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${pack.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() => _cart[key] = qty + 1);
                        setModal(() {});
                      },
                      child: Text(qty == 0 ? 'Add to Cart' : 'In Cart ($qty) + Add'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCheckout() {
    final messenger = ScaffoldMessenger.of(context);
    final nCtrl = TextEditingController(text: _savedName);
    final pCtrl = TextEditingController(text: _savedPhone);
    final aCtrl = TextEditingController(text: _savedAddress);
    String payMode = 'Cash on Delivery';
    bool busy = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (mCtx, setModal) {
          final entries = _cart.entries.where((e) => (e.value as int) > 0).toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(mCtx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('आपकी टोकरी • Your Basket ($_cartCount items)', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...entries.map((e) {
                    final parts = e.key.toString().split('::');
                    final prod = _findProduct(parts[0]);
                    if (prod == null) return const SizedBox.shrink();
                    final pack = prod.packs[int.parse(parts[1])] as PackOption;
                    final int q = e.value as int;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${prod.name} (${pack.label})'),
                      subtitle: Text('₹${pack.price.toStringAsFixed(0)} x $q = ₹${(pack.price * q).toStringAsFixed(0)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF1B7A2B)),
                            onPressed: () {
                              setState(() => q <= 1 ? _cart.remove(e.key) : _cart[e.key] = q - 1);
                              setModal(() {});
                            },
                          ),
                          Text('$q', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B7A2B)),
                            onPressed: () {
                              setState(() => _cart[e.key] = q + 1);
                              setModal(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'आपका नाम (Your Name)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 8),
                  TextField(controller: pCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर (Mobile Number)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 8),
                  TextField(controller: aCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'पूरा पता (Delivery Address)', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Cash on Delivery', 'UPI on Delivery'].map((m) {
                      return ChoiceChip(
                        label: Text(m),
                        selected: payMode == m,
                        selectedColor: const Color(0xFFE8F5E9),
                        onSelected: (_) => setModal(() => payMode = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
                      onPressed: (entries.isEmpty || busy) ? null : () async {
                        final name = nCtrl.text.trim();
                        final phone = pCtrl.text.trim();
                        final addr = aCtrl.text.trim();
                        if (name.isEmpty || phone.length < 10 || addr.isEmpty) {
                          messenger.showSnackBar(const SnackBar(content: Text('कृपया नाम, 10-अंकों का मोबाइल नंबर और पता भरें।'), backgroundColor: Colors.red));
                          return;
                        }
                        setModal(() => busy = true);
                        try {
                          await _saveCustomer(name, phone, addr);
                          final List itemsList = [];
                          for (final e in entries) {
                            final parts = e.key.toString().split('::');
                            final prod = _findProduct(parts[0])!;
                            final pack = prod.packs[int.parse(parts[1])] as PackOption;
                            final int q = e.value as int;
                            itemsList.add({'name': prod.name, 'pack': pack.label, 'price': pack.price, 'qty': q});
                          }
                          await _supabase.from('deua_orders').insert({
                            'customer_name': name,
                            'customer_phone': phone,
                            'delivery_address': addr,
                            'items': itemsList,
                            'total_amount': _cartTotal,
                            'payment_method': payMode,
                            'status': 'Pending',
                          });
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          setState(() {
                            _cart.clear();
                            _currentTab = 2;
                          });
                          messenger.showSnackBar(const SnackBar(content: Text('ऑर्डर कन्फर्म हो गया! Order Confirmed'), backgroundColor: Color(0xFF1B7A2B)));
                        } catch (_) {
                          setModal(() => busy = false);
                          messenger.showSnackBar(const SnackBar(content: Text('ऑर्डर भेजने में समस्या आई, पुनः प्रयास करें।'), backgroundColor: Colors.red));
                        }
                      },
                      child: Text(busy ? 'ऑर्डर हो रहा है...' : 'ऑर्डर कन्फर्म करें • ₹${_cartTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productCard(ProductItem item) {
    final int pIdx = (_selectedPackIdx[item.id] as int?) ?? 0;
    final pack = item.packs[pIdx] as PackOption;
    final key = '${item.id}::$pIdx';
    final int qty = (_cart[key] as int?) ?? 0;
    final fav = _wishlist.contains(item.id);

    return GestureDetector(
      onTap: () => _showProductDetail(item),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      width: double.infinity,
                      color: item.cardBg,
                      child: _netImg(item.imageUrl, iconSize: 40),
                    ),
                  ),
                  if (item.discountPercent > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                        child: Text('${item.discountPercent}% OFF', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => setState(() => fav ? _wishlist.remove(item.id) : _wishlist.add(item.id)),
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.white,
                        child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 15, color: fav ? Colors.red : Colors.black54),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: InkWell(
                      onTap: () => _showPackSheet(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(pack.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            if (item.packs.length > 1) const Icon(Icons.keyboard_arrow_down, size: 15),
                          ],
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
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('₹${pack.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 5),
                            if (pack.mrp > pack.price)
                              Text('₹${pack.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: qty == 0
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white, padding: EdgeInsets.zero),
                                  onPressed: () => setState(() => _cart[key] = 1),
                                  child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                                )
                              : Container(
                                  decoration: BoxDecoration(color: const Color(0xFF1B7A2B), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: () => setState(() => qty <= 1 ? _cart.remove(key) : _cart[key] = qty - 1),
                                        child: const Icon(Icons.remove, size: 16, color: Colors.white),
                                      ),
                                      Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      InkWell(
                                        onTap: () => setState(() => _cart[key] = qty + 1),
                                        child: const Icon(Icons.add, size: 16, color: Colors.white),
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

  Widget _homeTab() {
    final List searched = [];
    if (_searchQuery.isNotEmpty) {
      for (final x in _allProducts) {
        final p = x as ProductItem;
        if (p.name.toLowerCase().contains(_searchQuery.toLowerCase())) searched.add(p);
      }
    }
    final List deals = [];
    for (final x in _allProducts) {
      final p = x as ProductItem;
      if (p.discountPercent >= 15) deals.add(p);
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchCatalog,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF1B7A2B),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.amberAccent, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _currentTab = 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DEUA FRESH • ताज़ा व तेज़ डिलीवरी', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(_savedAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'खोजें: सेब (Apple), टमाटर, काजू...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF1B7A2B)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() {
                                  _searchQuery = '';
                                  _searchCtrl.clear();
                                }),
                              )
                            : null,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text('खोज परिणाम • Search Results (${searched.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: searched.length,
                itemBuilder: (_, i) => _productCard(searched[i] as ProductItem),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('UP TO 25% OFF • भारी छूट', style: TextStyle(color: Color(0xFF1B7A2B), fontWeight: FontWeight.w900, fontSize: 11.5)),
                          const SizedBox(height: 4),
                          const Text('ताज़े फल, हरी सब्ज़ी व ड्राई फ्रूट्स\nFresh Fruits, Veg & Dry Items', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
                            onPressed: () => _openCategory('fruits'),
                            child: const Text('अभी खरीदें • Shop Now'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _netImg(_basketBannerUrl, width: 92, height: 92),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text('फल, सब्ज़ी व किराना • Shop by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: _mainCategories.map((x) {
                    final cat = x as MainCategory;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _openCategory(cat.id),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _netImg(cat.imageUrl, width: double.infinity, height: 68),
                              ),
                              const SizedBox(height: 6),
                              Text(cat.hindiName.isNotEmpty ? cat.hindiName : cat.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              Text(cat.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Text('आज के खास ऑफ़र • Best Deals Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: deals.length > 6 ? 6 : deals.length,
                itemBuilder: (_, i) => _productCard(deals[i] as ProductItem),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoriesTab() {
    final List subs = [
      SubCategory(id: 'all', mainCategoryId: _selectedMainCatId, name: 'सभी आइटम (All)', imageUrl: _basketBannerUrl, bgColor: const Color(0xFFFFF3E0)),
    ];
    for (final x in _allSubCategories) {
      final s = x as SubCategory;
      if (s.mainCategoryId == _selectedMainCatId) subs.add(s);
    }

    final List prods = [];
    for (final x in _allProducts) {
      final p = x as ProductItem;
      if (p.mainCategoryId == _selectedMainCatId && (_selectedSubCatId == 'all' || p.subCategoryId == _selectedSubCatId)) {
        prods.add(p);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('सभी श्रेणियां • All Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _mainCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = _mainCategories[i] as MainCategory;
                final sel = m.id == _selectedMainCatId;
                final label = m.hindiName.isNotEmpty ? '${m.hindiName} (${m.name})' : m.name;
                return ChoiceChip(
                  avatar: ClipOval(child: _netImg(m.imageUrl, width: 24, height: 24, iconSize: 16)),
                  label: Text(label),
                  selected: sel,
                  selectedColor: const Color(0xFF1B7A2B),
                  labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                  onSelected: (_) => setState(() {
                    _selectedMainCatId = m.id;
                    _selectedSubCatId = 'all';
                  }),
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
            width: 88,
            color: Colors.white,
            child: ListView.builder(
              itemCount: subs.length,
              itemBuilder: (_, i) {
                final s = subs[i] as SubCategory;
                final sel = s.id == _selectedSubCatId;
                return InkWell(
                  onTap: () => setState(() => _selectedSubCatId = s.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFE8F5E9) : Colors.white,
                      border: Border(right: BorderSide(color: sel ? const Color(0xFF1B7A2B) : Colors.transparent, width: 3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: sel ? const Color(0xFF1B7A2B) : Colors.black12, width: 2),
                          ),
                          child: ClipOval(child: _netImg(s.imageUrl, width: 44, height: 44, iconSize: 20)),
                        ),
                        const SizedBox(height: 5),
                        Text(s.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: sel ? FontWeight.bold : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.56, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: prods.length,
              itemBuilder: (_, i) => _productCard(prods[i] as ProductItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTab() {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, title: const Text('प्रोफ़ाइल व पता • Profile & Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'आपका नाम (Your Name)', filled: true, fillColor: Colors.white, border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर (Mobile Number)', filled: true, fillColor: Colors.white, border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _addrCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'डिलीवरी पता (Delivery Address)', filled: true, fillColor: Colors.white, border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await _saveCustomer(_nameCtrl.text.trim(), _phoneCtrl.text.trim(), _addrCtrl.text.trim());
                messenger.showSnackBar(const SnackBar(content: Text('पता सेव हो गया! Address Saved'), backgroundColor: Color(0xFF1B7A2B)));
              },
              child: const Text('सेव करें • Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1B7A2B))));
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _fetchCatalog, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final tabs = [_homeTab(), _categoriesTab(), const OrdersTabView(), _profileTab()];

    return Scaffold(
      body: Stack(
        children: [
          tabs[_currentTab],
          if (_cartCount > 0)
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: InkWell(
                onTap: _showCheckout,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF1B7A2B), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_cartCount Items • ₹${_cartTotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Text('टोकरी देखें • View Cart >', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F5E9),
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF1B7A2B)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF1B7A2B)), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF1B7A2B)), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFF1B7A2B)), label: 'Profile'),
        ],
      ),
    );
  }
}

class OrdersTabView extends StatefulWidget {
  const OrdersTabView({super.key});
  @override
  State createState() => _OrdersTabViewState();
}

class _OrdersTabViewState extends State {
  final _supabase = Supabase.instance.client;
  final _phoneCtrl = TextEditingController();
  List _orders = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future _initLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final ph = prefs.getString('cust_phone') ?? '';
    if (ph.isNotEmpty) {
      _phoneCtrl.text = ph;
      await _fetchOrders();
    }
  }

  Future _fetchOrders() async {
    final ph = _phoneCtrl.text.trim();
    if (ph.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await _supabase.from('deua_orders').select().eq('customer_phone', ph).order('created_at', ascending: false);
      setState(() {
        _orders = List.from(res as List);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, title: const Text('मेरे ऑर्डर • My Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'मोबाइल नंबर डालें (Mobile Number)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
                  onPressed: _fetchOrders,
                  child: const Text('Check'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? const Center(child: Text('कोई ऑर्डर नहीं मिला • No orders found'))
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (_, i) {
                            final ord = Map.from(_orders[i] as Map);
                            final items = ord['items'] is List ? List.from(ord['items'] as List) : [];
                            return Card(
                              color: Colors.white,
                              child: ListTile(
                                title: Text('Total: ₹${ord['total_amount']} • ${ord['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(items.map((e) => '${(e as Map)['name']} x${e['qty']}').join(', ')),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
