import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/child.dart';
import '../../../core/services/staff_service.dart';

class AssignChildrenScreen extends StatefulWidget {
  final List<ActivityPhoto> photos;
  final Activity activity;

  const AssignChildrenScreen({
    super.key,
    required this.photos,
    required this.activity,
  });

  @override
  State<AssignChildrenScreen> createState() => _AssignChildrenScreenState();
}

class _AssignChildrenScreenState extends State<AssignChildrenScreen> {
  final _staffService = StaffService();
  final Map<int, List<String>> _assignments = {};
  List<Child> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize assignments map with empty lists
    for (int i = 0; i < widget.photos.length; i++) {
      _assignments[i] = widget.photos[i].assignedChildIds;
    }
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final children = await _staffService.getAllChildren();
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showChildrenBottomSheet(int index) {
    List<String> selectedForThisPhoto = List.from(_assignments[index] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Assigner des enfants',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _children.length,
                      itemBuilder: (context, idx) {
                        final child = _children[idx];
                        final isSelected = selectedForThisPhoto.contains(
                          child.id,
                        );
                        return CheckboxListTile(
                          title: Text(child.fullName),
                          value: isSelected,
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                selectedForThisPhoto.add(child.id);
                              } else {
                                selectedForThisPhoto.remove(child.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {
                          _assignments[index] = selectedForThisPhoto;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Confirmer l\'assignation'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAssignments() async {
    setState(() => _isLoading = true);
    try {
      for (int i = 0; i < widget.photos.length; i++) {
        final photo = widget.photos[i];
        final assignedChildIds = _assignments[i] ?? [];
        await _staffService.assignChildrenToPhoto(photo.id, assignedChildIds);
      }
      if (mounted) Navigator.pop(context, true); // Indicate success and pop
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'assignation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignation'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAssignments,
            child: _isLoading
                ? const CircularProgressIndicator(color: AppColors.primary)
                : const Text(
                    'Enregistrer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                final count = _assignments[index]?.length ?? 0;
                return GestureDetector(
                  onTap: () => _showChildrenBottomSheet(index),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          photo.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: AppColors.textSecondary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.broken_image_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.textSecondary.withValues(alpha: 0.1),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
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
