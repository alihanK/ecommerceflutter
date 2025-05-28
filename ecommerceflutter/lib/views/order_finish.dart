import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../utils/localization.dart';
import '../viewmodels/cart_vm.dart';
import '../viewmodels/language_vm.dart';

class OrderFinishPage extends ConsumerStatefulWidget {
  OrderFinishPage({Key? key}) : super(key: key);

  @override
  ConsumerState<OrderFinishPage> createState() => _OrderFinishPageState();
}

class _OrderFinishPageState extends ConsumerState<OrderFinishPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _processOrderAndNavigate();
    });
  }

  Future<void> _processOrderAndNavigate() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! List<MapEntry<Product, int>>) {
      debugPrint('OrderFinishPage: Geçersiz argüman.');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    final cartItems = args;
    final supabase = Supabase.instance.client;

    for (final entry in cartItems) {
      final product = entry.key;
      final qty = entry.value;
      try {
        final data = await supabase
            .from('products')
            .select('stock')
            .eq('id', product.id)
            .maybeSingle();

        if (data == null) {
          debugPrint('Ürün ID:${product.id} bulunamadı.');
          continue;
        }

        final currentStock = (data['stock'] ?? 0) as int;

        if (currentStock >= qty) {
          final newStock = currentStock - qty;
          if (newStock > 0) {
            await supabase
                .from('products')
                .update({'stock': newStock}).eq('id', product.id);
            debugPrint(
                'Ürün ID:${product.id} stoğu güncellendi: $currentStock -> $newStock');
          } else {
            await supabase.from('products').delete().eq('id', product.id);
            debugPrint('Ürün ID:${product.id} stoğu 0 olduğu için silindi.');
          }
        } else {
          debugPrint(
              'Ürün ID:${product.id} stok yetersiz (mevcut: $currentStock, gerekli: $qty).');
        }
      } catch (e, st) {
        debugPrint('Ürün ID:${product.id} işlenirken hata: $e\n$st');
      }
    }

    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      cartNotifier.clearAll();
      debugPrint('Sepet temizlendi.');
    } catch (e) {
      debugPrint('Sepeti temizlerken hata: $e');
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
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

    if (_isLoading) {
      return Scaffold(
        extendBody: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: primaryColor,
          elevation: 0,
          toolbarHeight: screenHeight * 0.065,
          title: Text(
            t(ref, 'appName'),
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                        child: Text(t(ref, 'cancel')),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await Supabase.instance.client.auth.signOut();
                          Navigator.pushReplacementNamed(context, '/auth');
                        },
                        child: Text(t(ref, 'confirm')),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          color: backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  t(ref, 'processingOrder'),
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: screenHeight * 0.065,
        title: Text(
          t(ref, 'orderConfirmed'),
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                      child: Text(t(ref, 'cancel')),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Supabase.instance.client.auth.signOut();
                        Navigator.pushReplacementNamed(context, '/auth');
                      },
                      child: Text(t(ref, 'confirm')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                primaryColor.withValues(alpha: .35),
                accentColor.withValues(alpha: .25),
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
                // Orders Tab
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final currentRoute =
                          ModalRoute.of(context)?.settings.name;
                      if (currentRoute != '/CartScreen') {
                        Navigator.pushReplacementNamed(context, '/CartScreen');
                      }
                    },
                    child: SizedBox(
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
                    child: SizedBox(
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
        child: Container(
          color: backgroundColor,
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Container(
                  width: screenWidth * 0.5,
                  height: screenWidth * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        accentColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: screenWidth * 0.35,
                      height: screenWidth * 0.35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: screenWidth * 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        t(ref, 'orderConfirmed'),
                        style: TextStyle(
                          fontSize: screenWidth * 0.065,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        t(ref, 'orderSuccessMessage'),
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: primaryColor,
                            size: screenWidth * 0.06,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            t(ref, 'orderInfo'),
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t(ref, 'orderStatus'),
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: screenHeight * 0.008,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              t(ref, 'orderCompleted'),
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t(ref, 'processTime'),
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            DateTime.now().toString().substring(0, 16),
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.06),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/products', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home,
                          size: screenWidth * 0.06,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          t(ref, 'backToHome'),
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
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
