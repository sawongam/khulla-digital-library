// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

/// Centralized route paths for the app router.
///
/// Navigate with `context.go(Routes.catalog)` — never a hard-coded string, so
/// renaming a path is a single edit and every caller moves with it.
///
/// Each shell section owns a small tree: the section's landing page at the
/// branch root, and its lists, records and editors nested underneath. The
/// nested form is deliberate — a detail page pushed under its list keeps the
/// back control working and leaves the shell's rail on screen, which is what
/// a desk tool wants.
///
/// Every nested path exists twice: once as a `*Segment` constant, which is
/// what a `GoRoute` inside a branch declares, and once as the full path a
/// caller navigates to. `AppRouter` uses the segments, everything else uses
/// the full paths.
abstract final class Routes {
  static const String root = '/';

  /// First-run setup. Reached only when the catalogue holds no staff account,
  /// and outside the shell — there is no library to navigate yet.
  static const String onboarding = '/onboarding';

  /// Staff sign-in. Outside the shell, for the same reason.
  static const String signIn = '/sign-in';

  /// Reset the first administrator password with a recovery code.
  static const String recoverPassword = '/recover-password';

  /// Whether [location] is one of the screens that live outside the shell.
  static bool isAuthLocation(String location) =>
      location == onboarding ||
      location == signIn ||
      location == recoverPassword;

  /// Dashboard: the shift's starting point — counts, activity, quick actions.
  static const String dashboard = '/dashboard';

  /// Catalogue: titles, copies, labels.
  static const String catalog = '/catalog';

  static const String titlesSegment = 'titles';
  static const String copiesSegment = 'copies';
  static const String idSegment = ':id';

  /// Every work the library holds.
  /// Label and barcode printing, under the catalogue.
  static const String labelsSegment = 'labels';

  static const String catalogTitles = '$catalog/$titlesSegment';

  /// Every physical item, across every title.
  static const String catalogCopies = '$catalog/$copiesSegment';

  /// The label and barcode desk.
  static const String catalogLabels = '$catalog/$labelsSegment';

  /// One title's record.
  static String catalogTitle(String id) => '$catalogTitles/$id';

  /// Circulation: checkouts, returns, reservations, overdues.
  static const String circulation = '/circulation';

  static const String loansSegment = 'loans';
  static const String checkOutSegment = 'check-out';
  static const String returnsSegment = 'return';
  static const String reservationsSegment = 'reservations';
  static const String finesSegment = 'fines';

  /// The circulation desk's landing page: open loans, headline counts,
  /// and links into the rest of the section.
  static const String circulationLoans = '$circulation/$loansSegment';

  /// The checkout desk.
  static const String circulationCheckOut = '$circulation/$checkOutSegment';

  /// The checkout desk with a member already looked up by card number.
  static String circulationCheckOutForMember(String cardNumber) =>
      '$circulationCheckOut?card=${Uri.encodeComponent(cardNumber)}';

  /// The returns desk.
  static const String circulationReturn = '$circulation/$returnsSegment';

  /// The hold queue.
  static const String circulationReservations =
      '$circulation/$reservationsSegment';

  /// The fines ledger.
  static const String circulationFines = '$circulation/$finesSegment';

  /// Members: borrower records and their standing.

  /// Reports and statistics.
  static const String reports = '/reports';

  /// Staff accounts and the roles they hold.
  static const String users = '/users';

  /// The role and permission matrix, under staff.
  static const String rolesSegment = 'roles';

  /// The role list.
  static const String usersRoles = '$users/$rolesSegment';

  static const String members = '/members';

  /// One borrower's record.
  static String member(String id) => '$members/$id';

  /// The manual: one article per section of the app.
  static const String guide = '/guide';

  /// A guide article, addressed by its topic slug.
  static const String guideTopicSegment = ':topic';

  /// One topic's article.
  static String guideTopic(String slug) => '$guide/$slug';

  /// Settings: library profile, loan rules, backup, appearance.
  static const String settings = '/settings';

  static const String librarySegment = 'library';
  static const String loanRulesSegment = 'loan-rules';
  static const String appearanceSegment = 'appearance';
  static const String backupSegment = 'backup';

  /// The component gallery, under settings. Registered by the dev build only.
  static const String designSystemSegment = 'design-system';

  /// Library profile — name, branch, contact, currency.
  static const String settingsLibrary = '$settings/$librarySegment';

  /// Loan periods, renewals, limits and fine rates.
  static const String settingsLoanRules = '$settings/$loanRulesSegment';

  /// Theme for this device.
  static const String settingsAppearance = '$settings/$appearanceSegment';

  /// Export, restore, import, and the destructive reset.
  static const String settingsBackup = '$settings/$backupSegment';

  /// The design-system gallery. Only reachable in the dev flavor — the
  /// release build declares neither the route nor the door to it.
  static const String settingsDesignSystem = '$settings/$designSystemSegment';

  /// Whether [location] is [prefix] or nested under it.
  static bool isUnder(String location, String prefix) =>
      location == prefix || location.startsWith('$prefix/');
}
