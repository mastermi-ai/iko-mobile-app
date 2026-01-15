import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/login_screen.dart';
import 'bloc/cart_cubit.dart';
// Background worker temporarily disabled for Android 7.0 compatibility
// import 'services/background_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Background sync temporarily disabled - manual sync via dashboard button
  // if (!kIsWeb) {
  //   await initializeBackgroundWorker();
  // }

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
