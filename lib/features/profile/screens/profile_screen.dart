import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design.dart';
import '../../../shared/widgets/scoreboard_header.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _cityCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _countryCtrl = TextEditingController(text: user?.country ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  String _getInitials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (image == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(authProvider.notifier).uploadAvatar(image.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile({
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEditing() {
    final user = ref.read(currentUserProvider);
    _firstNameCtrl.text = user?.firstName ?? '';
    _lastNameCtrl.text = user?.lastName ?? '';
    _emailCtrl.text = user?.email ?? '';
    _countryCtrl.text = user?.country ?? '';
    _cityCtrl.text = user?.city ?? '';
    setState(() => _isEditing = false);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
    } catch (_) {
      return 'Non disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Scoreboard header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ScoreboardHeader(
                title: 'Fiche Joueur',
                subtitle: 'Votre carte de joueur',
                icon: Icons.person_rounded,
              ),
            ),
            const SizedBox(height: 12),

            // Profile card
            _buildProfileCard(user),
            const SizedBox(height: 12),

            // Decorative separator
            Center(
              child: Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Personal info card
            _buildPersonalInfoCard(user),
            const SizedBox(height: 20),

            // Stats card
            _buildStatsCard(user),

            
          ]),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: [
        // Gradient banner with particles
        SizedBox(
          height: 80,
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                ),
              ),
              Positioned.fill(
                child: FloatingParticles(count: 4, color: AppColors.accent, maxSize: 4),
              ),
            ],
          ),
        ),

        // Avatar + info
        Transform.translate(
          offset: const Offset(0, -40),
          child: Column(children: [
            // Avatar
            GestureDetector(
              onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
              child: Stack(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    backgroundImage: (!_isUploadingAvatar && user.avatar != null && user.avatar!.isNotEmpty)
                        ? NetworkImage(
                            user.avatar!.startsWith('http')
                                ? user.avatar!
                                : '${ref.read(apiClientProvider).baseUrl}${user.avatar}',
                          )
                        : null,
                    child: _isUploadingAvatar
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : (user.avatar != null && user.avatar!.isNotEmpty)
                            ? null
                            : Text(
                                _getInitials(user.firstName, user.lastName),
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text('${user.firstName} ${user.lastName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textMutedLight)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user.isAdmin
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.shield_rounded, size: 14,
                    color: user.isAdmin ? const Color(0xFFD4AF37) : AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  user.isAdmin ? 'Administrateur' : 'Utilisateur',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: user.isAdmin ? const Color(0xFFD4AF37) : AppColors.primary,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            Text("Appuyez sur l'appareil photo pour changer votre photo",
                style: TextStyle(fontSize: 11, color: AppColors.textMutedLight.withValues(alpha: 0.7))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPersonalInfoCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Informations personnelles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Modifiez vos informations de profil',
                style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
          ])),
          TextButton(
            onPressed: _isEditing ? _cancelEditing : () => setState(() => _isEditing = true),
            child: Text(_isEditing ? 'Annuler' : 'Modifier',
                style: TextStyle(color: _isEditing ? AppColors.textMutedLight : AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 16),

        // Fields
        Row(children: [
          Expanded(child: _buildField(Icons.person_rounded, 'Prénom', _firstNameCtrl)),
          const SizedBox(width: 12),
          Expanded(child: _buildField(Icons.person_rounded, 'Nom', _lastNameCtrl)),
        ]),
        const SizedBox(height: 12),
        _buildField(Icons.email_rounded, 'Email', _emailCtrl, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildField(Icons.location_on_rounded, 'Pays', _countryCtrl, hint: 'Ex: France')),
          const SizedBox(width: 12),
          Expanded(child: _buildField(Icons.location_on_rounded, 'Ville', _cityCtrl, hint: 'Ex: Paris')),
        ]),

        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Member since
        Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMutedLight),
          const SizedBox(width: 8),
          const Text('Membre depuis', style: TextStyle(fontSize: 13, color: AppColors.textMutedLight)),
          const Spacer(),
          Text(_formatDate(user.createdAt), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),

        // Save button
        if (_isEditing) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildField(IconData icon, String label, TextEditingController controller,
      {TextInputType? keyboardType, String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: _isEditing
              ? (isDark ? AppColors.neutral800 : AppColors.neutral50)
              : (isDark ? AppColors.neutral800 : AppColors.neutral50).withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ]);
  }

  Widget _buildStatsCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Statistiques du Joueur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _buildStatTile(Icons.star_rounded, AppColors.accent, '${user.stars}', 'Étoiles')),
          const SizedBox(width: 10),
          Expanded(child: _buildStatTile(
            Icons.leaderboard_rounded,
            user.showInLeaderboard ? AppColors.primary : AppColors.textMutedLight,
            user.showInLeaderboard ? 'Visible' : 'Masqué',
            'Classement',
          )),
        ]),
      ]),
    );
  }

  Widget _buildStatTile(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
      ]),
    );
  }

}
