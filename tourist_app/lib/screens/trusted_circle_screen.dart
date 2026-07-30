import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trusted_circle_bloc.dart';

const Color primaryTeal = Color(0xFF006B5E);
const Color backgroundLight = Color(0xFFFAF9F6);
const Color darkText = Color(0xFF1A1F36);
const Color lightGrey = Color(0xFF757575);

class TrustedCircleScreen extends StatefulWidget {
  const TrustedCircleScreen({Key? key}) : super(key: key);

  @override
  State<TrustedCircleScreen> createState() => _TrustedCircleScreenState();
}

class _TrustedCircleScreenState extends State<TrustedCircleScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRelationship = 'Family';

  @override
  void initState() {
    super.initState();
    context.read<TrustedCircleBloc>().add(const FetchTrustedCircle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Trusted Circle', style: TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<TrustedCircleBloc, TrustedCircleState>(
        listener: (context, state) {
          if (state is TrustedCircleSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: primaryTeal),
            );
          }
          if (state is TrustedCircleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is TrustedCircleLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }

          if (state is TrustedCircleLoaded) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildAddMemberCard(),
                const SizedBox(height: 32),
                const Text('Circle Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkText)),
                const SizedBox(height: 16),
                if (state.members.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No trusted members yet', style: TextStyle(color: lightGrey, fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                else
                  ...state.members.map((member) => _buildMemberCard(member)),
                const SizedBox(height: 32),
                const Text('Shared Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkText)),
                const SizedBox(height: 16),
                if (state.sharedLocations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No shared locations', style: TextStyle(color: lightGrey)),
                  )
                else
                  ...state.sharedLocations.map((loc) => _buildLocationCard(loc)),
              ],
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text('Failed to load', style: TextStyle(color: darkText, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.read<TrustedCircleBloc>().add(const FetchTrustedCircle()),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddMemberCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Family Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkText)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'Phone Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _selectedRelationship,
              onChanged: (value) => setState(() => _selectedRelationship = value ?? 'Family'),
              items: ['Family', 'Friend', 'Emergency Contact']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addMember,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                child: const Text('Add Member', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryTeal,
          child: Text(member['name']?[0] ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        title: Text(member['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, color: darkText)),
        subtitle: Text('${member['relationship']} • ${member['phone_number']}', style: const TextStyle(color: lightGrey)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteMember(member['id']),
        ),
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> loc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: primaryTeal),
        title: Text(loc['username'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, color: darkText)),
        subtitle: Text('Safety Score: ${loc['safety_score']}', style: const TextStyle(color: lightGrey)),
      ),
    );
  }

  void _addMember() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.orange),
      );
      return;
    }

    context.read<TrustedCircleBloc>().add(
      AddTrustedCircleMember(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        relationship: _selectedRelationship,
      ),
    );

    _nameController.clear();
    _phoneController.clear();
  }

  void _deleteMember(int memberId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<TrustedCircleBloc>().add(DeleteTrustedCircleMember(memberId));
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
