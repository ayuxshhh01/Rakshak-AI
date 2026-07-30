import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../api/api_service.dart';
import '../bloc/auth_bloc.dart';

// --- UI Color and Style Constants ---
const Color primaryTeal = Color(0xFF006B5E);
const Color secondaryOrange = Color(0xFFE8753F);
const Color lightTeal = Color(0xFFB3E5DC);
const Color backgroundLight = Color(0xFFFAF9F6);
const Color darkTextColor = Color(0xFF1A1F36);
const Color lightGreyText = Color(0xFF757575);
const Color cardColor = Colors.white;

// Helper to convert string to IconData
IconData _getIconFromString(String? iconName) {
  switch (iconName) {
    case 'account_balance': return Icons.account_balance;
    case 'restaurant': return Icons.restaurant;
    case 'fort': return Icons.fort;
    case 'directions_car': return Icons.directions_car;
    case 'hotel': return Icons.hotel;
    case 'park': return Icons.park;
    case 'camera_alt': return Icons.camera_alt;
    case 'explore': return Icons.explore;
    case 'shopping_bag': return Icons.shopping_bag;
    case 'local_dining': return Icons.local_dining;
    case 'bed': return Icons.bed;
    case 'nature_people': return Icons.nature_people;
    case 'museum': return Icons.museum;
    default: return Icons.place;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(FetchDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('My Journey', style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }
          if (state is DashboardLoaded) {
            final bool hasItinerary = state.itinerary?.keys.isNotEmpty ?? false;
            if (!hasItinerary) {
              return const ItineraryPlanner();
            } else {
              return ItineraryDisplay(
                safetyScore: state.safetyScore,
                itinerary: state.itinerary!,
              );
            }
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text("Failed to load data.", style: TextStyle(fontSize: 18, color: darkTextColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try Again", style: TextStyle(fontSize: 16)),
                  onPressed: () => context.read<DashboardBloc>().add(FetchDashboardData()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Itinerary Planner UI ---
class ItineraryPlanner extends StatefulWidget {
  const ItineraryPlanner({Key? key}) : super(key: key);
  @override
  _ItineraryPlannerState createState() => _ItineraryPlannerState();
}

class _ItineraryPlannerState extends State<ItineraryPlanner> {
  final _formKey = GlobalKey<FormState>();
  String _destination = '';
  int _duration = 1;
  String _budget = '';
  bool _isLoading = false;

  void _generatePlan() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final apiService = context.read<AuthBloc>().apiService;
        await apiService.generateItinerary(_destination, _duration, _budget);
        if (mounted) context.read<DashboardBloc>().add(FetchDashboardData());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating plan: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(40.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildShieldWithCompassIcon(),
          ),
          const SizedBox(height: 32),
          const Text(
            'Plan Your Adventure',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: darkTextColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a personalized itinerary crafted by AI for safe, unforgettable travels',
            textAlign: TextAlign.center,
            style: TextStyle(color: lightGreyText, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextFormField(
                  labelText: 'Where are you heading?',
                  prefixIcon: Icons.location_on_rounded,
                  validator: (v) => v!.isEmpty ? 'Please enter a destination' : null,
                  onSaved: (v) => _destination = v!,
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  labelText: 'How many days?',
                  prefixIcon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0 ? 'Enter valid days' : null,
                  onSaved: (v) => _duration = int.parse(v!),
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  labelText: 'Budget level',
                  prefixIcon: Icons.wallet_travel_rounded,
                  validator: (v) => v!.isEmpty ? 'Please enter budget' : null,
                  onSaved: (v) => _budget = v!,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: primaryTeal.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Text(
                    'Create My Itinerary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldWithCompassIcon() {
    return Center(child: Stack(alignment: Alignment.center, children: [Icon(Icons.shield_outlined, size: 70, color: primaryTeal), Icon(Icons.explore_outlined, size: 38, color: primaryTeal.withOpacity(0.8))]));
  }

  Widget _buildTextFormField({
    required String labelText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color(0xFF006B5E), fontWeight: FontWeight.w600, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: primaryTeal, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}

// --- UI for Displaying the Itinerary ---
class ItineraryDisplay extends StatelessWidget {
  final int safetyScore;
  final Map<String, dynamic> itinerary;
  const ItineraryDisplay({Key? key, required this.safetyScore, required this.itinerary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => context.read<DashboardBloc>().add(FetchDashboardData()),
      color: primaryTeal,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 30.0),
        children: [
          SafetyScoreCard(safetyScore: safetyScore),
          const SizedBox(height: 36),
          const Text(
            'Your Itinerary',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: darkTextColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          ...itinerary.entries.map((dayEntry) {
            final activities = dayEntry.value as List;
            return ItineraryDayCard(dayEntry: dayEntry, activities: activities);
          }).toList(),
        ],
      ),
    );
  }
}

class ItineraryDayCard extends StatelessWidget {
  final MapEntry<String, dynamic> dayEntry;
  final List<dynamic> activities;
  const ItineraryDayCard({Key? key, required this.dayEntry, required this.activities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: lightTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dayEntry.key.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primaryTeal,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...activities.map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: lightTeal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconFromString(activity['icon']),
                        color: primaryTeal,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['time'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: darkTextColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['activity'],
                            style: const TextStyle(
                              fontSize: 15,
                              color: lightGreyText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// --- SafetyScoreCard Widget ---
class SafetyScoreCard extends StatelessWidget {
  final int safetyScore;
  const SafetyScoreCard({Key? key, required this.safetyScore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String scoreRemark;
    Color gradientStart, gradientEnd;
    IconData shieldIcon;

    if (safetyScore >= 80) {
      scoreRemark = "Excellent! Enjoy your trip with confidence.";
      gradientStart = primaryTeal;
      gradientEnd = const Color(0xFF004D47);
      shieldIcon = Icons.verified_user_rounded;
    } else if (safetyScore >= 50) {
      scoreRemark = "Good rating. Stay aware of surroundings.";
      gradientStart = const Color(0xFFE8753F);
      gradientEnd = const Color(0xFFC65321);
      shieldIcon = Icons.warning_amber_rounded;
    } else {
      scoreRemark = "Caution advised. Plan carefully.";
      gradientStart = Colors.red.shade700;
      gradientEnd = Colors.red.shade900;
      shieldIcon = Icons.dangerous_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientEnd.withOpacity(0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(shieldIcon, color: Colors.white, size: 48),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Score',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$safetyScore / 100',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scoreRemark,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}