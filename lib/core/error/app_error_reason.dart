// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Why a rule refused an action - the specific half of an `AppException`.
///
/// The exception's type says what kind of failure it was (not found, a
/// conflict, bad input); the reason says which rule fired. A desk that is
/// told only "that action conflicts with the current record" cannot tell a
/// borrowing limit from an overdue loan from an earlier hold, so every rule
/// a librarian can trip carries one of these, and
/// `AppErrorReasonL10n.localizedMessage` gives each its own sentence.
///
/// The l10n mapping is an exhaustive switch: a reason added here does not
/// compile until it has copy.
enum AppErrorReason {
  // Records that were looked up and are not there.
  copyNotFound,
  titleNotFound,
  memberNotFound,
  memberTypeNotFound,
  loanNotFound,
  fineNotFound,
  holdNotFound,
  staffNotFound,
  loanRulesMissing,
  copyNotOnLoan,
  copyHasNoBarcode,

  // A member's standing.
  memberArchived,
  memberSuspended,
  membershipExpired,
  membershipAlreadySuspended,
  membershipNotSuspended,
  memberHasHistory,

  // Check-out.
  copyArchived,
  titleArchived,
  titleNotLendable,
  copyReservedForAnotherMember,
  copyNotAvailable,
  borrowingLimitReached,
  memberHasOverdueLoans,
  outstandingFinesTooHigh,
  earlierHoldOnTitle,
  copyAlreadyInBasket,

  // Forms submitted before a required choice was made.
  chooseMemberFirst,
  chooseTitleFirst,
  dateOfBirthUnreadable,

  // Renewal.
  loanAlreadyReturned,
  renewalLimitReached,
  holdBlocksRenewal,

  // Holds.
  holdLimitReached,
  holdNotWaiting,
  noCopyForHold,

  // Fines.
  fineAlreadySettled,
  fineAmountNotPositive,

  // Catalogue.
  copyOnLoan,
  copyHeldForReservation,
  titleHasCopies,

  // Staff accounts.
  cannotChangeOwnRole,
  cannotDisableOwnAccount,
  lastActiveAdministrator,
  recoveryCodeUsed,
  passwordTooLong,

  // Files.
  labelSheetPrintFailed,

  // Backups.
  notABackup,
  backupVersionMismatch,
  backupFromNewerVersion,
  backupDamaged,
  restoreNotApplied,
}
