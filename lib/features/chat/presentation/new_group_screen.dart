import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/group_chat_repository.dart';
import 'group_chat_screen.dart';

/// Yangi guruh chati yaratish ekrani — `NewEventScreen` bilan bir xil
/// to'liq-ekran naqsh: yuqorida orqaga tugma + sarlavha, pastda
/// `ListView` ichida forma, oxirida asosiy tugma.
///
/// A'zolar mahalla qo'shnilari ro'yxatidan (`neighborsProvider`)
/// tanlanadi — o'zini bloklaganlar va o'zi allaqachon chiqarib
/// tashlangan (mavjud "Qo'shnilar" ekrani bilan bir xil ro'yxat).
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedUids = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppAlert(context, l10n.enterGroupNameError, kind: AppAlertKind.error);
      return;
    }
    if (_selectedUids.isEmpty) {
      showAppAlert(context, l10n.selectAtLeastOneMemberError,
          kind: AppAlertKind.error);
      return;
    }
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final mahallaId =
        ref.read(currentUserProfileProvider).valueOrNull?.mahallaId;
    if (myUid == null || mahallaId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final groupId = await ref.read(groupChatRepositoryProvider).createGroup(
            mahallaId: mahallaId,
            name: name,
            participantUids: _selectedUids.toList(),
            createdBy: myUid,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: groupId)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, l10n.groupCreateError,
          kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mahallaId =
        ref.watch(currentUserProfileProvider).valueOrNull?.mahallaId;
    final neighborsAsync = mahallaId == null
        ? const AsyncValue<List<MahallaMember>>.data([])
        : ref.watch(neighborsProvider(mahallaId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  const LiquidGlassBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.createGroupAction, style: context.titleStyle),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                children: [
                  Text(l10n.groupNameLabel, style: context.captionStyle),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: l10n.groupNameHint),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _selectedUids.isEmpty
                        ? l10n.selectMembersLabel
                        : l10n.selectMembersLabelWithCount(_selectedUids.length),
                    style: context.captionStyle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  neighborsAsync.when(
                    data: (members) {
                      if (members.isEmpty) {
                        return AppEmptyView(
                          icon: PhosphorIconsFill.usersThree,
                          title: l10n.noConversationsYet,
                        );
                      }
                      return Column(
                        children: members.map((member) {
                          final isSelected = _selectedUids.contains(member.uid);
                          final fullName =
                              '${member.firstName} ${member.lastName}'.trim();
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: InkWell(
                              borderRadius: AppRadius.smAll,
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selectedUids.remove(member.uid);
                                } else {
                                  _selectedUids.add(member.uid);
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : context.borderColor,
                                  ),
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      size: 40,
                                      firstName: member.firstName,
                                      lastName: member.lastName,
                                      photoUrl: member.photoUrl,
                                      seed: member.uid,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        fullName,
                                        style: context.bodyStyle,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? PhosphorIconsFill.checkCircle
                                          : PhosphorIconsRegular.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : context.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const ShimmerList(count: 4),
                    error: (_, __) => Center(
                      child: Text(l10n.unexpectedError,
                          style: context.secondaryStyle),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(l10n.createGroupAction),
                    ),
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
