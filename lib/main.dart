import 'package:flutter/material.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7A2B),
          primary: const Color(0xFF1B7A2B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const FreshFruitsScreen(),
    );
  }
}

class SubCategory {
  final String id;
  final String name;
  final int count;
  final String emoji;
  final Color bgColor;

  const SubCategory({
    required this.id,
    required this.name,
    required this.count,
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
  final String name;
  final String categoryId;
  final int discountPercent;
  final String imageUrl;
  final String fallbackEmoji;
  final Color cardBg;
  final List<PackOption> packs;

  const ProductItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.discountPercent,
    required this.imageUrl,
    required this.fallbackEmoji,
    required this.cardBg,
    required this.packs,
  });
}

class FreshFruitsScreen extends StatefulWidget {
  const FreshFruitsScreen({super.key});

  @override
  State<FreshFruitsScreen> createState() => _FreshFruitsScreenState();
}

class _FreshFruitsScreenState extends State<FreshFruitsScreen> {
  String _selectedCategoryId = 'citrus';
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _wishlist = {};
  final Map<String, int> _selectedPackIndex = {};
  final Map<String, int> _cartQuantities = {};

  final List<SubCategory> _categories = const [
    SubCategory(
      id: 'all',
      name: 'All',
      count: 32,
      emoji: '🧺',
      bgColor: Color(0xFFFFF3E0),
    ),
    SubCategory(
      id: 'apples',
      name: 'Apples & Pomegranate',
      count: 9,
      emoji: '🍎',
      bgColor: Color(0xFFFFEBEE),
    ),
    SubCategory(
      id: 'banana',
      name: 'Banana, Sapota & ...',
      count: 4,
      emoji: '🍌',
      bgColor: Color(0xFFFFFDE7),
    ),
    SubCategory(
      id: 'citrus',
      name: 'Kiwi, Melon, Citrus Fruit',
      count: 11,
      emoji: '🍊',
      bgColor: Color(0xFFE8F5E9),
    ),
    SubCategory(
      id: 'seasonal',
      name: 'Seasonal Fruits',
      count: 8,
      emoji: '🍇',
      bgColor: Color(0xFFF3E5F5),
    ),
  ];

  final List<ProductItem> _products = const [
    ProductItem(
      id: 'p1',
      name: 'Desi Malta',
      categoryId: 'citrus',
      discountPercent: 20,
      imageUrl: 'https://images.unsplash.com/photo-1547514701-42782101795e?w=400',
      fallbackEmoji: '🍊',
      cardBg: Color(0xFFFFF3E0),
      packs: [
        PackOption(label: '500g', price: 80.00, mrp: 100.00),
        PackOption(label: '1kg', price: 150.00, mrp: 190.00),
      ],
    ),
    ProductItem(
      id: 'p2',
      name: 'Orange',
      categoryId: 'citrus',
      discountPercent: 20,
      imageUrl: 'https://images.unsplash.com/photo-1582979512210-99b6a53386f9?w=400',
      fallbackEmoji: '🍊',
      cardBg: Color(0xFFFFF8E1),
      packs: [
        PackOption(label: '500g', price: 80.00, mrp: 100.00),
        PackOption(label: '1kg', price: 155.00, mrp: 195.00),
      ],
    ),
    ProductItem(
      id: 'p3',
      name: 'Striped Muskmelon (S...',
      categoryId: 'citrus',
      discountPercent: 25,
      imageUrl: 'https://images.unsplash.com/photo-1571575173700-afb9492e6a50?w=400',
      fallbackEmoji: '🍈',
      cardBg: Color(0xFFF1F8E9),
      packs: [
        PackOption(label: '500g', price: 30.00, mrp: 40.00),
        PackOption(label: '1kg', price: 55.00, mrp: 75.00),
      ],
    ),
    ProductItem(
      id: 'p4',
      name: 'Green Kiwi (New Zealand) - 3 pics',
      categoryId: 'citrus',
      discountPercent: 20,
      imageUrl: 'https://images.unsplash.com/photo-1585059895524-72359e06133a?w=400',
      fallbackEmoji: '🥝',
      cardBg: Color(0xFFE8F5E9),
      packs: [
        PackOption(label: '1box', price: 120.00, mrp: 150.00),
      ],
    ),
    ProductItem(
      id: 'p5',
      name: 'Green Kiwi',
      categoryId: 'citrus',
      discountPercent: 0,
      imageUrl: 'https://images.unsplash.com/photo-1618897996318-5a901fa6ca71?w=400',
      fallbackEmoji: '🥝',
      cardBg: Color(0xFFF1F8E9),
      packs: [
        PackOption(label: '1box', price: 110.00, mrp: 130.00),
      ],
    ),
    ProductItem(
      id: 'p6',
      name: 'Green Grapes',
      categoryId: 'seasonal',
      discountPercent: 17,
      imageUrl: 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=400',
      fallbackEmoji: '🍇',
      cardBg: Color(0xFFE8F5E9),
      packs: [
        PackOption(label: '1box', price: 75.00, mrp: 90.00),
        PackOption(label: '500g', price: 50.00, mrp: 60.00),
      ],
    ),
    ProductItem(
      id: 'p7',
      name: 'Royal Gala Apple',
      categoryId: 'apples',
      discountPercent: 15,
      imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400',
      fallbackEmoji: '🍎',
      cardBg: Color(0xFFFFEBEE),
      packs: [
        PackOption(label: '500g', price: 95.00, mrp: 112.00),
        PackOption(label: '1kg', price: 180.00, mrp: 215.00),
      ],
    ),
    ProductItem(
      id: 'p8',
      name: 'Robusta Banana',
      categoryId: 'banana',
      discountPercent: 10,
      imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400',
      fallbackEmoji: '🍌',
      cardBg: Color(0xFFFFFDE7),
      packs: [
        PackOption(label: '6 pcs', price: 36.00, mrp: 40.00),
        PackOption(label: '12 pcs', price: 68.00, mrp: 76.00),
      ],
    ),
  ];

