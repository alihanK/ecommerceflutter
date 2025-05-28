import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../utils/localization.dart';
import '../viewmodels/language_vm.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final primaryColor = const Color(0xFF1A237E);
    final accentColor = const Color(0xFF3F51B5);

    final items = ModalRoute.of(context)!.settings.arguments
        as List<MapEntry<Product, int>>;

    final total = items.fold<double>(
      0,
      (sum, e) => sum + e.key.newPrice * e.value,
    );

    Widget buildCard({required Widget child, double? width, double? height}) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    Widget buildOrderItem(MapEntry<Product, int> e) {
      return Container(
        margin: EdgeInsets.symmetric(
          vertical: screenHeight * 0.008,
          horizontal: screenWidth * 0.025,
        ),
        child: buildCard(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: (screenWidth * 0.042).clamp(14.0, 18.0),
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₺${e.key.newPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.038).clamp(12.0, 16.0),
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${t(ref, 'quantity')}: ${e.value}',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.038).clamp(12.0, 16.0),
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.008),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.025,
                      vertical: screenHeight * 0.006,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15), // Biraz daha koyu
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '= ₺${(e.key.newPrice * e.value).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: (screenWidth * 0.04).clamp(13.0, 17.0),
                        color: primaryColor,
                      ),
                    ),
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: (screenWidth * 0.055).clamp(18.0, 24.0),
          ),
          onPressed: () => Navigator.pushReplacementNamed(context, '/products'),
        ),
        title: Text(
          t(ref, 'orderConfirmation'),
          style: TextStyle(
            color: Colors.white,
            fontSize: (screenWidth * 0.045).clamp(16.0, 20.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.language,
              color: Colors.white,
              size: (screenWidth * 0.055).clamp(18.0, 24.0),
            ),
            onPressed: () {
              final RenderBox button = context.findRenderObject() as RenderBox;
              final RenderBox overlay =
                  Overlay.of(context).context.findRenderObject() as RenderBox;
              final Offset position =
                  button.localToGlobal(Offset.zero, ancestor: overlay);
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                    position.dx,
                    position.dy + button.size.height,
                    position.dx + button.size.width,
                    0),
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
            },
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
                            color: Colors.white,
                          ),
                          SizedBox(height: 2),
                          Text(
                            t(ref, 'nav_orders'),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
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
                            color: Colors.white,
                          ),
                          SizedBox(height: 2),
                          Text(
                            t(ref, 'nav_products'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
                            color: Colors.white,
                          ),
                          SizedBox(height: 2),
                          Text(
                            t(ref, 'nav_about'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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
      body: Container(
        color: const Color(0xFFF0F0F0),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: screenWidth * 0.02,
            right: screenWidth * 0.02,
            top: screenHeight * 0.02,
            bottom: screenHeight * 0.15 + bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Section at the top
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                child: buildCard(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t(ref, 'total'),
                          style: TextStyle(
                            fontSize: (screenWidth * 0.05).clamp(18.0, 24.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '₺${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: (screenWidth * 0.048).clamp(16.0, 22.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                child: Text(
                  t(ref, 'orderItems'),
                  style: TextStyle(
                    fontSize: (screenWidth * 0.045).clamp(16.0, 20.0),
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              ...items.map((e) => buildOrderItem(e)).toList(),

              SizedBox(height: screenHeight * 0.03),

              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/OrderFinishScreen',
                      arguments: items,
                    );
                  },
                  child: Text(
                    t(ref, 'confirm'),
                    style: TextStyle(
                      fontSize: (screenWidth * 0.042).clamp(14.0, 18.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
