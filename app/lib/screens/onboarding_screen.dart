import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';

class OnboardingScreen extends StatefulWidget {
  final List<Allergen> allergens;
  final UserProfile userProfile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const OnboardingScreen({
    super.key,
    required this.allergens,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.userProfile;
  }

  void _toggleAllergen(Allergen allergen) {
    setState(() {
      _profile = _profile.toggleAllergen(allergen);
    });
  }

  void _complete() {
    final updated = _profile.copyWith(hasCompletedOnboarding: true);
    widget.onProfileUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('בחר אלרגנים'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.allergens.length,
                itemBuilder: (context, index) {
                  final allergen = widget.allergens[index];
                  final isSelected = _profile.isAllergenSelected(allergen.id);
                  return CheckboxListTile(
                    title: Text(allergen.nameHe),
                    value: isSelected,
                    onChanged: (_) => _toggleAllergen(allergen),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _profile.selectedAllergenIds.isNotEmpty
                      ? _complete
                      : null,
                  child: const Text('התחל'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
