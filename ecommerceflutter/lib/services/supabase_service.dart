import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';

class SupabaseService {
  final GoTrueClient auth = Supabase.instance.client.auth;
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Product>> fetchProducts() async {
    final data = await client
        .from('products')
        .select()
        .order('id', ascending: true) as List;
    return data
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Category>> fetchCategories() async {
    final data = await client.from('categories').select() as List;
    return data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> decrementStock({
    required int productId,
    required int amount,
  }) async {
    final row = await client
        .from('products')
        .select('stock')
        .eq('id', productId)
        .single();
    final current = (row['stock'] as num).toInt();
    final newStock = (current - amount).clamp(0, current);
    await client
        .from('products')
        .update({'stock': newStock}).eq('id', productId);
  }

  Future<List<Order>> fetchUserOrders() async {
    final user = auth.currentUser;
    if (user == null) return [];
    final data = await client
        .from('orders')
        .select('''
          id,
          total,
          created_at,
          order_items (
            quantity,
            product ( name, new_price )
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(10) as List;
    return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }
}
