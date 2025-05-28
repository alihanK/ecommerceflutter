import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'utils/constants.dart';
import 'views/about_us.dart';
import 'views/auth_screen.dart';
import 'views/cart_screen.dart';
import 'views/order_confirmation_screen.dart';
import 'views/order_finish.dart';
import 'views/product_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Commerce',
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthCheck(),
        '/products': (_) => const ProductListScreen(),
        '/CartScreen': (_) => CartScreen(),
        '/AboutUsScreen': (_) => const AboutUsScreen(),
        '/login': (_) => const AuthScreen(),
        '/auth': (_) => const AuthScreen(),
        '/OrderConfirmationScreen': (_) => const OrderConfirmationScreen(),
        '/OrderFinishScreen': (_) => OrderFinishPage(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final _auth = Supabase.instance.client.auth;
  bool? _signedIn;

  @override
  void initState() {
    super.initState();
    _signedIn = _auth.currentSession != null;

    _auth.onAuthStateChange.listen((data) {
      final isSignedIn = data.session != null;

      if (mounted && _signedIn != isSignedIn) {
        setState(() {
          _signedIn = isSignedIn;
        });

        if (isSignedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/products');
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // İlk yükleme durumu
    if (_signedIn == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _signedIn! ? const ProductListScreen() : const AuthScreen();
  }
}