  List<ProductItem> get _filteredProducts {
    return _products.where((item) {
      final matchesCategory = _selectedCategoryId == 'all' ||
          item.categoryId == _selectedCategoryId ||
          (_selectedCategoryId == 'citrus' && item.id == 'p6');
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
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
      final parts = entry.key.split('_');
      final product = _products.firstWhere((p) => p.id == parts[0]);
      final packIdx = int.parse(parts[1]);
      sum += product.packs[packIdx].price * entry.value;
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

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final entries = _cartQuantities.entries.where((e) => e.value > 0).toList();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Basket',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_totalCartItems items',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Cart is empty'),
                    )
                  else
                    ...entries.map((entry) {
                      final parts = entry.key.split('_');
                      final product = _products.firstWhere((p) => p.id == parts[0]);
                      final pack = product.packs[int.parse(parts[1])];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
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
                            const SizedBox(width: 10),
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
                                      child: Icon(Icons.remove, size: 16, color: Colors.white),
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
                                      child: Icon(Icons.add, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B7A2B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: entries.isEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Order Placed! Total: ₹${_totalCartPrice.toStringAsFixed(2)}',
                                  ),
                                  backgroundColor: const Color(0xFF1B7A2B),
                                ),
                              );
                              setState(() {
                                _cartQuantities.clear();
                              });
                            },
                      child: Text(
                        'Proceed to Order • ₹${_totalCartPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              onPressed: () {},
            ),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search fruits...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text(
                'Fresh Fruits',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
        actions: [
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
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sub-Category Sidebar
          Container(
            width: 84,
            color: Colors.white,
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat.id == _selectedCategoryId;
                return InkWell(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: isSelected ? const Color(0xFF1B7A2B) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1B7A2B) : cat.bgColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat.emoji,
                            style: const TextStyle(fontSize: 24),
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
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF1B7A2B) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${cat.count}',
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
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                final cartKey = '${item.id}_$packIdx';
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
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Container(
                                width: double.infinity,
                                color: item.cardBg,
                                child: Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      item.fallbackEmoji,
                                      style: const TextStyle(fontSize: 48),
                                    ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
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

                      // Details + Price + Add Button
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
                                        '₹${currentPack.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          '₹${currentPack.mrp.toStringAsFixed(2)}',
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
                                                borderRadius: BorderRadius.circular(7),
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
                                              borderRadius: BorderRadius.circular(7),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
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
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _totalCartItems > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: InkWell(
                  onTap: _showCartSheet,
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
                              'View Cart',
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
