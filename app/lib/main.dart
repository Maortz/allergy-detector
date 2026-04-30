import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/onboarding_screen.dart';
import 'screens/search_screen.dart';
import 'models/allergen.dart';
import 'models/user_profile.dart';
import 'services/allergen_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseKey = const String.fromEnvironment('SUPABASE_KEY');
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
      title: 'גלאי אלרגנים',
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      home: const AppShell(),
    ));
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
  String? _allergenLoadError;

  @override
  void initState() {
    super.initState();
    _loadProfileAndAllergens();
  }

  Future<void> _loadProfileAndAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('selected_allergen_ids') ?? [];
    final completedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

    List<Allergen> allergens = [];
    String? loadError;
    try {
      final service = AllergenService(Supabase.instance.client);
      allergens = await service.fetchAllergens();
    } catch (e) {
      loadError = e.toString();
    }

    if (mounted) {
      setState(() {
        _allergens = allergens;
        _allergenLoadError = loadError;
        _profile = UserProfile(
          selectedAllergenIds: savedIds.toSet(),
          hasCompletedOnboarding: completedOnboarding,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _onProfileUpdated(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selected_allergen_ids',
      profile.selectedAllergenIds.toList(),
    );
    await prefs.setBool(
      'has_completed_onboarding',
      profile.hasCompletedOnboarding,
    );
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  Widget _buildErrorScreen(String error) {
    final isNetworkError = error.toLowerCase().contains('socketexception') ||
        error.toLowerCase().contains('connection');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  isNetworkError
                      ? 'אין חיבור לאינטרנט'
                      : 'לא ניתן לטעון את הנתונים',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'יש להתחבר לאינטרנט כדי להשתמש באפליקציה',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _allergenLoadError = null;
                    });
                    _loadProfileAndAllergens();
                  },
                  child: const Text('נסה שוב'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_allergenLoadError != null && !_profile.hasCompletedOnboarding) {
      return _buildErrorScreen(_allergenLoadError!);
    }

    if (!_profile.hasCompletedOnboarding) {
      return OnboardingScreen(
        allergens: _allergens,
        userProfile: _profile,
        onProfileUpdated: _onProfileUpdated,
      );
    }

    return SearchScreenContent(
      userProfile: _profile,
      allergens: _allergens,
      onProfileUpdated: _onProfileUpdated,
    );
  }
}