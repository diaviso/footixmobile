import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/duel_provider.dart';
import '../../../navigation/app_router.dart';

class DuelLobbyScreen extends ConsumerStatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  ConsumerState<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends ConsumerState<DuelLobbyScreen> {
  bool _copied = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _invitingUserId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activeDuelProvider.notifier).startPolling(
        onUpdate: (duel) {
          if (duel.status == 'PLAYING' && mounted) {
            context.go(AppRoutes.duelPlay);
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Don't stop polling here — the play screen may pick it up
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    final results = await ref.read(activeDuelProvider.notifier).searchUsers(query);
    if (!mounted) return;
    final duel = ref.read(activeDuelProvider).duel;
    final participantIds = duel?.participants.map((p) => p.id).toSet() ?? {};
    setState(() {
      _searchResults = results.where((u) => !participantIds.contains(u['id'])).toList();
      _isSearching = false;
    });
  }

  Future<void> _inviteUser(String userId) async {
    setState(() => _invitingUserId = userId);
    final ok = await ref.read(activeDuelProvider.notifier).inviteUser(userId);
    if (!mounted) return;
    setState(() => _invitingUserId = null);
    if (ok) {
      _searchController.clear();
      setState(() => _searchResults = []);
    }
  }

  void _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duelState = ref.watch(activeDuelProvider);
    final duel = duelState.duel;

    if (duel == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isFull = duel.participants.length >= duel.maxParticipants;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Salon de Duel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(activeDuelProvider.notifier).stopPolling();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Code display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'CODE DU SALON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        duel.code,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 8,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _copyCode(duel.code),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                            key: ValueKey(_copied),
                            size: 22,
                            color: _copied ? AppColors.success : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Partagez ce code avec les autres joueurs',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Invite a player — only for creator when not full
            if (duel.isCreator && !isFull) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    const SizedBox(width: 8),
                    Text(
                      'Inviter un joueur',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou email...',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Column(
                    children: _searchResults.map((u) {
                      final uid = u['id'] as String;
                      final firstName = u['firstName'] as String? ?? '';
                      final lastName = u['lastName'] as String? ?? '';
                      final email = u['email'] as String? ?? '';
                      final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                        title: Text('$firstName $lastName', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        subtitle: Text(email, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                        trailing: SizedBox(
                          width: 80,
                          height: 30,
                          child: ElevatedButton(
                            onPressed: _invitingUserId == uid ? null : () => _inviteUser(uid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: _invitingUserId == uid
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Inviter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (_searchController.text.length >= 2 && !_isSearching && _searchResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Aucun joueur trouvé',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Participants
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.people_rounded, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  const SizedBox(width: 8),
                  Text(
                    'Participants (${duel.participants.length}/${duel.maxParticipants})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Participant tiles
            ...duel.participants.asMap().entries.map((entry) => _ParticipantTile(
              index: entry.key + 1,
              name: '${entry.value.firstName} ${entry.value.lastName}',
              initials: '${entry.value.firstName.isNotEmpty ? entry.value.firstName[0] : ''}${entry.value.lastName.isNotEmpty ? entry.value.lastName[0] : ''}',
              isCreator: entry.value.id == duel.creatorId,
              isReady: true,
            )),

            // Empty slots
            ...List.generate(duel.maxParticipants - duel.participants.length, (i) => _EmptySlot()),

            const SizedBox(height: 24),

            // Status message
            if (duel.isCreator && isFull)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: duelState.isLoading
                      ? null
                      : () async {
                          final ok = await ref.read(activeDuelProvider.notifier).launchDuel();
                          if (ok && mounted) {
                            context.go(AppRoutes.duelPlay);
                          }
                        },
                  icon: duelState.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Lancer le duel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary.withValues(alpha: 0.06),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        duel.isCreator
                            ? 'En attente des participants...'
                            : (isFull ? 'En attente du lancement...' : 'En attente des joueurs...'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (duelState.error != null) ...[
              const SizedBox(height: 12),
              Text(duelState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],

            const SizedBox(height: 16),

            // Leave button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: duelState.isLoading
                    ? null
                    : () async {
                        final ok = await ref.read(activeDuelProvider.notifier).leaveDuel();
                        if (ok && mounted) {
                          ref.read(duelListProvider.notifier).loadDuels();
                          context.pop();
                        }
                      },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Quitter le salon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final int index;
  final String name;
  final String initials;
  final bool isCreator;
  final bool isReady;

  const _ParticipantTile({
    required this.index,
    required this.name,
    required this.initials,
    required this.isCreator,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppColors.neutral800 : AppColors.neutral100,
      ),
      child: Row(
        children: [
          // Jersey number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), width: 1),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                if (isCreator) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Créateur',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.neutral800 : AppColors.neutral100,
            ),
            child: Icon(Icons.schedule_rounded, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ),
          const SizedBox(width: 12),
          Text(
            'En attente d\'un joueur...',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
