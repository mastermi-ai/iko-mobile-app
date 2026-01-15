import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/login_screen.dart';
import 'bloc/cart_cubit.dart';
import 'services/background_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background sync worker (only on mobile platforms, not web)
  if (!kIsWeb) {
    await initializeBackgroundWorker();
  }

  runApp(const IKOApp());
}

class IKOApp extends StatelessWidget {
  const IKOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CartCubit(),
      child: MaterialApp(
        title: 'IKO Mobile Sales',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
