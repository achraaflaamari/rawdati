import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/main_layout.dart';
import '../../shared/widgets/search_filter_bar.dart';
import 'publication_screen.dart';

class ChildSelectionScreen extends StatefulWidget {
  const ChildSelectionScreen({super.key});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen> {
  final List<Map<String, dynamic>> children = [
    {'name': 'Ahmed Ben Salah', 'group': 'Petite section', 'selected': true},
    {'name': 'Sarra Mansouri', 'group': 'Grande section', 'selected': false},
    {'name': 'Youssef Trabelsi', 'group': 'Moyenne section', 'selected': true},
    {'name': 'Mariem Gharbi', 'group': 'Petite section', 'selected': false},
    {'name': 'Omar Feki', 'group': 'Grande section', 'selected': true},
    {'name': 'Lina Jallouli', 'group': 'Moyenne section', 'selected': false},
  ];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Assignation',
      showBackButton: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: SearchFilterBar(
              hintText: 'Rechercher un enfant...',
              onFilterPressed: () => _showFilterBottomSheet(context),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: CheckboxListTile(
                    value: child['selected'],
                    onChanged: (value) {
                      setState(() {
                        children[index]['selected'] = value;
                      });
                    },
                    title: Text(
                      child['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      child['group'],
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        child['name'][0],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: child['selected']
                            ? AppColors.primary
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    activeColor: AppColors.primary,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PublicationScreen(),
                  ),
                );
              },
              child: const Text('Suivant : Publication'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par groupe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Toutes les sections'),
              trailing: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Petite Section'),
              trailing: const Icon(Icons.circle_outlined, color: Colors.grey),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Appliquer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
