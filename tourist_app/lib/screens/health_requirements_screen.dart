import 'package:flutter/material.dart';

const Color primaryTeal = Color(0xFF006B5E);
const Color secondaryOrange = Color(0xFFE8753F);
const Color backgroundLight = Color(0xFFFAF9F6);
const Color darkTextColor = Color(0xFF1A1F36);
const Color lightGreyText = Color(0xFF757575);
const Color cardColor = Colors.white;

class HealthRequirementsScreen extends StatefulWidget {
  const HealthRequirementsScreen({Key? key}) : super(key: key);

  @override
  State<HealthRequirementsScreen> createState() => _HealthRequirementsScreenState();
}

class _HealthRequirementsScreenState extends State<HealthRequirementsScreen> {
  final List<Map<String, dynamic>> vaccinations = [
    {
      'name': 'Yellow Fever',
      'required': true,
      'status': 'Completed',
      'icon': '💉',
      'date': 'Jan 15, 2026',
      'description': 'Recommended for this destination',
    },
    {
      'name': 'Typhoid',
      'required': true,
      'status': 'Completed',
      'icon': '💉',
      'date': 'Jan 15, 2026',
      'description': 'Common in South Asia',
    },
    {
      'name': 'Hepatitis A',
      'required': false,
      'status': 'Pending',
      'icon': '⚠️',
      'date': null,
      'description': 'Recommended if staying long-term',
    },
    {
      'name': 'COVID-19',
      'required': true,
      'status': 'Completed',
      'icon': '💉',
      'date': 'Dec 20, 2025',
      'description': 'Current travel requirement',
    },
  ];

  final List<Map<String, dynamic>> healthAlerts = [
    {
      'title': 'Water Safety',
      'description': 'Avoid tap water. Use bottled or boiled water only.',
      'severity': 'high',
      'icon': Icons.water_drop_rounded,
    },
    {
      'title': 'Mosquito-Borne Diseases',
      'description': 'Dengue and Malaria risk present. Use insect repellent.',
      'severity': 'high',
      'icon': Icons.bug_report_rounded,
    },
    {
      'title': 'Air Quality',
      'description': 'Moderate pollution levels. Consider N95 masks during peak hours.',
      'severity': 'medium',
      'icon': Icons.air_rounded,
    },
    {
      'title': 'Food Safety',
      'description': 'Eat only well-cooked food from established restaurants.',
      'severity': 'medium',
      'icon': Icons.restaurant_menu_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Health & Vaccinations',
          style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        children: [
          // Vaccinations Section
          const Text(
            'Required Vaccinations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkTextColor),
          ),
          const SizedBox(height: 16),
          ...vaccinations.map((vac) => _buildVaccinationTile(vac)).toList(),
          const SizedBox(height: 36),

          // Health Alerts Section
          const Text(
            'Health Alerts & Precautions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkTextColor),
          ),
          const SizedBox(height: 16),
          ...healthAlerts.map((alert) => _buildHealthAlertTile(alert)).toList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVaccinationTile(Map<String, dynamic> vac) {
    final isCompleted = vac['status'] == 'Completed';
    final statusColor = isCompleted ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(vac['icon'], style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vac['name'],
                              style: const TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 16),
                            ),
                            Text(
                              vac['description'],
                              style: const TextStyle(color: lightGreyText, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vac['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (vac['date'] != null)
                  Text(
                    vac['date'],
                    style: const TextStyle(color: lightGreyText, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthAlertTile(Map<String, dynamic> alert) {
    final severityColor = alert['severity'] == 'high' ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(alert['icon'], color: severityColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert['title'],
                        style: const TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          alert['severity'].toUpperCase(),
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert['description'],
                    style: const TextStyle(color: lightGreyText, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
