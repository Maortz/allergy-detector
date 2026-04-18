import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/search_screen.dart';
import 'models/allergen.dart';
import 'models/user_profile.dart';
import 'services/allergen_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const isWeb = identical(0, 0.0);
  if (!isWeb) {
    try {
      final localEnv = File('.env.local');
      if (await localEnv.exists()) {
        await dotenv.load(fileName: '.env.local');
      } else {
        await dotenv.load(fileName: '../.env');
      }
    } catch (_) {
      await dotenv.load(fileName: '../.env');
    }
  } else {
    await dotenv.load();
  }
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLIC_API_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'גלאי אלרגנים',
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  UserProfile _profile = const UserProfile();
  List<Allergen> _allergens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndAllergens();
  }

  Future<void> _loadProfileAndAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('selected_allergen_ids') ?? [];
    final completedOnboarding =
        prefs.getBool('has_completed_onboarding') ?? false;

    List<Allergen> allergens = [];
    try {
      final service = AllergenService(Supabase.instance.client);
      allergens = await service.fetchAllergens();
    } catch (e) {
      allergens = _getDefaultAllergens();
    }

    if (mounted) {
      setState(() {
        _allergens = allergens;
        _profile = UserProfile(
          selectedAllergenIds: savedIds.toSet(),
          hasCompletedOnboarding: completedOnboarding,
        );
        _isLoading = false;
      });
    }
  }

  List<Allergen> _getDefaultAllergens() {
    return [
      const Allergen(id: '1', nameHe: 'חלב', nameEn: 'Milk'),
      const Allergen(id: '2', nameHe: 'ביצים', nameEn: 'Eggs'),
      const Allergen(id: '3', nameHe: 'אגוזים', nameEn: 'Nuts'),
      const Allergen(id: '4', nameHe: 'רגישות לגלוטן', nameEn: 'Gluten'),
      const Allergen(id: '5', nameHe: 'סויה', nameEn: 'Soy'),
      const Allergen(id: '6', nameHe: 'דגים', nameEn: 'Fish'),
      const Allergen(id: '7', nameHe: 'שרימפס', nameEn: 'Shrimp'),
      const Allergen(id: '8', nameHe: 'תירס', nameEn: 'Corn'),
    ];
  }

  Future<void> _onProfileUpdated(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'selected_allergen_ids', profile.selectedAllergenIds.toList());
    await prefs.setBool(
        'has_completed_onboarding', profile.hasCompletedOnboarding);
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      );
    }

    if (!_profile.hasCompletedOnboarding) {
      return MaterialApp(
        locale: const Locale('he'),
        supportedLocales: const [Locale('he')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: OnboardingScreen(
          allergens: _allergens,
          userProfile: _profile,
          onProfileUpdated: _onProfileUpdated,
        ),
      );
    }

    return MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SearchScreenContent(
        userProfile: _profile,
        allergens: _allergens,
        onProfileUpdated: _onProfileUpdated,
      ),
    );
  }
}
