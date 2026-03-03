import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_design.dart';
import '../core/utils/avatar_utils.dart';
import '../providers/auth_provider.dart';
import 'app_router.dart';

class MainScaffold extends ConsumerWidget {
  final String location;
  final Widget child;

  const MainScaffold({
    super.key,
    required this.location,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tabs = <_TabItem>[
      _TabItem(icon: Icons.home_rounded, label: 'Accueil'),
      _TabItem(icon: Icons.category_rounded, label: 'Thèmes'),
      _TabItem(icon: Icons.quiz_rounded, label: 'Quiz'),
      _TabItem(icon: Icons.emoji_events_rounded, label: 'Classement'),
      _TabItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    final currentIndex = _getTabIndex(location);

    return Scaffold(
      drawer: _AppDrawer(currentLocation: location),
      body: child,
      bottomNavigationBar: _AnimatedNavBar(
        currentIndex: currentIndex.clamp(0, tabs.length - 1),
        tabs: tabs,
        onTap: (i) => _onTabChanged(context, i),
      ),
    );
  }

  int _getTabIndex(String loc) {
    if (loc.startsWith(AppRoutes.themes)) return 1;
    if (loc.startsWith(AppRoutes.quizzes)) return 2;
    if (loc.startsWith(AppRoutes.leaderboard)) return 3;
    if (loc.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTabChanged(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.themes);
      case 2:
        context.go(AppRoutes.quizzes);
      case 3:
        context.go(AppRoutes.leaderboard);
      case 4:
        context.go(AppRoutes.profile);
    }
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM ANIMATED BOTTOM NAV BAR
// ═══════════════════════════════════════════════════════════════
class _AnimatedNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _AnimatedNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final isActive = i == currentIndex;
              return _NavBarItem(
                icon: tabs[i].icon,
                label: tabs[i].label,
                isActive: isActive,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColors.primary : AppColors.textMutedLight;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 16 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  widget.icon,
                  size: widget.isActive ? 26 : 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: widget.isActive ? 11 : 10,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(widget.label),
              ),
              // Active indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(top: 3),
                width: widget.isActive ? 18 : 0,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: widget.isActive ? AppDesign.accentBarGradient : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DRAWER MENU
// ═══════════════════════════════════════════════════════════════
class _AppDrawer extends ConsumerWidget {
  final String currentLocation;
  const _AppDrawer({required this.currentLocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = user?.firstName ?? 'Utilisateur';
    final lastName = user?.lastName ?? '';
    final email = user?.email ?? '';
    final avatar = user?.avatar;
    final userId = user?.id;
    
    // Build full avatar URL if user has an avatar
    final avatarUrl = AvatarUtils.buildAvatarUrl(avatar);

    return Drawer(
      child: Column(
        children: [
          // ── Premium Drawer Header with gold ring ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: AppDesign.heroGradient,
            ),
            child: Stack(
              children: [
                // Floating particles decoration
                Positioned.fill(
                  child: FloatingParticles(
                    count: 5,
                    color: AppColors.accent,
                    maxSize: 6,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with gold ring
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppDesign.goldGradient,
                        boxShadow: AppDesign.glowShadow(AppColors.accent, blur: 12),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryDark,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? (userId != null
                                ? ClipOval(
                                    child: SvgPicture.network(
                                      AvatarUtils.generateDiceBearUrl(userId),
                                      width: 60,
                                      height: 60,
                                      placeholderBuilder: (context) => Text(
                                        firstName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    firstName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$firstName $lastName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Stars badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${user?.stars ?? 0}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Menu Items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerSection(title: 'Navigation'),
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  isActive: currentLocation == AppRoutes.dashboard,
                  onTap: () => _navigate(context, AppRoutes.dashboard),
                ),
                _DrawerItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quiz',
                  isActive: currentLocation.startsWith(AppRoutes.quizzes),
                  onTap: () => _navigate(context, AppRoutes.quizzes),
                ),
                _DrawerItem(
                  icon: Icons.category_rounded,
                  label: 'Thèmes',
                  isActive: currentLocation.startsWith(AppRoutes.themes),
                  onTap: () => _navigate(context, AppRoutes.themes),
                ),

                const Divider(height: 16, indent: 16, endIndent: 16),
                _DrawerSection(title: 'Communauté'),
                _DrawerItem(
                  icon: Icons.sports_mma_rounded,
                  label: 'Duels',
                  isActive: currentLocation.startsWith(AppRoutes.duels),
                  onTap: () => _navigate(context, AppRoutes.duels),
                ),
                _DrawerItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Classement',
                  isActive: currentLocation.startsWith(AppRoutes.leaderboard),
                  onTap: () => _navigate(context, AppRoutes.leaderboard),
                ),

                const Divider(height: 16, indent: 16, endIndent: 16),
                _DrawerSection(title: 'Mon compte'),
                _DrawerItem(
                  icon: Icons.history_rounded,
                  label: 'Historique',
                  isActive: currentLocation == AppRoutes.history,
                  onTap: () => _navigate(context, AppRoutes.history),
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isActive: currentLocation.startsWith(AppRoutes.profile),
                  onTap: () => _navigate(context, AppRoutes.profile),
                ),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Paramètres',
                  isActive: currentLocation == AppRoutes.settings,
                  onTap: () => _navigate(context, AppRoutes.settings),
                ),

                const Divider(height: 16, indent: 16, endIndent: 16),
                _DrawerSection(title: 'Informations'),
                _DrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Aide',
                  isActive: currentLocation == AppRoutes.help,
                  onTap: () => _navigatePush(context, AppRoutes.help),
                ),
                _DrawerItem(
                  icon: Icons.description_rounded,
                  label: 'Conditions d\'utilisation',
                  isActive: currentLocation == AppRoutes.terms,
                  onTap: () => _navigatePush(context, AppRoutes.terms),
                ),
              ],
            ),
          ),

          // ── Logout ──
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop(); // close drawer
    context.go(route);
  }

  void _navigatePush(BuildContext context, String route) {
    Navigator.of(context).pop(); // close drawer
    context.push(route);
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  const _DrawerSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
              border: isActive
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.15))
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.primary : null,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
                if (isActive)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: AppDesign.accentBarGradient,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
