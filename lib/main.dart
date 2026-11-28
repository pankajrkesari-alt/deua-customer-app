import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String kSupabaseUrl = 'https://cvbubouqkoladwhemzcf.supabase.co';
const String kSupabaseAnonKey =
    'sb_publishable_gSYtFINdgJzEQwYLJ9M8pg_zxMs6SK5';

// Future-ready settings (yahan se kabhi bhi badal sakte hain)
const double kDeliveryCharge = 0; // Abhi FREE hai; aage 15 ya 20 kar sakte hain
const double kFreeDeliveryMinOrder = 0; // Jaise 199 se upar FREE rakhna ho
const String kSupportPhone = '+91 99999 99999'; // Apna WhatsApp/Call number dalein
const String kUpiId = 'pankajram3507@pnb';
const String kUpiName = 'PANKAJ RAM';

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

  int _tabIndex = 0; // 0: Home, 1: Categories, 2: Cart, 3: Orders, 4: Profile
  bool _loading = true;
  String? _error;

  List _categories = [];
  List _subCategories = [];
  List _products = [];
  List _orders = [];
  List _banners = [];

  String _selectedCatId = 'all';
  String _selectedSubCatId = 'all';
  String _searchQuery = '';
  bool _showCatSearch = false;
  int _bannerPage = 0;

  final _bannerCtrl = PageController();
  final _searchCtrl = TextEditingController();
  final _homeSearchCtrl = TextEditingController();

  final _profileNameCtrl = TextEditingController();
  final _profilePhoneCtrl = TextEditingController();
  final _profileAddrCtrl = TextEditingController();
  final _profilePinCtrl = TextEditingController();
  final _deliveryNoteCtrl = TextEditingController();

  String _checkoutPayment = 'COD';
  bool _placingOrder = false;

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
    _bannerCtrl.dispose();
    _searchCtrl.dispose();
    _homeSearchCtrl.dispose();
    _profileNameCtrl.dispose();
    _profilePhoneCtrl.dispose();
    _profileAddrCtrl.dispose();
    _profilePinCtrl.dispose();
    _deliveryNoteCtrl.dispose();
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

    _profileNameCtrl.text = _customerName;
    _profilePhoneCtrl.text = _customerPhone;
    _profileAddrCtrl.text = _customerAddress.isNotEmpty
        ? _customerAddress
        : 'Deua Village, Bihar';
    _profilePinCtrl.text = _savedPincode;

    final savedFavs = prefs.getStringList('deua_favs') ?? [];
    _favorites.clear();
    _favorites.addAll(savedFavs);

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

      List loadedBanners = [];
      try {
        final banRes = await _supabase
            .from('deua_banners')
            .select()
            .eq('is_active', true)
            .order('sort_order');
        loadedBanners = List.from(banRes as List);
      } catch (_) {}

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
        _banners = loadedBanners;
        _orders = ords;

        final validIds =
            cats.map((c) => Map.from(c as Map)['id'].toString()).toSet();
        if (_selectedCatId != 'all' && !validIds.contains(_selectedCatId)) {
          _selectedCatId = 'all';
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

  Future _toggleFavorite(String pid) async {
    setState(() {
      if (_favorites.contains(pid)) {
        _favorites.remove(pid);
      } else {
        _favorites.add(pid);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'deua_favs',
      _favorites.map((e) => e.toString()).toList(),
    );
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
      _toast('Out of Stock • यह सामान अभी उपलब्ध नहीं है', isError: true);
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
    final mrp = (pack['mrp'] as num?)?.toDouble() ?? price;
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
          'mrp': mrp < price ? price : mrp,
          'image_url': (prod['image_url'] ?? '').toString(),
          'qty': 1,
        };
      }
    });
  }

  void _reorderItems(Map ord) {
    final rawItems = ord['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      _toast('Is order mein koi item nahi mila.', isError: true);
      return;
    }
    setState(() {
      for (final raw in rawItems) {
        final item = Map.from(raw as Map);
        final pid = (item['product_id'] ?? item['name'] ?? '').toString();
        final pack = (item['pack'] ?? '1 pack').toString();
        final key = 're_${pid}_$pack';
        final qty = (item['qty'] as num?)?.toInt() ?? 1;
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        final mrp = (item['mrp'] as num?)?.toDouble() ?? price;
        if (_cart.containsKey(key)) {
          final cur = Map.from(_cart[key] as Map);
          cur['qty'] = ((cur['qty'] as num?)?.toInt() ?? 1) + qty;
          _cart[key] = cur;
        } else {
          _cart[key] = {
            'product_id': pid,
            'name': (item['name'] ?? '').toString(),
            'pack': pack,
            'price': price,
            'mrp': mrp < price ? price : mrp,
            'image_url': (item['image_url'] ?? '').toString(),
            'qty': qty,
          };
        }
      }
      _tabIndex = 2; // Cart tab
    });
    _toast('Items cart mein add ho gaye • कार्ट में जुड़ गए');
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

  double get _cartSavings {
    double saved = 0;
    for (final rawItem in _cart.values) {
      final item = Map.from(rawItem as Map);
      final p = (item['price'] as num?)?.toDouble() ?? 0;
      final m = (item['mrp'] as num?)?.toDouble() ?? p;
      final q = (item['qty'] as num?)?.toInt() ?? 1;
      if (m > p) {
        saved += (m - p) * q;
      }
    }
    return saved;
  }

  double get _deliveryFee {
    if (kDeliveryCharge <= 0) return 0;
    if (kFreeDeliveryMinOrder > 0 && _cartTotal >= kFreeDeliveryMinOrder) {
      return 0;
    }
    return kDeliveryCharge;
  }

  double get _grandTotal => _cartTotal + _deliveryFee;

  int get _cartCount {
    int cnt = 0;
    for (final rawItem in _cart.values) {
      final item = Map.from(rawItem as Map);
      cnt += (item['qty'] as num?)?.toInt() ?? 1;
    }
    return cnt;
  }

  String _formatOrderId(dynamic rawId) {
    final clean = (rawId ?? '').toString().replaceAll('-', '').toUpperCase();
    if (clean.isEmpty) return '#DF-0000';
    final part = clean.length >= 4
        ? clean.substring(clean.length - 4)
        : clean.padLeft(4, '0');
    return '#DF-$part';
  }

  String _formatDateTime(dynamic rawDate) {
    final s = (rawDate ?? '').toString().trim();
    if (s.isEmpty) return '';
    final dt = DateTime.tryParse(s)?.toLocal();
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[dt.month - 1];
    final hr12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} $m, $hr12:$min $ampm';
  }

  int _statusStepIndex(String status) {
    final s = status.toLowerCase();
    if (s.contains('deliver')) return 3;
    if (s.contains('out') || s.contains('way') || s.contains('ship')) return 2;
    if (s.contains('pack') || s.contains('confirm') || s.contains('accept')) {
      return 1;
    }
    return 0;
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
    _toast('Profile saved • प्रोफाइल सेव हो गई');
  }

  Future _checkPincode(String pin) async {
    final clean = pin.trim();
    if (clean.length != 6) {
      _toast('Enter 6-digit PIN • 6 अंकों का पिन डालें', isError: true);
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
          'Delivery not active on $clean yet, PIN saved.',
          isError: true,
        );
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deua_pincode', clean);
      setState(() => _savedPincode = clean);
      _toast('PIN code $clean saved.');
    }
  }

  Future _placeOrderFromCart() async {
    if (_cart.isEmpty) {
      _toast('Cart is empty • पहले सामान जोड़ें', isError: true);
      return;
    }
    final nm = _profileNameCtrl.text.trim();
    final ph = _profilePhoneCtrl.text.trim();
    final ad = _profileAddrCtrl.text.trim();
    final pn = _profilePinCtrl.text.trim();
    final note = _deliveryNoteCtrl.text.trim();
    if (nm.isEmpty || ph.length < 8 || ad.isEmpty) {
      _toast('नाम, मोबाइल नंबर और पता ज़रूर भरें।', isError: true);
      return;
    }

    String fullAddress = ad;
    if (pn.isNotEmpty) {
      fullAddress = '$fullAddress (PIN: $pn)';
    }
    if (note.isNotEmpty) {
      fullAddress = '$fullAddress | Note: $note';
    }

    setState(() => _placingOrder = true);
    try {
      final itemsList = _cart.values.toList();
      await _supabase.from('deua_orders').insert({
        'customer_name': nm,
        'customer_phone': ph,
        'delivery_address': fullAddress,
        'items': itemsList,
        'total_amount': _grandTotal,
        'payment_method': _checkoutPayment,
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
        _deliveryNoteCtrl.clear();
        _placingOrder = false;
        _tabIndex = 3; // Orders tab
      });
      await _loadPrefsAndData();
      _toast('Order placed! • ऑर्डर सफलतापूर्वक दर्ज हो गया');
    } catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      _toast('Order error: $e', isError: true);
    }
  }

  Future _confirmCancelOrder(Map ord) async {
    final orderId = _formatOrderId(ord['id']);
    final ok = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Order $orderId?'),
        content: const Text(
          'Kya aap yeh order cancel karna chahte hain?\nक्या आप यह ऑर्डर रद्द करना चाहते हैं?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No • नहीं'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel • रद्द करें'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await _supabase
          .from('deua_orders')
          .update({'status': 'Cancelled'})
          .eq('id', ord['id']);
      await _loadPrefsAndData();
      _toast('Order $orderId cancelled • ऑर्डर रद्द हो गया');
    } catch (e) {
      _toast('Cancel error: $e', isError: true);
    }
  }

  Future _openHelpDialog(Map ord) async {
    final orderId = _formatOrderId(ord['id']);
    final helpMsg =
        'Hello DEUA FRESH, mujhe Order $orderId (₹${ord['total_amount'] ?? 0}) mein madad chahiye.';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Color(0xFF1B7A2B)),
            SizedBox(width: 8),
            Text('Order Help • मदद'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: $orderId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'WhatsApp / Call Support:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              kSupportPhone,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B7A2B),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                helpMsg,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: kSupportPhone));
              Navigator.pop(ctx);
              _toast('Support number copied • नंबर कॉपी हो गया');
            },
            child: const Text('Copy Number'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B7A2B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: helpMsg));
              Navigator.pop(ctx);
              _toast('WhatsApp message copied • मैसेज कॉपी हो गया');
            },
            child: const Text('Copy Message'),
          ),
        ],
      ),
    );
  }

  Future _openWishlistSheet() async {
    final favProds = _products
        .map((p) => Map.from(p as Map))
        .where((p) => _favorites.contains(p['id'].toString()))
        .toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.72,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Items (${favProds.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'पसंदीदा सामान',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: favProds.isEmpty
                  ? const Center(
                      child: Text(
                        'No saved items yet • अभी कोई पसंदीदा सामान नहीं है',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: favProds.length,
                      itemBuilder: (_, i) {
                        final prod = favProds[i];
                        final packs = _packsOf(prod);
                        final p0 = Map.from(packs.first as Map);
                        final price = (p0['price'] as num?)?.toDouble() ?? 0;
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _netImage(
                                prod['image_url']?.toString(),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              (prod['name'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text(
                              '₹${price.toStringAsFixed(0)} • ${p0['label']}',
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B7A2B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () {
                                _addToCart(prod);
                                _toast('Added to cart • कार्ट में जुड़ा');
                              },
                              child: const Text('Add'),
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
  }

  Widget _netImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final clean = (url ?? '').trim();
    if (clean.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.eco, color: Color(0xFF1B7A2B), size: 26),
      );
    }
    return Image.network(
      clean,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.eco, color: Color(0xFF1B7A2B), size: 26),
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

    final cartKey = '${pid}_$pIdx';
    final int inCartQty = _cart.containsKey(cartKey)
        ? ((Map.from(_cart[cartKey] as Map)['qty'] as num?)?.toInt() ?? 0)
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _netImage(
                  prod['image_url']?.toString(),
                  fit: BoxFit.cover,
                ),
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
                    onTap: () => _toggleFavorite(pid),
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
                  child: Container(
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
                if (packs.length > 1)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: PopupMenuButton(
                      onSelected: (val) {
                        final parsed = int.tryParse(val.toString()) ?? 0;
                        setState(() => _selectedPackIndex[pid] = parsed);
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
                        width: 26,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x20000000),
                              blurRadius: 3,
                            ),
                          ],
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
                if (inCartQty > 0)
                  Container(
                    height: 33,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B7A2B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _changeCartQty(cartKey, -1),
                          child: const SizedBox(
                            width: 34,
                            height: 33,
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        Text(
                          '$inCartQty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                        InkWell(
                          onTap: () => _changeCartQty(cartKey, 1),
                          child: const SizedBox(
                            width: 34,
                            height: 33,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 33,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inStock
                            ? const Color(0xFF1B7A2B)
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: inStock ? () => _addToCart(prod) : null,
                      child: Text(
                        inStock ? 'Add • जोड़ें' : 'Out of Stock',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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

  Widget _buildUpiQrCard() {
    final amountStr = _grandTotal.toStringAsFixed(2);
    final upiUri =
        'upi://pay?pa=$kUpiId&pn=${Uri.encodeComponent(kUpiName)}&am=$amountStr&cu=INR&tn=${Uri.encodeComponent('DEUA FRESH Order')}';
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=280x280&ecc=H&margin=8&data=${Uri.encodeComponent(upiUri)}';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        children: [
          Text(
            'Scan & Pay ₹${_grandTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B7A2B),
            ),
          ),
          const Text(
            'PhonePe, Google Pay या Paytm से स्कैन करें',
            style: TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  qrUrl,
                  width: 196,
                  height: 196,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      width: 196,
                      height: 196,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B7A2B),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 196,
                    height: 196,
                    child: Center(
                      child: Text(
                        'QR load nahi hua.\nNeeche UPI ID copy karein.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
                // Center DF Brand Badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B7A2B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x28000000),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'DF',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: Color(0xFF1B7A2B),
                ),
                const SizedBox(width: 6),
                const Text(
                  kUpiId,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: kUpiId));
                    _toast('UPI ID copied • यूपीआई आईडी कॉपी हो गई');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Copy',
                      style: TextStyle(
                        color: Color(0xFF1B7A2B),
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '$kUpiName • Payment karne ke baad "Place Order" dabayein',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  List _effectiveBanners() {
    String fallbackFruitImg = '';
    String fallbackGroceryImg = '';
    for (final c in _categories) {
      final m = Map.from(c as Map);
      final url = (m['image_url'] ?? '').toString().trim();
      final nm = (m['name'] ?? '').toString().toLowerCase();
      if (url.isNotEmpty) {
        if (fallbackFruitImg.isEmpty) fallbackFruitImg = url;
        if (nm.contains('fruit') || nm.contains('veg')) fallbackFruitImg = url;
        if (nm.contains('masala') || nm.contains('kirana') || nm.contains('dry')) {
          fallbackGroceryImg = url;
        }
      }
    }
    if (fallbackGroceryImg.isEmpty) fallbackGroceryImg = fallbackFruitImg;

    if (_banners.isNotEmpty) {
      return _banners.map((b) {
        final m = Map.from(b as Map);
        return {
          'tagline': (m['tagline'] ?? 'Super Saver Deals Are Live!').toString(),
          'highlight': (m['highlight'] ?? '20% OFF').toString(),
          'subtitle': (m['subtitle'] ?? 'on fruits & veggies.').toString(),
          'hindi_subtitle':
              (m['hindi_subtitle'] ?? 'ताज़े फल और सब्ज़ियां').toString(),
          'delivery_badge': (m['delivery_badge'] ?? '30 MINUTES!').toString(),
          'cta_text': (m['cta_text'] ?? 'ORDER NOW').toString(),
          'cta_hindi': (m['cta_hindi'] ?? 'अभी ऑर्डर करें').toString(),
          'badge_text': (m['badge_text'] ?? '20% Off').toString(),
          'image_url': (m['image_url'] ?? '').toString().trim().isNotEmpty
              ? m['image_url'].toString()
              : fallbackFruitImg,
        };
      }).toList();
    }

    return [
      {
        'tagline': 'Super Saver Deals Are Live!',
        'highlight': '20% OFF',
        'subtitle': 'on fruits & veggies.',
        'hindi_subtitle': 'ताज़े फल और सब्ज़ियां',
        'delivery_badge': '30 MINUTES!',
        'cta_text': 'ORDER NOW',
        'cta_hindi': 'अभी ऑर्डर करें',
        'badge_text': '20% Off',
        'image_url': fallbackFruitImg,
      },
      {
        'tagline': 'Daily Kirana & Masala Deals!',
        'highlight': '25% OFF',
        'subtitle': 'on rashan & spices.',
        'hindi_subtitle': 'राशन, दाल और मसाले',
        'delivery_badge': '30 MINUTES!',
        'cta_text': 'SHOP NOW',
        'cta_hindi': 'अभी खरीदें',
        'badge_text': '25% Off',
        'image_url': fallbackGroceryImg,
      },
    ];
  }

  Widget _buildOfferBannerCard(Map b) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E6B24), Color(0xFF289738), Color(0xFF56B847)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261B7A2B),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  b['tagline'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  runSpacing: 2,
                  children: [
                    const Text(
                      'Up to',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        b['highlight'].toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  b['subtitle'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  b['hindi_subtitle'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDCEDC8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'DELIVERED IN ',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        b['delivery_badge'].toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(() {
                    _selectedCatId = 'all';
                    _selectedSubCatId = 'all';
                    _tabIndex = 1;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${b['cta_text']} • ${b['cta_hindi']}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'DISCOUNT',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          b['badge_text'].toString(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B7A2B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _netImage(
                    b['image_url']?.toString(),
                    width: 96,
                    height: 88,
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
    final banners = _effectiveBanners();
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
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEUA FRESH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            locationLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Delivering fresh in 30 mins • ताज़ा व तेज़ डिलीवरी',
                            style: TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _openWishlistSheet,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _favorites.isNotEmpty
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _favorites.isNotEmpty
                                  ? Colors.red
                                  : Colors.black54,
                              size: 20,
                            ),
                          ),
                          if (_favorites.isNotEmpty)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5534B),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${_favorites.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                      _selectedCatId = 'all';
                      _selectedSubCatId = 'all';
                      _showCatSearch = true;
                      _tabIndex = 1;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for items... • सामान खोजें',
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

          const SizedBox(height: 14),

          SizedBox(
            height: 174,
            child: PageView.builder(
              controller: _bannerCtrl,
              itemCount: banners.length,
              onPageChanged: (idx) => setState(() => _bannerPage = idx),
              itemBuilder: (_, i) =>
                  _buildOfferBannerCard(Map.from(banners[i] as Map)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (idx) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerPage == idx ? 10 : 7,
                height: _bannerPage == idx ? 10 : 7,
                decoration: BoxDecoration(
                  color: _bannerPage == idx
                      ? const Color(0xFF1B7A2B)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop by Category',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'सभी श्रेणियां',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => setState(() {
                    _selectedCatId = 'all';
                    _selectedSubCatId = 'all';
                    _tabIndex = 1;
                  }),
                  child: const Text(
                    'View All ->',
                    style: TextStyle(
                      color: Color(0xFF1B7A2B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
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
              final eng = (cat['name'] ?? '').toString();
              final hindi = (cat['hindi_name'] ?? '').toString();

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
                        eng.isNotEmpty ? eng : hindi,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (hindi.isNotEmpty && eng.isNotEmpty)
                        Text(
                          hindi,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Hot Deals",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'लोकप्रिय सामान और ऑफ़र',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => setState(() {
                    _selectedCatId = 'all';
                    _selectedSubCatId = 'all';
                    _tabIndex = 1;
                  }),
                  child: const Text(
                    'View All ->',
                    style: TextStyle(
                      color: Color(0xFF1B7A2B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
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

    String headerEng = 'All Categories';
    String headerHindi = 'सभी श्रेणियां';
    for (final c in _categories) {
      final m = Map.from(c as Map);
      if (m['id'].toString() == _selectedCatId) {
        headerEng = (m['name'] ?? 'Categories').toString();
        headerHindi = (m['hindi_name'] ?? '').toString();
        break;
      }
    }

    final activeSubCats = _selectedCatId == 'all'
        ? []
        : _subCategories
            .map((s) => Map.from(s as Map))
            .where((s) =>
                (s['main_category_id'] ?? '').toString() == _selectedCatId)
            .toList();

    final catProducts = _products
        .map((p) => Map.from(p as Map))
        .where((p) {
          final matchesCat = _selectedCatId == 'all' ||
              (p['main_category_id'] ?? '').toString() == _selectedCatId;
          final matchesSubCat = _selectedSubCatId == 'all' ||
              activeSubCats.isEmpty ||
              (p['sub_category_id'] ?? '').toString() == _selectedSubCatId;
          final matchesSearch =
              q.isEmpty || (p['name'] ?? '').toString().toLowerCase().contains(q);
          return matchesCat && matchesSubCat && matchesSearch;
        })
        .toList();

    final firstCatImg = _categories.isNotEmpty
        ? Map.from(_categories.first as Map)['image_url']?.toString()
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerEng,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        if (headerHindi.isNotEmpty)
                          Text(
                            headerHindi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showCatSearch ? Icons.close : Icons.search,
                      color: const Color(0xFF1B7A2B),
                      size: 24,
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
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search items... • सामान खोजें',
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
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Container(
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: _categories.length + 1,
                    itemBuilder: (_, i) {
                      final isAll = i == 0;
                      final cat = isAll ? {} : Map.from(_categories[i - 1] as Map);
                      final cid = isAll ? 'all' : cat['id'].toString();
                      final sel = cid == _selectedCatId;
                      final eng = isAll ? 'All' : (cat['name'] ?? '').toString();
                      final hindi =
                          isAll ? 'सभी' : (cat['hindi_name'] ?? '').toString();
                      final img = isAll
                          ? firstCatImg
                          : cat['image_url']?.toString();
                      final count = isAll
                          ? _products.length
                          : _products
                              .where((p) =>
                                  (Map.from(p as Map)['main_category_id'] ?? '')
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
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFE8F5E9) : Colors.white,
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
                                  child: _netImage(img, width: 44, height: 44),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                eng.isNotEmpty ? eng : hindi,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight:
                                      sel ? FontWeight.w800 : FontWeight.w700,
                                  color: sel
                                      ? const Color(0xFF1B7A2B)
                                      : Colors.black87,
                                  height: 1.15,
                                ),
                              ),
                              if (hindi.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  hindi,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? Colors.white
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: sel
                                        ? const Color(0xFF1B7A2B)
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
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
              ),
              Expanded(
                child: Column(
                  children: [
                    if (activeSubCats.isNotEmpty)
                      Container(
                        height: 40,
                        color: const Color(0xFFF6F8F6),
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: const Text('All • सभी'),
                                selected: _selectedSubCatId == 'all',
                                selectedColor: const Color(0xFF1B7A2B),
                                labelStyle: TextStyle(
                                  color: _selectedSubCatId == 'all'
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) =>
                                    setState(() => _selectedSubCatId = 'all'),
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _selectedSubCatId = sid),
                                ),
                              );
                            }),
                          ],
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
                                    child: Text(
                                      'No items in this category\nइस श्रेणी में अभी सामान नहीं है',
                                      textAlign: TextAlign.center,
                                    ),
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
                                itemBuilder: (_, i) =>
                                    _buildProductCard(catProducts[i]),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartTab() {
    if (_cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Color(0xFF1B7A2B),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Cart is Empty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'आपका कार्ट खाली है, खरीदारी शुरू करें',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7A2B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => setState(() => _tabIndex = 1),
                child: const Text(
                  'Shop Now • अभी खरीदें',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Cart ($_cartCount items)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'आपका कार्ट और कुल बिल',
                  style: TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
              ],
            ),
            Text(
              'कुल ₹${_grandTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B7A2B),
              ),
            ),
          ],
        ),

        if (_cartSavings > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.savings_outlined,
                  color: Color(0xFF1B7A2B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aapki Bachat: ₹${_cartSavings.toStringAsFixed(0)} • आपने ₹${_cartSavings.toStringAsFixed(0)} बचाए!',
                    style: const TextStyle(
                      color: Color(0xFF1B7A2B),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),

        ..._cart.entries.map((entry) {
          final key = entry.key.toString();
          final item = Map.from(entry.value as Map);
          final qty = (item['qty'] as num?)?.toInt() ?? 1;
          final price = (item['price'] as num?)?.toDouble() ?? 0;
          final mrp = (item['mrp'] as num?)?.toDouble() ?? price;

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _netImage(
                      item['image_url']?.toString(),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['name']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item['pack']}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '₹${(price * qty).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B7A2B),
                              ),
                            ),
                            if (mrp > price) ...[
                              const SizedBox(width: 6),
                              Text(
                                '₹${(mrp * qty).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black45,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B7A2B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _changeCartQty(key, -1),
                          child: const SizedBox(
                            width: 30,
                            height: 32,
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        InkWell(
                          onTap: () => _changeCartQty(key, 1),
                          child: const SizedBox(
                            width: 30,
                            height: 32,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        Card(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 4, bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill Summary • बिल विवरण',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items Total • सामान का कुल'),
                    Text(
                      '₹${_cartTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Charge • डिलीवरी चार्ज'),
                    Text(
                      _deliveryFee <= 0
                          ? 'FREE'
                          : '₹${_deliveryFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _deliveryFee <= 0
                            ? const Color(0xFF1B7A2B)
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total • कुल देय राशि',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '₹${_grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B7A2B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Details',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'डिलीवरी की जानकारी',
                  style: TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _profileNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name • आपका नाम',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _profilePhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone • मोबाइल नंबर',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _profilePinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'PIN Code • पिन कोड',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _profileAddrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address • पूरा पता',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _deliveryNoteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Landmark / Delivery Note (Optional)',
                    hintText: 'जैसे: मंदिर के पास, आने से पहले कॉल करें',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: _checkoutPayment,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method • भुगतान का तरीका',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'COD',
                      child: Text('Cash on Delivery (COD)'),
                    ),
                    DropdownMenuItem(
                      value: 'UPI',
                      child: Text('UPI (QR Scan / Online)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _checkoutPayment = v.toString());
                    }
                  },
                ),
                if (_checkoutPayment == 'UPI') _buildUpiQrCard(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B7A2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _placingOrder ? null : _placeOrderFromCart,
                    child: Text(
                      _placingOrder
                          ? 'Placing Order... • ऑर्डर भेजा जा रहा है'
                          : 'Place Order (₹${_grandTotal.toStringAsFixed(0)}) • ऑर्डर करें',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusBar(String status) {
    final isCancelled = status.toLowerCase().contains('cancel');
    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Order Cancelled • ऑर्डर रद्द किया गया',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );
    }

    final step = _statusStepIndex(status);
    const labels = ['Placed', 'Packed', 'On Way', 'Delivered'];

    return Row(
      children: List.generate(4, (idx) {
        final done = idx <= step;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: idx == 0
                          ? Colors.transparent
                          : (done
                              ? const Color(0xFF1B7A2B)
                              : Colors.grey.shade300),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color:
                          done ? const Color(0xFF1B7A2B) : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.circle,
                      size: done ? 11 : 6,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: idx == 3
                          ? Colors.transparent
                          : (idx < step
                              ? const Color(0xFF1B7A2B)
                              : Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                labels[idx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                  color: done ? const Color(0xFF1B7A2B) : Colors.black45,
                ),
              ),
            ],
          ),
        );
      }),
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
                Center(
                  child: Text(
                    'No orders yet\nअभी कोई ऑर्डर नहीं मिला है',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              itemBuilder: (_, i) {
                final ord = Map.from(_orders[i] as Map);
                final orderId = _formatOrderId(ord['id']);
                final dateStr = _formatDateTime(ord['created_at']);
                final status = (ord['status'] ?? 'Pending').toString();
                final isPending = status.toLowerCase() == 'pending';
                final total = ord['total_amount'] ?? 0;
                final items =
                    ord['items'] is List ? List.from(ord['items'] as List) : [];

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order $orderId',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                  ),
                                ),
                                if (dateStr.isNotEmpty)
                                  Text(
                                    '$dateStr • ${ord['payment_method'] ?? 'COD'}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              '₹$total',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16.5,
                                color: Color(0xFF1B7A2B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildOrderStatusBar(status),
                        const Divider(height: 18),
                        ...items.map((rawIt) {
                          final it = Map.from(rawIt as Map);
                          final qty = (it['qty'] as num?)?.toInt() ?? 1;
                          final price = (it['price'] as num?)?.toDouble() ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _netImage(
                                    it['image_url']?.toString(),
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (it['name'] ?? '').toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      Text(
                                        '${it['pack'] ?? ''} × $qty',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${(price * qty).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1B7A2B),
                                  side: const BorderSide(
                                    color: Color(0xFF1B7A2B),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () => _reorderItems(ord),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text(
                                  'Re-order',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => _openHelpDialog(ord),
                              icon: const Icon(
                                Icons.support_agent,
                                size: 16,
                                color: Color(0xFF1B7A2B),
                              ),
                              label: const Text(
                                'Help',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (isPending) ...[
                              const SizedBox(width: 6),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () => _confirmCancelOrder(ord),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'ग्राहक की जानकारी',
                  style: TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _profileNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name • नाम',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _profilePhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone • मोबाइल नंबर',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _profileAddrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address • पता',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _profilePinCtrl,
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
                      onPressed: () => _checkPincode(_profilePinCtrl.text),
                      child: const Text('Check PIN'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _saveProfileDetails(
                      name: _profileNameCtrl.text,
                      phone: _profilePhoneCtrl.text,
                      address: _profileAddrCtrl.text,
                      pincode: _profilePinCtrl.text,
                    ),
                    child: const Text('Save Profile • सेव करें'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: Text('Saved Wishlist (${_favorites.length})'),
            subtitle: const Text('पसंदीदा सामान देखें'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openWishlistSheet,
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
          currentBody = _buildCartTab();
          break;
        case 3:
          currentBody = _buildOrdersTab();
          break;
        default:
          currentBody = _buildProfileTab();
      }
    }

    return Scaffold(
      body: SafeArea(child: currentBody),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        indicatorColor: const Color(0xFFE8F5E9),
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _cartCount > 0,
              label: Text('$_cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _cartCount > 0,
              label: Text('$_cartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
