import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../utils/localization.dart';
import '../viewmodels/cart_vm.dart';
import '../viewmodels/language_vm.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  const ProductDetailScreen({Key? key, required this.product})
      : super(key: key);

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late int _qty;
  int _currentStock = 0;
  bool _isStockLoaded = false;
  final TextEditingController _qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _qty = 1;
    _qtyController.text = _qty.toString();
    _loadStock();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _loadStock() async {
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('stock')
          .eq('id', widget.product.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _currentStock = data['stock'] as int? ?? 0;
          _isStockLoaded = true;

          // Eğer mevcut miktar stoktan fazlaysa, stok kadar ayarla
          if (_qty > _currentStock && _currentStock > 0) {
            _qty = _currentStock;
            _qtyController.text = _qty.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStockLoaded = true;
          _currentStock = 0;
        });
      }
    }
  }

  void _updateQty(int newQty) {
    int validQty = newQty.clamp(1, _currentStock > 0 ? _currentStock : 1);

    setState(() {
      _qty = validQty;
      _qtyController.text = validQty.toString();
    });
  }

  void _inc() {
    if (_qty < _currentStock) {
      _updateQty(_qty + 1);
    }
  }

  void _dec() {
    if (_qty > 1) {
      _updateQty(_qty - 1);
    }
  }

  void _onQtyTextChanged(String value) {
    if (value.isEmpty) return;

    final newQty = int.tryParse(value);
    if (newQty != null) {
      _updateQty(newQty);
    }
  }

  void showLanguageMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        position.dx + button.size.width,
        0,
      ),
      items: const [
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'tr', child: Text('Türkçe')),
        PopupMenuItem(value: 'fr', child: Text('Français')),
        PopupMenuItem(value: 'it', child: Text('Italiano')),
        PopupMenuItem(value: 'de', child: Text('Deutsch')),
      ],
    ).then((selected) {
      if (selected != null) {
        ref.read(languageProvider.notifier).state = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Modern color scheme
    final primaryColor = const Color(0xFF1A237E);
    final accentColor = const Color(0xFF3F51B5);
    final backgroundColor = const Color(0xFAFAFA);

    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: screenHeight * 0.065,
        actions: [
          IconButton(
            icon: Icon(
              Icons.language,
              color: Colors.white,
              size: (screenWidth * 0.055).clamp(18.0, 24.0),
            ),
            onPressed: () => showLanguageMenu(context),
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.white,
              size: (screenWidth * 0.055).clamp(18.0, 24.0),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(t(ref, 'logoutConfirmationTitle')),
                  content: Text(t(ref, 'logoutConfirmationMessage')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        t(ref, 'cancel'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Supabase.instance.client.auth.signOut();
                        Navigator.pushReplacementNamed(context, '/auth');
                      },
                      child: Text(
                        t(ref, 'confirm'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.085 + bottomPadding),
        child: FloatingActionButton(
          backgroundColor: Colors.redAccent,
          child: Icon(
            Icons.shopping_cart,
            size: (screenWidth * 0.055).clamp(18.0, 24.0),
          ),
          onPressed: () => Navigator.pushNamed(context, '/CartScreen'),
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: bottomPadding + 8,
        ),
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 56,
            borderRadius: 16,
            blur: 20,
            border: 1,
            linearGradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.35),
                accentColor.withOpacity(0.25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            child: Row(
              children: [
                // Orders Tab - Siparişler
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final currentRoute =
                          ModalRoute.of(context)?.settings.name;
                      if (currentRoute != '/CartScreen') {
                        Navigator.pushReplacementNamed(context, '/CartScreen');
                      }
                    },
                    child: Container(
                      height: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: Colors.black,
                          ),
                          SizedBox(height: 2),
                          Text(
                            t(ref, 'nav_orders'),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: InkWell(
                    onTap: () {
                      final currentRoute =
                          ModalRoute.of(context)?.settings.name;
                      if (currentRoute != '/products') {
                        Navigator.pushReplacementNamed(context, '/products');
                      }
                    },
                    child: Container(
                      height: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag,
                            size: 20,
                            color: Colors.black,
                          ),
                          SizedBox(height: 2),
                          Text(
                            t(ref, 'nav_products'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: InkWell(
                    onTap: () {
                      final currentRoute =
                          ModalRoute.of(context)?.settings.name;
                      if (currentRoute != '/AboutUsScreen') {
                        Navigator.pushReplacementNamed(
                            context, '/AboutUsScreen');
                      }
                    },
                    child: Container(
                      height: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.black,
                          ),
                          SizedBox(height: 2),
                          Text(
                            t(ref, 'nav_about'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: !_isStockLoaded
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      t(ref, 'loadingStock'),
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                color: backgroundColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: size.width * 0.07,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Container(
                        height: size.height * 0.35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.indigo.shade50,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.7),
                              offset: const Offset(-4, -4),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color:
                                  Colors.indigo.shade200.withValues(alpha: 0.6),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: widget.product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.product.imageUrl!,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text(
                                        t(ref, 'loadingImage'),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        t(ref, 'imageLoadError'),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      t(ref, 'noImage'),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      Text(
                        '₺${widget.product.newPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: size.width * 0.08,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      if (widget.product.description != null &&
                          widget.product.description!.isNotEmpty) ...[
                        Text(
                          t(ref, 'productDescription'),
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          widget.product.description!,
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                      ],
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: _currentStock > 0
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentStock > 0
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t(ref, 'stockStatus'),
                              style: TextStyle(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  _currentStock > 0
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _currentStock > 0
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _currentStock > 0
                                      ? '${t(ref, 'inStock')}: $_currentStock'
                                      : t(ref, 'outOfStock'),
                                  style: TextStyle(
                                    fontSize: size.width * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: _currentStock > 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      if (_currentStock > 0) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                            vertical: size.height * 0.02,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                t(ref, 'selectQuantity'),
                                style: TextStyle(
                                  fontSize: size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: size.height * 0.02),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _qty > 1
                                          ? primaryColor
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _qty > 1
                                          ? [
                                              BoxShadow(
                                                color: primaryColor
                                                    .withOpacity(0.3),
                                                spreadRadius: 1,
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: IconButton(
                                      onPressed: _qty > 1 ? _dec : null,
                                      icon: Icon(
                                        Icons.remove,
                                        color: _qty > 1
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        size: size.width * 0.06,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: size.width * 0.06),
                                  Container(
                                    width: size.width * 0.25,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: primaryColor, width: 2),
                                    ),
                                    child: TextField(
                                      controller: _qtyController,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      style: TextStyle(
                                        fontSize: size.width * 0.08,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 4),
                                        hintText: t(ref, 'quantity'),
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: size.width * 0.04,
                                        ),
                                      ),
                                      onChanged: _onQtyTextChanged,
                                      onSubmitted: (value) {
                                        if (value.isEmpty) {
                                          _updateQty(1);
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(width: size.width * 0.06),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _qty < _currentStock
                                          ? primaryColor
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _qty < _currentStock
                                          ? [
                                              BoxShadow(
                                                color: primaryColor
                                                    .withOpacity(0.3),
                                                spreadRadius: 1,
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: IconButton(
                                      onPressed:
                                          _qty < _currentStock ? _inc : null,
                                      icon: Icon(
                                        Icons.add,
                                        color: _qty < _currentStock
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        size: size.width * 0.06,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: size.height * 0.02),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.04,
                                  vertical: size.height * 0.01,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${t(ref, 'totalPrice')}: ₺${(widget.product.newPrice * _qty).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: size.width * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                      ],
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.018),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            backgroundColor: _currentStock > 0
                                ? primaryColor
                                : Colors.grey.shade400,
                            elevation: _currentStock > 0 ? 4 : 0,
                            shadowColor: _currentStock > 0
                                ? primaryColor.withOpacity(0.3)
                                : Colors.transparent,
                          ),
                          onPressed: _currentStock > 0
                              ? () {
                                  for (var i = 0; i < _qty; i++) {
                                    cart.add(widget.product);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${widget.product.name} ×$_qty ${t(ref, 'addedToCart')}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      action: SnackBarAction(
                                        label: t(ref, 'viewCart'),
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.pushNamed(
                                              context, '/CartScreen');
                                        },
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _currentStock > 0
                                    ? Icons.add_shopping_cart
                                    : Icons.block,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _currentStock > 0
                                    ? '${t(ref, 'addToCart')} (₺${(widget.product.newPrice * _qty).toStringAsFixed(2)})'
                                    : t(ref, 'outOfStock'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: size.width * 0.045,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.15 + bottomPadding),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
