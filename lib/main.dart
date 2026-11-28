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
  State createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State {
  final _supabase = Supabase.instance.client;

  int _tabIndex = 0; // 0: Home, 1: Categories, 2: Orders, 3: Profile
  bool _loading = true;
  String? _error;

  List _categories = [];
  List _subCategories = [];
  List _products = [];
  List _orders = [];

  String _selectedCatId = '';
  String _selectedSubCatId = 'all';
  String _searchQuery = '';
  bool _showCatSearch = false;
  final _searchCtrl = TextEditingController();
  final _homeSearchCtrl = TextEditingController();

  final Map _selectedPackIndex = {};
  final Map _cart = {};
  final Set _favorites = {};

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
    _homeSearchCtrl.dispose();
    super.dispose();
  }

  Future _loadPrefsAndData() async {
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
      final cats = List.from(catRes as List);

      List subCats = [];
      try {
        final subRes = await _supabase
            .from('deua_sub_categories')
            .select()
            .order('sort_order');
        subCats = List.from(subRes as List);
      } catch (_) {}

      final prodRes = await _supabase
          .from('deua_products')
          .select()
          .order('created_at', ascending: false);
      final prods = List.from(prodRes as List);

      List ords = [];
      try {
        if (_customerPhone.trim().isNotEmpty) {
          final ordRes = await _supabase
              .from('deua_orders')
              .select()
              .eq('customer_phone', _customerPhone.trim())
              .order('created_at', ascending: false);
          ords = List.from(ordRes as List);
        } else {
          final ordRes = await _supabase
              .from('deua_orders')
              .select()
              .order('created_at', ascending: false)
              .limit(20);
          ords = List.from(ordRes as List);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _categories = cats;
        _subCategories = subCats;
        _products = prods;
        _orders = ords;

        final validIds =
            cats.map((c) => Map.from(c as Map)['id'].toString()).toSet();
        if (_selectedCatId.isEmpty || !validIds.contains(_selectedCatId)) {
          _selectedCatId = cats.isNotEmpty
              ? Map.from(cats.first as Map)['id'].toString()
              : '';
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

  List _packsOf(Map prod) {
    final raw = prod['packs'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => Map.from(e as Map)).toList();
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

  void _addToCart(Map prod) {
    if (prod['in_stock'] == false) {
      _toast('यह सामान अभी Out of Stock है।', isError: true);
      return;
    }
    final pid = prod['id'].toString();
    final packs = _packsOf(prod);
    final int pIdx = ((_selectedPackIndex[pid] as int?) ?? 0)
        .clamp(0, packs.length - 1)
        .toInt();
    final pack = Map.from(packs[pIdx] as Map);
    final key = '${pid}_$pIdx';

    final price = (pack['price'] as num?)?.toDouble() ?? 0;
    final label = (pack['label'] ?? '1 pack').toString();

    setState(() {
      if (_cart.containsKey(key)) {
        final cur = Map.from(_cart[key] as Map);
        cur['qty'] = ((cur['qty'] as num?)?.toInt() ?? 1) + 1;
        _cart[key] = cur;
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
      final cur = Map.from(_cart[key] as Map);
      final nextQty = ((cur['qty'] as num?)?.toInt() ?? 1) + delta;
      if (nextQty <= 0) {
        _cart.remove(key);
      } else {
        cur['qty'] = nextQty;
        _cart[key] = cur;
      }
    });
  }

  double get _cartTotal {
    double sum = 0;
    for (final rawItem in _cart.values) {
      final item = Map.from(rawItem as Map);
      final p = (item['price'] as num?)?.toDouble() ?? 0;
      final q = (item['qty'] as num?)?.toInt() ?? 1;
      sum += p * q;
    }
    return sum;
  }

  int get _cartCount {
    int cnt = 0;
    for (final rawItem in _cart.values) {
      final item = Map.from(rawItem as Map);
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

  Future _saveProfileDetails({
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

  Future _checkPincode(String pin) async {
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
      final list = List.from(res as List);
      final activeRow = list
          .map((r) => Map.from(r as Map))
          .where((r) => r['is_active'] != false)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deua_pincode', clean);
      setState(() => _savedPincode = clean);

      if (activeRow.isNotEmpty) {
        final area = (activeRow.first['area_name'] ?? '').toString();
        _toast(
          'Delivery available in $clean ${area.isNotEmpty ? "($area)" : ""}',
        );
      } else {
        _toast(
          'Is PIN par abhi delivery active nahi hai, lekin PIN save ho gaya.',
          isError: true,
        );
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deua_pincode', clean);
      setState(() => _savedPincode = clean);
      _toast('PIN code $clean save kar liya gaya.');
    }
  }

  Future _openCartAndCheckout() async {
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
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
                  final key = entry.key.toString();
                  final item = Map.from(entry.value as Map);
                  final qty = (item['qty'] as num?)?.toInt() ?? 1;
                  final price = (item['price'] as num?)?.toDouble() ?? 0;
                  return Card(
                    color: const Color(0xFFF9FBF9),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        '${item['name']} (${item['pack']})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text('₹${(price * qty).toStringAsFixed(0)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                            ),
                            onPressed: () {
                              _changeCartQty(key, -1);
                              setModal(() {});
                              if (_cart.isEmpty) Navigator.pop(ctx);
                            },
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                              color: Color(0xFF1B7A2B),
                            ),
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
                DropdownButtonFormField(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'COD',
                      child: Text('Cash on Delivery (COD)'),
                    ),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => paymentMethod = v.toString());
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
                              _toast(
                                'नाम, मोबाइल नंबर और पता ज़रूर भरें।',
                                isError: true,
                              );
                              return;
                            }
                            setModal(() => placing = true);
                            try {
                              final itemsList = _cart.values.toList();
                              await _supabase.from('deua_orders').insert({
                                'customer_name': nm,
                                'customer_phone': ph,
                                'delivery_address':
                                    pn.isNotEmpty ? '$ad (PIN: $pn)' : ad,
                                'items': itemsList,
                                'total_amount': _cartTotal,
                                'payment_method': paymentMethod,
                                'status': 'Pending',
                              });

                              final prefs =
                                  await SharedPreferences.getInstance();
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
                      placing
                          ? 'ऑर्डर भेजा जा रहा है...'
                          : 'ऑर्डर करें • Place Order (₹${_cartTotal.toStringAsFixed(0)})',
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
        child: const Icon(Icons.eco, color: Color(0xFF1B7A2B), size: 28),
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
        child: const Icon(Icons.eco, color: Color(0xFF1B7A2B), size: 28),
      ),
    );
  }

  Widget _buildProductCard(Map prod) {
    final pid = prod['id'].toString();
    final packs = _packsOf(prod);
    final int pIdx = ((_selectedPackIndex[pid] as int?) ?? 0)
        .clamp(0, packs.length - 1)
        .toInt();
    final activePack = Map.from(packs[pIdx] as Map);
    final price = (activePack['price'] as num?)?.toDouble() ?? 0;
    final mrp = (activePack['mrp'] as num?)?.toDouble() ?? price;
    final disc = (prod['discount_percent'] as num?)?.toInt() ?? 0;
    final inStock = prod['in_stock'] != false;
    final isFav = _favorites.contains(pid);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Large Image + Red Discount Pill + Heart Icon + Floating Pack Pill
          Expanded(
            flex: 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _netImage(prod['image_url']?.toString()),
                if (disc > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5534B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$disc% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
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
                          _favorites.remove(pid);
                        } else {
                          _favorites.add(pid);
                        }
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
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
                  child: packs.length > 1
                      ? PopupMenuButton(
                          onSelected: (val) {
                            setState(() => _selectedPackIndex[pid] = val);
                          },
                          itemBuilder: (_) => List.generate(
                            packs.length,
                            (idx) => PopupMenuItem(
                              value: idx,
                              child: Text(
                                '${Map.from(packs[idx] as Map)['label']} - ₹${Map.from(packs[idx] as Map)['price']}',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (activePack['label'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 15,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (activePack['label'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Details + Price + Add Button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (prod['name'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    if (mrp > price) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹${mrp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          inStock ? const Color(0xFF1B7A2B) : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: inStock ? () => _addToCart(prod) : null,
                    child: Text(
                      inStock ? 'Add' : 'Out of Stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
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
    String bannerImg = '';
    for (final c in _categories) {
      final m = Map.from(c as Map);
      final url = (m['image_url'] ?? '').toString().trim();
      if (url.isNotEmpty) {
        bannerImg = url;
        if ((m['name'] ?? '').toString().toLowerCase().contains('fruit')) break;
      }
    }

    final locationLine = _customerAddress.isNotEmpty
        ? _customerAddress
        : (_savedPincode.isNotEmpty
            ? 'Deua Village, Bihar ($_savedPincode)'
            : 'Deua Village, Bihar');

    return RefreshIndicator(
      onRefresh: _loadPrefsAndData,
      color: const Color(0xFF1B7A2B),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1B7A2B),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFFFD54F),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEUA FRESH • ताज़ा व तेज़ डिलीवरी',
                            style: TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            locationLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _homeSearchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) {
                    setState(() {
                      _searchQuery = v.trim();
                      _searchCtrl.text = v.trim();
                      _showCatSearch = true;
                      _selectedSubCatId = 'all';
                      _tabIndex = 1;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'खोजें: सेब, टमाटर, दाल, मसाले, दूध...',
                    hintStyle:
                        const TextStyle(fontSize: 13.5, color: Colors.black54),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF1B7A2B)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UP TO 25% OFF • भारी छूट',
                          style: TextStyle(
                            color: Color(0xFF1B7A2B),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'फल, सब्ज़ी, किराना, मसाले व डेयरी',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Fruits, Veg, Grocery & Dairy',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B7A2B),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () => setState(() => _tabIndex = 1),
                          child: const Text(
                            'अभी खरीदें • Shop Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _netImage(bannerImg, width: 92, height: 92),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              'सभी श्रेणियां • Shop by Category',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.78,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (_, i) {
              final cat = Map.from(_categories[i] as Map);
              final cid = cat['id'].toString();
              final hindi = (cat['hindi_name'] ?? '').toString();
              final eng = (cat['name'] ?? '').toString();

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedCatId = cid;
                    _selectedSubCatId = 'all';
                    _searchQuery = '';
                    _searchCtrl.clear();
                    _tabIndex = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: double.infinity,
                            child: _netImage(cat['image_url']?.toString()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hindi.isNotEmpty ? hindi : eng,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (eng.isNotEmpty && hindi.isNotEmpty)
                        Text(
                          eng,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(14, 16, 14, 8),
            child: Text(
              'लोकप्रिय सामान • Popular Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) =>
                _buildProductCard(Map.from(_products[i] as Map)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final q = _searchQuery.trim().toLowerCase();
    final activeSubCats = _subCategories
        .map((s) => Map.from(s as Map))
        .where((s) => (s['main_category_id'] ?? '').toString() == _selectedCatId)
        .toList();

    final hasSubCats = activeSubCats.isNotEmpty;

    final catProducts = _products
        .map((p) => Map.from(p as Map))
        .where((p) {
          final matchesCat = _selectedCatId.isEmpty ||
              (p['main_category_id'] ?? '').toString() == _selectedCatId;
          final matchesSubCat = !hasSubCats ||
              _selectedSubCatId == 'all' ||
              (p['sub_category_id'] ?? '').toString() == _selectedSubCatId;
          final matchesSearch =
              q.isEmpty || (p['name'] ?? '').toString().toLowerCase().contains(q);
          return matchesCat && matchesSubCat && matchesSearch;
        })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header + Search Toggle + Horizontal Main Category Pills
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _showCatSearch ? Icons.close : Icons.search,
                      color: const Color(0xFF1B7A2B),
                    ),
                    onPressed: () {
                      setState(() {
                        _showCatSearch = !_showCatSearch;
                        if (!_showCatSearch) {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_showCatSearch) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'सामान खोजें • Search items...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF1B7A2B),
                      size: 20,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = Map.from(_categories[i] as Map);
                    final cid = cat['id'].toString();
                    final sel = cid == _selectedCatId;
                    final hindi = (cat['hindi_name'] ?? '').toString();
                    final eng = (cat['name'] ?? '').toString();
                    final label = hindi.isNotEmpty && eng.isNotEmpty
                        ? '$hindi ($eng)'
                        : (hindi.isNotEmpty ? hindi : eng);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() {
                          _selectedCatId = cid;
                          _selectedSubCatId = 'all';
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFE8F5E9) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF1B7A2B)
                                  : Colors.grey.shade300,
                              width: sel ? 1.4 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipOval(
                                child: _netImage(
                                  cat['image_url']?.toString(),
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight:
                                      sel ? FontWeight.w800 : FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Left Sidebar + Right Product Grid
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Container(
                  color: Colors.white,
                  child: hasSubCats
                      ? ListView.builder(
                          itemCount: activeSubCats.length + 1,
                          itemBuilder: (_, i) {
                            final isAll = i == 0;
                            final sid = isAll
                                ? 'all'
                                : activeSubCats[i - 1]['id'].toString();
                            final sel = _selectedSubCatId == sid;
                            final title = isAll
                                ? 'सभी आइटम\n(All)'
                                : (activeSubCats[i - 1]['name'] ?? '')
                                    .toString();
                            final img = isAll
                                ? (_categories.isNotEmpty
                                    ? Map.from(_categories.first as Map)['image_url']
                                        ?.toString()
                                    : '')
                                : activeSubCats[i - 1]['image_url']?.toString();

                            final count = isAll
                                ? _products
                                    .where((p) =>
                                        (Map.from(p as Map)['main_category_id'] ??
                                                '')
                                            .toString() ==
                                        _selectedCatId)
                                    .length
                                : _products
                                    .where((p) =>
                                        (Map.from(p as Map)['sub_category_id'] ??
                                                '')
                                            .toString() ==
                                        sid)
                                    .length;

                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedSubCatId = sid),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFFE8F5E9)
                                      : Colors.white,
                                  border: Border(
                                    right: BorderSide(
                                      color: sel
                                          ? const Color(0xFF1B7A2B)
                                          : Colors.transparent,
                                      width: 3.5,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: sel
                                              ? const Color(0xFF1B7A2B)
                                              : Colors.grey.shade200,
                                          width: sel ? 2 : 1,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: _netImage(
                                          img,
                                          width: 44,
                                          height: 44,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: sel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: sel
                                            ? const Color(0xFF1B7A2B)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (_, i) {
                            final cat = Map.from(_categories[i] as Map);
                            final cid = cat['id'].toString();
                            final sel = cid == _selectedCatId;
                            final hindi = (cat['hindi_name'] ?? '').toString();
                            final eng = (cat['name'] ?? '').toString();
                            final count = _products
                                .where((p) =>
                                    (Map.from(p as Map)['main_category_id'] ??
                                            '')
                                        .toString() ==
                                    cid)
                                .length;

                            return InkWell(
                              onTap: () => setState(() {
                                _selectedCatId = cid;
                                _selectedSubCatId = 'all';
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFFE8F5E9)
                                      : Colors.white,
                                  border: Border(
                                    right: BorderSide(
                                      color: sel
                                          ? const Color(0xFF1B7A2B)
                                          : Colors.transparent,
                                      width: 3.5,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    ClipOval(
                                      child: _netImage(
                                        cat['image_url']?.toString(),
                                        width: 44,
                                        height: 44,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      hindi.isNotEmpty ? hindi : eng,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: sel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$count',
                                      style: const TextStyle(
                                        fontSize: 9.5,
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
                            Center(
                              child: Text('इस श्रेणी में अभी सामान नहीं है।'),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: catProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.56,
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
                final ord = Map.from(_orders[i] as Map);
                final status = (ord['status'] ?? 'Pending').toString();
                final total = ord['total_amount'] ?? 0;
                final items =
                    ord['items'] is List ? List.from(ord['items'] as List) : [];

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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B7A2B),
                              ),
                            ),
                            Text(
                              '₹$total',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
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
                const Text(
                  'Customer Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
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
            leading: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF1B7A2B),
            ),
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
      currentBody = const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B7A2B)),
      );
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
              label: Text(
                'Cart ($_cartCount) • ₹${_cartTotal.toStringAsFixed(0)}',
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        indicatorColor: const Color(0xFFE8F5E9),
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
