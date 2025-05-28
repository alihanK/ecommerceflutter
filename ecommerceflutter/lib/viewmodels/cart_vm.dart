import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';

class CartNotifier extends StateNotifier<List<Product>> {
  CartNotifier() : super([]);

  void add(Product p) => state = [...state, p];

  void remove(Product p) {
    final index = state.indexWhere((x) => x.id == p.id);
    if (index == -1) return;
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }

  void removeOne(Product p) {
    final index = state.indexWhere((x) => x.id == p.id);
    if (index == -1) return;

    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }

  void removeAll(Product p) {
    state = state.where((x) => x.id != p.id).toList();
  }

  void clearAll() => state = [];

  int getQuantity(Product p) {
    return state.where((x) => x.id == p.id).length;
  }

  double getTotalForProduct(Product p) {
    final quantity = getQuantity(p);
    return quantity * p.newPrice;
  }

  double get total => state.fold(0.0, (sum, p) => sum + p.newPrice);

  int get uniqueItemCount {
    final uniqueIds = <int>{};
    for (var product in state) {
      uniqueIds.add(product.id);
    }
    return uniqueIds.length;
  }

  int get totalItemCount => state.length;

  bool get isEmpty => state.isEmpty;

  bool get isNotEmpty => state.isNotEmpty;

  bool contains(Product p) {
    return state.any((x) => x.id == p.id);
  }

  Map<Product, int> get groupedItems {
    final Map<Product, int> grouped = {};
    for (var product in state) {
      final existingProduct = grouped.keys.firstWhere(
        (p) => p.id == product.id,
        orElse: () => product,
      );
      grouped[existingProduct] = (grouped[existingProduct] ?? 0) + 1;
    }
    return grouped;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<Product>>((_) => CartNotifier());
