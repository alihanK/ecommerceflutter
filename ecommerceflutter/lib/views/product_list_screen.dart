import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../utils/localization.dart';
import '../viewmodels/language_vm.dart';
import 'product_detail_screen.dart';

final selectedCategoryProvider = StateProvider<int?>((ref) => null);
final searchProvider = StateProvider<String>((ref) => '');

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((listResult) =>
      listResult.isNotEmpty ? listResult.first : ConnectivityResult.none);
});

final combinedDataProvider = FutureProvider.autoDispose((ref) async {
  final results = await Future.wait([
    SupabaseService().fetchCategories(),
    SupabaseService().fetchProducts(),
  ]);
  return {
    'categories': results[0] as List<Category>,
    'products': results[1] as List<Product>,
  };
});

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late PageController _sliderController;
  int _currentSliderIndex = 0;

  final List<String> _sliderImages = [
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
    'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=800',
    'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=800',
  ];

  final List<String> _sliderRoutes = [
    '/category/1',
    '/category/2',
    '/category/3',
  ];

  @override
  void initState() {
    super.initState();
    _sliderController = PageController();

    Future.delayed(const Duration(seconds: 3), _autoSlide);
  }

  void _autoSlide() {
    if (mounted) {
      final next = (_currentSliderIndex + 1) % _sliderImages.length;
      _sliderController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      Future.delayed(const Duration(seconds: 3), _autoSlide);
    }
  }

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(combinedDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Responsive calculations - more compact
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? screenWidth * 0.28 : screenWidth * 0.38;
    final cardHeight = isTablet ? screenHeight * 0.18 : screenHeight * 0.2;

    final combinedDataAsync = ref.watch(combinedDataProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final selCat = ref.watch(selectedCategoryProvider);
    final search = ref.watch(searchProvider).toLowerCase();

    final primaryColor = const Color(0xFF1A237E);
    final accentColor = const Color(0xFF3F51B5);
    final backgroundColor = const Color(0xFFFAFAFA);

    Widget buildImageSlider() {
      final sliderHeight = isTablet ? screenHeight * 0.2 : screenHeight * 0.16;

      return Container(
        height: sliderHeight,
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.008,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              PageView.builder(
                controller: _sliderController,
                onPageChanged: (index) {
                  setState(() => _currentSliderIndex = index);
                },
                itemCount: _sliderImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, _sliderRoutes[index]);
                    },
                    child: CachedNetworkImage(
                      imageUrl: _sliderImages[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _sliderImages.asMap().entries.map((entry) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentSliderIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildGlassCard(
        {required Widget child, double? width, double? height}) {
      return GlassmorphicContainer(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        borderRadius: 14,
        blur: 18,
        border: 1.2,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: child,
      );
    }

    Widget buildHorizontalItem(Product p) {
      final itemWidth = cardWidth;
      final itemHeight = cardHeight;
      final imageSize = itemWidth * 0.7;
      final fontSize = itemWidth * 0.038;

      return Container(
        width: itemWidth,
        height: itemHeight,
        margin: EdgeInsets.only(right: screenWidth * 0.025),
        child: buildGlassCard(
          width: itemWidth,
          height: itemHeight,
          child: Padding(
            padding: EdgeInsets.all(itemWidth * 0.04),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (p.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: p.imageUrl!,
                      width: imageSize,
                      height: itemHeight * 0.55,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: imageSize,
                        height: itemHeight * 0.55,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                SizedBox(height: itemHeight * 0.025),
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize.clamp(11.0, 15.0),
                  ),
                ),
                SizedBox(height: itemHeight * 0.015),
                Text(
                  '₺${p.newPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: (fontSize * 0.9).clamp(10.0, 14.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget horizontalList(List<Product> list) {
      if (list.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
          child: Center(
            child: Text(
              t(ref, 'noData'),
              style: TextStyle(
                fontSize: (screenWidth * 0.04).clamp(14.0, 18.0),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      return SizedBox(
        height: cardHeight + 15,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          itemCount: list.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: list[i]),
              ),
            ),
            child: buildHorizontalItem(list[i]),
          ),
        ),
      );
    }

    Widget buildDiscountedItem(Product p) {
      final discountPercent =
          ((p.oldPrice - p.newPrice) / p.oldPrice * 100).round();
      final itemHeight = isTablet ? screenHeight * 0.07 : screenHeight * 0.065;
      final imageSize = itemHeight * 0.65;

      return Container(
        margin: EdgeInsets.symmetric(
          vertical: screenHeight * 0.004,
          horizontal: screenWidth * 0.025,
        ),
        height: itemHeight,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
          ),
          child: buildGlassCard(
            height: itemHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.012,
                vertical: screenHeight * 0.005,
              ),
              child: Row(
                children: [
                  if (p.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: p.imageUrl!,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: imageSize,
                          height: imageSize,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (screenWidth * 0.03).clamp(10.0, 14.0),
                              color: Colors.black.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.002),
                        Text(
                          '₺${p.newPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: (screenWidth * 0.028).clamp(9.0, 13.0),
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.01,
                        vertical: screenHeight * 0.004,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '%$discountPercent',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (screenWidth * 0.032).clamp(11.0, 16.0),
                              color: Colors.redAccent,
                            ),
                          ),
                          Text(
                            t(ref, 'discount'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: (screenWidth * 0.018).clamp(7.0, 10.0),
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
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

    Widget verticalDiscountedList(List<Product> list) {
      if (list.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
          child: Center(
            child: Text(
              t(ref, 'noData'),
              style: TextStyle(
                fontSize: (screenWidth * 0.04).clamp(14.0, 18.0),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: list.length,
        itemBuilder: (_, i) => buildDiscountedItem(list[i]),
      );
    }

    Widget buildSearchBar() {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.006,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade700.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: t(ref, 'searchHint'),
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: (screenWidth * 0.032).clamp(11.0, 15.0),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade300,
                size: (screenWidth * 0.055).clamp(18.0, 24.0),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.012,
              ),
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: (screenWidth * 0.035).clamp(12.0, 16.0),
            ),
            onChanged: (v) => ref.read(searchProvider.notifier).state = v,
          ),
        ),
      );
    }

    Widget buildCategoryButtons(int? selCat, Color primaryColor) {
      final buttonHeight =
          isTablet ? screenHeight * 0.05 : screenHeight * 0.045;

      return Container(
        height: buttonHeight + 8,
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          children: [
            _categoryButton(
                t(ref, 'cat_all'), null, selCat, primaryColor, buttonHeight),
            _categoryButton(
                t(ref, 'cat_food'), 1, selCat, primaryColor, buttonHeight),
            _categoryButton(t(ref, 'cat_technology'), 2, selCat, primaryColor,
                buttonHeight),
            _categoryButton(
                t(ref, 'cat_hygiene'), 3, selCat, primaryColor, buttonHeight),
          ],
        ),
      );
    }

    Widget buildSectionTitle(String title) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
        child: Text(
          title,
          style: TextStyle(
            fontSize: (screenWidth * 0.045).clamp(16.0, 22.0),
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      );
    }

    Widget bodyWidget() {
      return combinedDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final products = data['products'] as List<Product>;

          final filteredProducts = products
              .where((p) =>
                  (selCat == null || p.categoryId == selCat) &&
                  p.name.toLowerCase().contains(search))
              .toList();

          final discountedProducts = filteredProducts
              .where((p) => (p.oldPrice - p.newPrice) / p.oldPrice >= 0.1)
              .toList();

          return Container(
            color: backgroundColor,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  buildImageSlider(),
                  buildSearchBar(),
                  buildCategoryButtons(selCat, primaryColor),
                  SizedBox(height: screenHeight * 0.012),
                  buildSectionTitle(t(ref, 'allProducts')),
                  SizedBox(height: screenHeight * 0.008),
                  horizontalList(filteredProducts),
                  SizedBox(height: screenHeight * 0.018),
                  buildSectionTitle(t(ref, 'discounted')),
                  SizedBox(height: screenHeight * 0.008),
                  verticalDiscountedList(discountedProducts),
                  SizedBox(height: screenHeight * 0.1 + bottomPadding),
                ],
              ),
            ),
          );
        },
      );
    }

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
                      child: const Text('×', style: TextStyle(fontSize: 24)),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Supabase.instance.client.auth.signOut();
                        Navigator.pushReplacementNamed(context, '/auth');
                      },
                      child: const Text('✓', style: TextStyle(fontSize: 24)),
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
      body: connectivityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (connectivity) {
          if (connectivity == ConnectivityResult.none) {
            return Center(
              child: Text(
                t(ref, 'noInternet'),
                style: TextStyle(
                  fontSize: (screenWidth * 0.045).clamp(16.0, 22.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            );
          }
          return bodyWidget();
        },
      ),
    );
  }

  Widget _categoryButton(String text, int? id, int? selectedId,
      Color primaryColor, double buttonHeight) {
    final selected = selectedId == id;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.008),
      height: buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selected ? primaryColor : Colors.white.withOpacity(0.9),
          foregroundColor: selected ? Colors.white : primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonHeight / 2)),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035),
          elevation: selected ? 4 : 2,
        ),
        onPressed: () => ref.read(selectedCategoryProvider.notifier).state =
            selected ? null : id,
        child: Text(
          text,
          style: TextStyle(
            fontSize: (screenWidth * 0.03).clamp(10.0, 14.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
