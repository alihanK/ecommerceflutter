import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/localization.dart';
import '../viewmodels/cart_vm.dart';
import '../viewmodels/language_vm.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({Key? key}) : super(key: key);

  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t(ref, 'deleteConfirmationTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(t(ref, 'deleteConfirmationContent')),
        actions: [
          TextButton(
            child: Text(
              t(ref, 'cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              t(ref, 'delete'),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  void _showQuantityEditDialog(BuildContext context, WidgetRef ref,
      dynamic product, int currentQuantity) {
    final TextEditingController controller =
        TextEditingController(text: currentQuantity.toString());
    final cartNotifier = ref.read(cartProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t(ref, 'editQuantity'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${t(ref, 'availableStock')}: ${product.stock}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: t(ref, 'quantity'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: '/ ${product.stock}',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue > product.stock) {
                    controller.text = product.stock.toString();
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              t(ref, 'cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              t(ref, 'confirm'),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () {
              final newQuantity = int.tryParse(controller.text) ?? 1;
              final validQuantity = newQuantity.clamp(1, product.stock);

              cartNotifier.removeAll(product);

              for (int i = 0; i < validQuantity; i++) {
                cartNotifier.add(product);
              }

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void showLanguageMenu(BuildContext context, WidgetRef ref) {
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
      items: [
        PopupMenuItem(value: 'en', child: Text(t(ref, 'english'))),
        PopupMenuItem(value: 'tr', child: Text(t(ref, 'turkish'))),
        PopupMenuItem(value: 'fr', child: Text(t(ref, 'french'))),
        PopupMenuItem(value: 'it', child: Text(t(ref, 'italian'))),
        PopupMenuItem(value: 'de', child: Text(t(ref, 'german'))),
      ],
    ).then((selected) {
      if (selected != null) {
        ref.read(languageProvider.notifier).state = selected;
      }
    });
  }

  void _updateQuantity(WidgetRef ref, dynamic product, int newQuantity) {
    final cartNotifier = ref.read(cartProvider.notifier);
    // Önce bu üründen tüm adedleri çıkar
    cartNotifier.removeAll(product);
    // Sonra yeni miktarı ekle
    for (int i = 0; i < newQuantity; i++) {
      cartNotifier.add(product);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/auth');
      });
      return const Scaffold();
    }

    final cartList = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final primaryColor = const Color(0xFF1A237E);
    final accentColor = const Color(0xFF3F51B5);
    final backgroundColor = Colors.grey.shade200;

    final qtyMap = <int, int>{};
    for (var p in cartList) {
      qtyMap[p.id] = (qtyMap[p.id] ?? 0) + 1;
    }

    final items = qtyMap.entries
        .map(
            (e) => MapEntry(cartList.firstWhere((p) => p.id == e.key), e.value))
        .toList();

    final total =
        items.fold<double>(0, (sum, e) => sum + e.key.newPrice * e.value);

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
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
            onPressed: () => showLanguageMenu(context, ref),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                        Navigator.pushReplacementNamed(context, '/login');
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
      body: SafeArea(
        child: Container(
          color: backgroundColor,
          child: Column(
            children: [
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            size: screenWidth * 0.15,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Text(
                          t(ref, 'emptyCart'),
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                            fontSize: (screenWidth * 0.045).clamp(16.0, 18.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.04,
                      screenHeight * 0.02,
                      screenWidth * 0.04,
                      screenHeight * 0.02,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final p = items[index].key;
                      final q = items[index].value;
                      return Container(
                        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                        child: GlassmorphicContainer(
                          width: screenWidth * 0.92,
                          height: screenHeight * 0.14,
                          borderRadius: 20,
                          blur: 20,
                          border: 1,
                          linearGradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderGradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            child: Row(
                              children: [
                                Container(
                                  width: screenWidth * 0.16,
                                  height: screenWidth * 0.16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: p.imageUrl != null
                                        ? Image.network(
                                            p.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              color: Colors.grey.shade200,
                                              child: Icon(
                                                Icons.shopping_bag_outlined,
                                                color: Colors.grey.shade400,
                                                size: screenWidth * 0.07,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.shopping_bag_outlined,
                                              color: Colors.grey.shade400,
                                              size: screenWidth * 0.07,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        p.name,
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: (screenWidth * 0.04)
                                              .clamp(14.0, 16.0),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: screenHeight * 0.004),
                                      Text(
                                        '${t(ref, 'availableStock')}: ${p.stock}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: (screenWidth * 0.028)
                                              .clamp(10.0, 12.0),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.004),
                                      Row(
                                        children: [
                                          Text(
                                            '₺${(p.newPrice * q).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: (screenWidth * 0.042)
                                                  .clamp(15.0, 17.0),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.02),
                                          Text(
                                            '(₺${p.newPrice.toStringAsFixed(2)} / ${t(ref, 'unit')})',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: (screenWidth * 0.028)
                                                  .clamp(10.0, 12.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: q > 1
                                                ? () {
                                                    _updateQuantity(
                                                        ref, p, q - 1);
                                                  }
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Container(
                                              width: screenWidth * 0.08,
                                              height: screenWidth * 0.08,
                                              decoration: BoxDecoration(
                                                color: q > 1
                                                    ? primaryColor
                                                        .withOpacity(0.1)
                                                    : Colors.grey
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: screenWidth * 0.04,
                                                color: q > 1
                                                    ? primaryColor
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              _showQuantityEditDialog(
                                                  context, ref, p, q);
                                            },
                                            child: Container(
                                              width: screenWidth * 0.12,
                                              height: screenWidth * 0.08,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  q.toString(),
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize:
                                                        (screenWidth * 0.035)
                                                            .clamp(14.0, 16.0),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: q < p.stock
                                                ? () {
                                                    _updateQuantity(
                                                        ref, p, q + 1);
                                                  }
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Container(
                                              width: screenWidth * 0.08,
                                              height: screenWidth * 0.08,
                                              decoration: BoxDecoration(
                                                color: q < p.stock
                                                    ? primaryColor
                                                        .withOpacity(0.1)
                                                    : Colors.grey
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: screenWidth * 0.04,
                                                color: q < p.stock
                                                    ? primaryColor
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Container(
                                      width: screenWidth * 0.1,
                                      height: screenWidth * 0.1,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.redAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: (screenWidth * 0.05)
                                              .clamp(18.0, 22.0),
                                        ),
                                        onPressed: () async {
                                          final confirmed =
                                              await _showDeleteConfirmationDialog(
                                                  context, ref);
                                          if (confirmed == true) {
                                            cartNotifier.removeAll(p);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.04,
                  screenHeight * 0.02,
                  screenWidth * 0.04,
                  screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.05),
                            accentColor.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t(ref, 'total'),
                            style: TextStyle(
                              fontSize: (screenWidth * 0.05).clamp(16.0, 20.0),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '₺${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: (screenWidth * 0.055).clamp(18.0, 22.0),
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    if (items.isNotEmpty)
                      Container(
                        height: screenHeight * 0.065,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: primaryColor.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/OrderConfirmationScreen',
                              arguments: items,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_checkout,
                                size: (screenWidth * 0.05).clamp(18.0, 22.0),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Text(
                                t(ref, 'orderConfirmation'),
                                style: TextStyle(
                                  fontSize:
                                      (screenWidth * 0.045).clamp(16.0, 18.0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.08 + bottomPadding),
                  ],
                ),
              ),
            ],
          ),
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
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 20,
                          color: Colors.black87,
                        ),
                        SizedBox(height: 2),
                        Text(
                          t(ref, 'nav_orders'),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
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
                            size: 18,
                            color: Colors.black,
                          ),
                          SizedBox(height: 2),
                          Text(
                            t(ref, 'nav_products'),
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
    );
  }
}
