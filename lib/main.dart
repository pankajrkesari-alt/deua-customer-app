import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String kSupabaseUrl = 'https://cvbubouqkoladwhemzcf.supabase.co';
const String kSupabaseAnonKey =
    'sb_publishable_gSYtFINdgJzEQwYLJ9M8pg_zxMs6SK5';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
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
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7A2B),
          primary: const Color(0xFF1B7A2B),
        ),
      ),
      home: const CustomerShellScreen(),
    );
  }
}

class CustomerShellScreen extends StatefulWidget {
  const CustomerShellScreen({super.key});

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  final _supabase = Supabase.instance.client;

  int _tabIndex = 1; // 0: Home, 1: Categories (Left Sidebar), 2: Orders, 3: Profile
  bool _loading = true;
  String? _error;

  List> _categories = [];
  List> _subCategories = [];
  List> _products = [];
  List> _orders = [];

  String _selectedCatId = '';
  String _selectedSubCatId = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final Map<String, int> _selectedPackIndex = {};
  final Map<String, Map<String, dynamic>> _cart = {};

  String _savedPincode = '';
  String _customerName = '';
  String _customerPhone = '';
  String _customerAddress = '';

  @override
  void initState() {
    super.initState();
    _loadPrefsAndData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefsAndData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    _savedPincode = prefs.getString('deua_pincode') ?? '';
    _customerName = prefs.getString('deua_cust_name') ?? '';
    _customerPhone = prefs.getString('deua_cust_phone') ?? '';
    _customerAddress = prefs.getString('deua_cust_addr') ?? '';

    try {
      final catRes = await _supabase
          .from('deua_main_categories')
          .select()
          .order('sort_order');
      final cats = List>.from(catRes as List);

      List> subCats = [];
      try {
        final subRes = await _supabase
            .from('deua_sub_categories')
            .select()
            .order('sort_order');
        subCats = List>.from(subRes as List);
      } catch (_) {}

      final prodRes = await _supabase
          .from('deua_products')
          .select()
          .order('created_at', ascending: false);
      final prods = List>.from(prodRes as List);

      List> ords = [];
      try {
        if (_customerPhone.trim().isNotEmpty) {
          final ordRes = await _supabase
              .from('deua_orders')
              .select()
              .eq('customer_phone', _customerPhone.trim())
              .order('created_at', ascending: false);
          ords = List>.from(ordRes as List);
        } else {
          final ordRes = await _supabase
              .from('deua_orders')
              .select()
              .order('created_at', ascending: false)
              .limit(20);
          ords = List>.from(ordRes as List);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _categories = cats;
        _subCategories = subCats;
        _products = prods;
        _orders = ords;

        final validIds = cats.map((c) => c['id'].toString()).toSet();
        if (_selectedCatId.isEmpty || !validIds.contains(_selectedCatId)) {
          _selectedCatId = cats.isNotEmpty ? cats.first['id'].toString() : '';
          _selectedSubCatId = 'all';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Data load error: $e';
        _loading = false;
      });
    }
  }

  List> _packsOf(Map<String, dynamic> prod) {
    final raw = prod['packs'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final price = (prod['price'] as num?)?.toDouble() ?? 0;
    final mrp = (prod['mrp'] as num?)?.toDouble() ?? price;
    return [
      {
        'label': (prod['unit'] ?? '1 unit').toString(),
        'price': price,
        'mrp': mrp < price ? price : mrp,
      }
    ];
  }

  void _addToCart(Map<String, dynamic> prod) {
    if (prod['in_stock'] == false) {
      _toast('यह सामान अभी Out of Stock है।', isError: true);
      return;
    }
    final pid = prod['id'].toString();
    final packs = _packsOf(prod);
    final pIdx = (_selectedPackIndex[pid] ?? 0).clamp(0, packs.length - 1);
    final pack = packs[pIdx];
    final key = '${pid}_$pIdx';

    final price = (pack['price'] as num?)?.toDouble() ?? 0;
    final label = (pack['label'] ?? '1 pack').toString();

    setState(() {
      if (_cart.containsKey(key)) {
        _cart[key]!['qty'] = (_cart[key]!['qty'] as int) + 1;
      } else {
        _cart[key] = {
          'product_id': pid,
          'name': (prod['name'] ?? '').toString(),
          'pack': label,
          'price': price,
          'image_url': (prod['image_url'] ?? '').toString(),
          'qty': 1,
        };
      }
    });
    _toast('${prod['name']} ($label) cart mein add hua');
  }

  void _changeCartQty(String key, int delta) {
    setState(() {
      if (!_cart.containsKey(key)) return;
      final nextQty = ((_cart[key]!['qty'] as int?) ?? 1) + delta;
      if (nextQty <= 0) {
        _cart.remove(key);
      } else {
        _cart[key]!['qty'] = nextQty;
      }
    });
  }

  double get _cartTotal {
    double sum = 0;
    for (final item in _cart.values) {
      final p = (item['price'] as num?)?.toDouble() ?? 0;
      final q = (item['qty'] as num?)?.toInt() ?? 1;
      sum += p * q;
    }
    return sum;
  }

  int get _cartCount {
    int cnt = 0;
    for (final item in _cart.values) {
      cnt += (item['qty'] as num?)?.toInt() ?? 1;
    }
    return cnt;
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1B7A2B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveProfileDetails({
    required String name,
    required String phone,
    required String address,
    required String pincode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deua_cust_name', name.trim());
    await prefs.setString('deua_cust_phone', phone.trim());
    await prefs.setString('deua_cust_addr', address.trim());
    await prefs.setString('deua_pincode', pincode.trim());
    setState(() {
      _customerName = name.trim();
      _customerPhone = phone.trim();
      _customerAddress = address.trim();
      _savedPincode = pincode.trim();
    });
    _toast('Profile details save ho gayi.');
  }

  Future<void> _checkPincode(String pin) async {
    final clean = pin.trim();
    if (clean.length != 6) {
      _toast('6 digit ka PIN code dalein.', isError: true);
      return;
    }
    try {
      final res = await _supabase
          .from('deua_service_pincodes')
          .select()
          .eq('pincode', clean);
      final list = List>.from(res as List);
      final activeRow = list.where((r) => r['is_active'] != false).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deua_pincode', clean);
      setState(() => _savedPincode = clean);

      if (activeRow.isNotEmpty) {
        final area = (activeRow.first['area_name'] ?? '').toString();
        _toast('Delivery available in $clean ${area.isNotEmpty ? "($area)" : ""}');
      } else {
        _toast('Is PIN par abhi delivery active nahi hai, lekin PIN save ho gaya.', isError: true);
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deua_pincode', clean);
      setState(() => _savedPincode = clean);
      _toast('PIN code $clean save kar liya gaya.');
    }
  }

  Future<void> _openCartAndCheckout() async {
    if (_cart.isEmpty) {
      _toast('Cart khali hai, pehle सामान add karein.', isError: true);
      return;
    }

    final nameCtrl = TextEditingController(text: _customerName);
    final phoneCtrl = TextEditingController(text: _customerPhone);
    final addrCtrl = TextEditingController(
      text: _customerAddress.isNotEmpty ? _customerAddress : 'Deua Village, Bihar',
    );
    final pinCtrl = TextEditingController(text: _savedPincode);
    String paymentMethod = 'COD';
    bool placing = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (mCtx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(mCtx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cart ($_cartCount) • Checkout',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${_cartTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B7A2B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._cart.entries.map((entry) {
                  final key = entry.key;
                  final item = entry.value;
                  final qty = (item['qty'] as num?)?.toInt() ?? 1;
                  final price = (item['price'] as num?)?.toDouble() ?? 0;
                  return Card(
                    color: const Color(0xFFF9FBF9),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        '${item['name']} (${item['pack']})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text('₹${(price * qty).toStringAsFixed(0)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () {
                              _changeCartQty(key, -1);
                              setModal(() {});
                              if (_cart.isEmpty) Navigator.pop(ctx);
                            },
                          ),
                          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF1B7A2B)),
                            onPressed: () {
                              _changeCartQty(key, 1);
                              setModal(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'आपका नाम • Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'मोबाइल नंबर • Phone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'PIN Code',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'पूरा पता • Delivery Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'COD', child: Text('Cash on Delivery (COD)')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => paymentMethod = v);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B7A2B),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: placing
                        ? null
                        : () async {
                            final nm = nameCtrl.text.trim();
                            final ph = phoneCtrl.text.trim();
                            final ad = addrCtrl.text.trim();
                            final pn = pinCtrl.text.trim();
                            if (nm.isEmpty || ph.length < 8 || ad.isEmpty) {
                              _toast('नाम, मोबाइल नंबर और पता ज़रूर भरें।', isError: true);
                              return;
                            }
                            setModal(() => placing = true);
                            try {
                              final itemsList = _cart.values.toList();
                              await _supabase.from('deua_orders').insert({
                                'customer_name': nm,
                                'customer_phone': ph,
                                'delivery_address': pn.isNotEmpty ? '$ad (PIN: $pn)' : ad,
                                'items': itemsList,
                                'total_amount': _cartTotal,
                                'payment_method': paymentMethod,
                                'status': 'Pending',
                              });

                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('deua_cust_name', nm);
                              await prefs.setString('deua_cust_phone', ph);
                              await prefs.setString('deua_cust_addr', ad);
                              if (pn.isNotEmpty) {
                                await prefs.setString('deua_pincode', pn);
                              }

                              if (!mounted) return;
                              setState(() {
                                _customerName = nm;
                                _customerPhone = ph;
                                _customerAddress = ad;
                                if (pn.isNotEmpty) _savedPincode = pn;
                                _cart.clear();
                                _tabIndex = 2;
                              });
                              Navigator.pop(ctx);
                              await _loadPrefsAndData();
                              _toast('ऑर्डर सफलतापूर्वक दर्ज हो गया!');
                            } catch (e) {
                              setModal(() => placing = false);
                              _toast('Order error: $e', isError: true);
                            }
                          },
                    child: Text(
                      placing ? 'ऑर्डर भेजा जा रहा है...' : 'ऑर्डर करें • Place Order (₹${_cartTotal.toStringAsFixed(0)})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _netImage(String? url, {double? width, double? height}) {
    final clean = (url ?? '').trim();
    if (clean.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.eco, color: Color(0xFF1B7A2B)),
      );
    }
    return Image.network(
      clean,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.eco, color: Color(0xFF1B7A2B)),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> prod) {
    final pid = prod['id'].toString();
    final packs = _packsOf(prod);
    final pIdx = (_selectedPackIndex[pid] ?? 0).clamp(0, packs.length - 1);
    final activePack = packs[pIdx];
    final price = (activePack['price'] as num?)?.toDouble() ?? 0;
    final mrp = (activePack['mrp'] as num?)?.toDouble() ?? price;
    final disc = (prod['discount_percent'] as num?)?.toInt() ?? 0;
    final inStock = prod['in_stock'] != false;

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _netImage(prod['image_url']?.toString()),
                if (disc > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B7A2B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$disc% OFF',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (packs.length > 1)
                  SizedBox(
                    height: 28,
                    child: DropdownButtonFormField<int>(
                      value: pIdx,
                      isDense: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        packs.length,
                        (idx) => DropdownMenuItem<int>(
                          value: idx,
                          child: Text(
                            (packs[idx]['label'] ?? '').toString(),
                            style: const TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedPackIndex[pid] = v);
                      },
                    ),
                  )
                else
                  Text(
                    (activePack['label'] ?? '').toString(),
                    style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                  ),
                const SizedBox(height: 4),
                Text(
                  (prod['name'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    if (mrp > price) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹${mrp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black45,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inStock ? const Color(0xFF1B7A2B) : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: inStock ? () => _addToCart(prod) : null,
                    child: Text(
                      inStock ? 'Add' : 'Out of Stock',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadPrefsAndData,
      color: const Color(0xFF1B7A2B),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B7A2B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEUA FRESH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _savedPincode.isNotEmpty
                      ? 'Delivery PIN: $_savedPincode'
                      : 'ताज़ा फल, सब्ज़ियां व किराना सामान',
                  style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 12.5),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B7A2B),
                  ),
                  onPressed: () => setState(() => _tabIndex = 1),
                  child: const Text('सभी श्रेणियां देखें • Shop Now', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('लोकप्रिय सामान • Popular Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) => _buildProductCard(_products[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final q = _searchQuery.trim().toLowerCase();
    final activeSubCats = _subCategories
        .where((s) => (s['main_category_id'] ?? '').toString() == _selectedCatId)
        .toList();

    final catProducts = _products.where((p) {
      final matchesCat =
          _selectedCatId.isEmpty || (p['main_category_id'] ?? '').toString() == _selectedCatId;
      final matchesSubCat = _selectedSubCatId == 'all' ||
          (p['sub_category_id'] ?? '').toString() == _selectedSubCatId;
      final matchesSearch =
          q.isEmpty || (p['name'] ?? '').toString().toLowerCase().contains(q);
      return matchesCat && matchesSubCat && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'सभी श्रेणियां • All Categories',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${_categories.length} श्रेणियां',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B7A2B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'सामान खोजें • Search items...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1B7A2B), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (activeSubCats.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedSubCatId == 'all',
                          selectedColor: const Color(0xFF1B7A2B),
                          labelStyle: TextStyle(
                            color: _selectedSubCatId == 'all' ? Colors.white : Colors.black87,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => _selectedSubCatId = 'all'),
                        ),
                      ),
                      ...activeSubCats.map((sc) {
                        final sid = sc['id'].toString();
                        final sel = _selectedSubCatId == sid;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text((sc['name'] ?? '').toString()),
                            selected: sel,
                            selectedColor: const Color(0xFF1B7A2B),
                            labelStyle: TextStyle(
                              color: sel ? Colors.white : Colors.black87,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setState(() => _selectedSubCatId = sid),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 98,
                child: Container(
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final cid = cat['id'].toString();
                      final selected = cid == _selectedCatId;
                      final hindi = (cat['hindi_name'] ?? '').toString();
                      final eng = (cat['name'] ?? '').toString();
                      final itemCount = _products
                          .where((p) => (p['main_category_id'] ?? '').toString() == cid)
                          .length;

                      return InkWell(
                        onTap: () => setState(() {
                          _selectedCatId = cid;
                          _selectedSubCatId = 'all';
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFE8F5E9) : Colors.white,
                            border: Border(
                              left: BorderSide(
                                color: selected ? const Color(0xFF1B7A2B) : Colors.transparent,
                                width: 3.5,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              ClipOval(
                                child: _netImage(cat['image_url']?.toString(), width: 46, height: 46),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hindi.isNotEmpty ? hindi : eng,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              if (eng.isNotEmpty && hindi.isNotEmpty)
                                Text(
                                  eng,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9.5, color: Colors.black54),
                                ),
                              Text(
                                '$itemCount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF1B7A2B),
                                  fontWeight: FontWeight.bold,
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadPrefsAndData,
                  color: const Color(0xFF1B7A2B),
                  child: catProducts.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('इस श्रेणी में अभी सामान नहीं है।')),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: catProducts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (_, i) => _buildProductCard(catProducts[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadPrefsAndData,
      color: const Color(0xFF1B7A2B),
      child: _orders.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('अभी कोई ऑर्डर नहीं मिला है।')),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              itemBuilder: (_, i) {
                final ord = _orders[i];
                final status = (ord['status'] ?? 'Pending').toString();
                final total = ord['total_amount'] ?? 0;
                final items = ord['items'] is List ? List.from(ord['items'] as List) : [];

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order • $status',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B7A2B)),
                            ),
                            Text('₹$total', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Items: ${items.length} • ${ord['payment_method'] ?? 'COD'}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileTab() {
    final nameCtrl = TextEditingController(text: _customerName);
    final phoneCtrl = TextEditingController(text: _customerPhone);
    final addrCtrl = TextEditingController(text: _customerAddress);
    final pinCtrl = TextEditingController(text: _savedPincode);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'नाम • Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'मोबाइल नंबर • Phone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'पता • Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit PIN Code',
                          border: OutlineInputBorder(),
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
                      onPressed: () => _checkPincode(pinCtrl.text),
                      child: const Text('Check PIN'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _saveProfileDetails(
                      name: nameCtrl.text,
                      phone: phoneCtrl.text,
                      address: addrCtrl.text,
                      pincode: pinCtrl.text,
                    ),
                    child: const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1B7A2B)),
            title: Text('Cart Items: $_cartCount'),
            subtitle: Text('Total: ₹${_cartTotal.toStringAsFixed(0)}'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B7A2B),
                foregroundColor: Colors.white,
              ),
              onPressed: _openCartAndCheckout,
              child: const Text('Cart / Checkout'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    if (_loading) {
      currentBody = const Center(child: CircularProgressIndicator(color: Color(0xFF1B7A2B)));
    } else if (_error != null) {
      currentBody = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    } else {
      switch (_tabIndex) {
        case 0:
          currentBody = _buildHomeTab();
          break;
        case 1:
          currentBody = _buildCategoriesTab();
          break;
        case 2:
          currentBody = _buildOrdersTab();
          break;
        default:
          currentBody = _buildProfileTab();
      }
    }

    return Scaffold(
      body: SafeArea(child: currentBody),
      floatingActionButton: _cartCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1B7A2B),
              foregroundColor: Colors.white,
              onPressed: _openCartAndCheckout,
              icon: const Icon(Icons.shopping_bag),
              label: Text('Cart ($_cartCount) • ₹${_cartTotal.toStringAsFixed(0)}'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        indicatorColor: const Color(0xFFE8F5E9),
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
