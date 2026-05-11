import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/notification_service.dart';
import '../../shared/widgets/main_layout.dart';
import 'account_form_screen.dart';
import '../../shared/widgets/search_filter_bar.dart';

class AccountManagementScreen extends StatefulWidget {
  final int initialTab;
  const AccountManagementScreen({super.key, this.initialTab = 0});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminService = AdminService();

  List<UserProfile> _staff = [];
  List<UserProfile> _parents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final staff = await _adminService.getAccountsByRole(UserRole.staff);
      final parents = await _adminService.getAccountsByRole(UserRole.parent);
      setState(() {
        _staff = staff;
        _parents = parents;
      });
    } catch (e) {
      NotificationService.showSnackBar(
        'Erreur lors du chargement des comptes',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Gestion Comptes',
      showBackButton: false,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Staff'),
                Tab(text: 'Parents'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SearchFilterBar(
              hintText: 'Rechercher un compte...',
              onFilterPressed: () {},
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAccountList(_staff, 'Staff'),
                _buildAccountList(_parents, 'Parent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList(List<UserProfile> accounts, String role) {
    return Stack(
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (accounts.isEmpty)
          const Center(child: Text('Aucun compte trouvé'))
        else
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final user = accounts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        (user.fullName != null && user.fullName!.isNotEmpty)
                            ? user.fullName!.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? 'Utilisateur',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AccountFormScreen(role: role, userProfile: user),
                        ),
                      ).then((_) => _loadAccounts()),
                    ),
                    IconButton(
                      icon: Icon(
                        user.isBlocked
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        color: user.isBlocked ? Colors.orange : Colors.grey,
                      ),
                      onPressed: () => _confirmToggleBlock(user),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmDelete(user),
                    ),
                  ],
                ),
              );
            },
          ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountFormScreen(role: role),
              ),
            ).then((_) => _loadAccounts()),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person_add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmToggleBlock(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isBlocked ? 'Débloquer' : 'Bloquer'),
        content: Text(
          'Voulez-vous vraiment ${user.isBlocked ? 'débloquer' : 'bloquer'} le compte de ${user.fullName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              user.isBlocked ? 'Débloquer' : 'Bloquer',
              style: TextStyle(
                color: user.isBlocked ? AppColors.primary : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.toggleBlockAccount(user.id, !user.isBlocked);
        NotificationService.showSnackBar(
          'Compte ${user.isBlocked ? 'débloqué' : 'bloqué'} avec succès',
        );
        _loadAccounts();
      } catch (e) {
        NotificationService.showSnackBar(
          'Erreur lors de la modification du statut',
          isError: true,
        );
      }
    }
  }

  Future<void> _confirmDelete(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text(
          'Voulez-vous vraiment supprimer définitivement le compte de ${user.fullName} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteAccount(user.id);
        NotificationService.showSnackBar('Compte supprimé avec succès');
        _loadAccounts();
      } catch (e) {
        NotificationService.showSnackBar(
          'Erreur lors de la suppression du compte',
          isError: true,
        );
      }
    }
  }
}
