import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'models/allergen.dart';
import 'models/user_profile.dart';
import 'services/allergen_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '../.env');
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

    final service = AllergenService(Supabase.instance.client);
    final allergens = await service.fetchAllergens();

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
      home: SearchScreen(
        userProfile: _profile,
        allergens: _allergens,
        onProfileUpdated: _onProfileUpdated,
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;

  const SearchScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('גלאי אלרגנים'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'חפש מוצר',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: Text('חפש מוצר לפי שם או ברקוד'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
