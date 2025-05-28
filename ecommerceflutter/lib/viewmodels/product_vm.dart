import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/supabase_service.dart';

final productListProvider = FutureProvider.autoDispose<List<Product>>(
    (ref) => SupabaseService().fetchProducts());
