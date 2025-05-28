import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/localization.dart';
import '../viewmodels/language_vm.dart';

class AboutUsScreen extends ConsumerWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final primaryColor = const Color(0xFF1A237E);
    final accentColor = const Color(0xFF3F51B5);
    final backgroundColor = const Color(0xFAFAFA);

    final aboutUsText = t(ref, 'aboutUsShortText');

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: screenHeight * 0.065,
        title: Text(
          "EcommerceApp",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                      child: Text(
                        t(ref, 'cancel'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Supabase.instance.client.auth.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        t(ref, 'confirm'),
                        style: TextStyle(color: primaryColor),
                      ),
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info,
                            size: 20,
                            color: primaryColor,
                          ),
                          SizedBox(height: 2),
                          Text(
                            t(ref, 'nav_about'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  t(ref, 'appName'),
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                Container(
                  width: screenWidth * 0.92,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenHeight * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GlassmorphicContainer(
                        width: double.infinity,
                        height: screenHeight * 0.4,
                        borderRadius: 20,
                        blur: 15,
                        border: 1.5,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withOpacity(0.1),
                            accentColor.withOpacity(0.05),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [primaryColor, accentColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(
                                  Rect.fromLTWH(
                                      0, 0, bounds.width, bounds.height),
                                ),
                                child: Text(
                                  aboutUsText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              Container(
                                width: screenWidth * 0.65,
                                height: screenHeight * 0.18,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: accentColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: .1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Image.asset(
                                  'assets/images/bg_cart.jpg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              ref,
                              Icons.security,
                              t(ref, 'SECURE'),
                              t(ref, 'SHOPPING'),
                              primaryColor,
                              screenWidth,
                              screenHeight,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              ref,
                              Icons.local_shipping,
                              t(ref, 'FAST'),
                              t(ref, 'DELIVERY'),
                              accentColor,
                              screenWidth,
                              screenHeight,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              ref,
                              Icons.support_agent,
                              t(ref, 'SUPPORT'),
                              t(ref, '7/24'),
                              Colors.green.shade600,
                              screenWidth,
                              screenHeight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.12 + bottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.02,
        horizontal: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: screenWidth * 0.06,
            color: color,
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: screenWidth * 0.025,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
