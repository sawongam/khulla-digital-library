// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/error/app_error_reason.dart';
import 'package:khulla/l10n/l10n.dart';

/// The sentence a librarian reads for each rule that can refuse an action.
///
/// Exhaustive on purpose: a new [AppErrorReason] does not compile until it
/// has copy here, so no refusal can quietly fall back to "that action
/// conflicts with the current record".
extension AppErrorReasonL10n on AppErrorReason {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    AppErrorReason.copyNotFound => l10n.errorReasonCopyNotFound,
    AppErrorReason.titleNotFound => l10n.errorReasonTitleNotFound,
    AppErrorReason.memberNotFound => l10n.errorReasonMemberNotFound,
    AppErrorReason.memberTypeNotFound => l10n.errorReasonMemberTypeNotFound,
    AppErrorReason.loanNotFound => l10n.errorReasonLoanNotFound,
    AppErrorReason.fineNotFound => l10n.errorReasonFineNotFound,
    AppErrorReason.holdNotFound => l10n.errorReasonHoldNotFound,
    AppErrorReason.staffNotFound => l10n.errorReasonStaffNotFound,
    AppErrorReason.loanRulesMissing => l10n.errorReasonLoanRulesMissing,
    AppErrorReason.copyNotOnLoan => l10n.errorReasonCopyNotOnLoan,
    AppErrorReason.copyHasNoBarcode => l10n.errorReasonCopyHasNoBarcode,
    AppErrorReason.memberArchived => l10n.errorReasonMemberArchived,
    AppErrorReason.memberSuspended => l10n.errorReasonMemberSuspended,
    AppErrorReason.membershipExpired => l10n.errorReasonMembershipExpired,
    AppErrorReason.membershipAlreadySuspended =>
      l10n.errorReasonMembershipAlreadySuspended,
    AppErrorReason.membershipNotSuspended =>
      l10n.errorReasonMembershipNotSuspended,
    AppErrorReason.memberHasHistory => l10n.errorReasonMemberHasHistory,
    AppErrorReason.copyArchived => l10n.errorReasonCopyArchived,
    AppErrorReason.titleArchived => l10n.errorReasonTitleArchived,
    AppErrorReason.titleNotLendable => l10n.errorReasonTitleNotLendable,
    AppErrorReason.copyReservedForAnotherMember =>
      l10n.errorReasonCopyReservedForAnotherMember,
    AppErrorReason.copyNotAvailable => l10n.errorReasonCopyNotAvailable,
    AppErrorReason.borrowingLimitReached =>
      l10n.errorReasonBorrowingLimitReached,
    AppErrorReason.memberHasOverdueLoans =>
      l10n.errorReasonMemberHasOverdueLoans,
    AppErrorReason.outstandingFinesTooHigh =>
      l10n.errorReasonOutstandingFinesTooHigh,
    AppErrorReason.earlierHoldOnTitle => l10n.errorReasonEarlierHoldOnTitle,
    AppErrorReason.copyAlreadyInBasket => l10n.errorReasonCopyAlreadyInBasket,
    AppErrorReason.chooseMemberFirst => l10n.errorReasonChooseMemberFirst,
    AppErrorReason.chooseTitleFirst => l10n.errorReasonChooseTitleFirst,
    AppErrorReason.dateOfBirthUnreadable =>
      l10n.errorReasonDateOfBirthUnreadable,
    AppErrorReason.loanAlreadyReturned => l10n.errorReasonLoanAlreadyReturned,
    AppErrorReason.renewalLimitReached => l10n.errorReasonRenewalLimitReached,
    AppErrorReason.holdBlocksRenewal => l10n.errorReasonHoldBlocksRenewal,
    AppErrorReason.holdLimitReached => l10n.errorReasonHoldLimitReached,
    AppErrorReason.holdNotWaiting => l10n.errorReasonHoldNotWaiting,
    AppErrorReason.noCopyForHold => l10n.errorReasonNoCopyForHold,
    AppErrorReason.fineAlreadySettled => l10n.errorReasonFineAlreadySettled,
    AppErrorReason.fineAmountNotPositive =>
      l10n.errorReasonFineAmountNotPositive,
    AppErrorReason.copyOnLoan => l10n.errorReasonCopyOnLoan,
    AppErrorReason.copyHeldForReservation =>
      l10n.errorReasonCopyHeldForReservation,
    AppErrorReason.titleHasCopies => l10n.errorReasonTitleHasCopies,
    AppErrorReason.cannotChangeOwnRole => l10n.errorReasonCannotChangeOwnRole,
    AppErrorReason.cannotDisableOwnAccount => l10n.usersSelfDisableError,
    AppErrorReason.lastActiveAdministrator => l10n.usersLastAdministratorError,
    AppErrorReason.recoveryCodeUsed => l10n.errorReasonRecoveryCodeUsed,
    AppErrorReason.passwordTooLong => l10n.errorReasonPasswordTooLong,
    AppErrorReason.labelSheetPrintFailed =>
      l10n.errorReasonLabelSheetPrintFailed,
    AppErrorReason.notABackup => l10n.errorReasonNotABackup,
    AppErrorReason.backupVersionMismatch =>
      l10n.errorReasonBackupVersionMismatch,
    AppErrorReason.backupFromNewerVersion =>
      l10n.errorReasonBackupFromNewerVersion,
    AppErrorReason.backupDamaged => l10n.errorReasonBackupDamaged,
    AppErrorReason.restoreNotApplied => l10n.errorReasonRestoreNotApplied,
  };
}
