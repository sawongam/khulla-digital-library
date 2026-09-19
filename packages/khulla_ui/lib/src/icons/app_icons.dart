// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/src/icons/app_icon_spec.dart';
import 'package:solar_iconkit/solar_iconkit.dart';

/// The app's icon catalog.
///
/// Every icon in Khulla is named here and drawn with `AppIcon`. Material's
/// `Icons` and Cupertino's `CupertinoIcons` are **banned** - see `DESIGN.md`.
/// Two reasons:
///
/// * A central catalog is what keeps "delete" the same glyph on the copy list,
///   in the fine sheet and in the confirm dialog.
/// * A Material icon carries Material's drawing style. Solar's outline weight
///   pairs with the app's type and spacing; the Material set does not.
///
/// ## One weight: `outline`
///
/// Every icon here is [SolarIconStyle.outline], and nothing in the app uses
/// `bold` or either duotone. Solar's bold style is a solid silhouette - next
/// to this app's hairline borders and `w500` type it reads as a different,
/// heavier product. Selection and active state are carried by **color** and by
/// the surface underneath the icon, never by swapping in a filled glyph. Do
/// not add a `bold` constant here; if a state is not reading as selected, the
/// fix is contrast, not weight.
///
/// Names are semantic, not Solar names: a call site says [delete], not
/// `'trash-bin-minimalistic'`. Two names may share a glyph - [warning] and
/// [damage] are different meanings that happen to look alike today, and
/// keeping them separate is what lets one change without the other.
///
/// Adding an icon: pick a name from <https://solar-icons-web.vercel.app>, add
/// a constant here with a doc comment saying what it *means*, and use it.
/// Never inline an [AppIconSpec] at a call site - the catalog is the point.
abstract final class AppIcons {
  // ---------------------------------------------------------------- direction

  /// Trailing disclosure chevron on a row or tile.
  static const AppIconSpec chevronRight = AppIconSpec(SolarIcons.altArrowRight);

  /// Leading back chevron.
  static const AppIconSpec chevronLeft = AppIconSpec(SolarIcons.altArrowLeft);

  /// Expand/collapse chevron on a section or a dropdown.
  static const AppIconSpec chevronDown = AppIconSpec(SolarIcons.altArrowDown);

  /// Sort indicator, ascending.
  static const AppIconSpec caretUp = AppIconSpec(SolarIcons.altArrowUp);

  /// Sort indicator, descending.
  static const AppIconSpec caretDown = AppIconSpec(SolarIcons.altArrowDown);

  /// A value that rose since the last period.
  static const AppIconSpec arrowUp = AppIconSpec(SolarIcons.arrowUp);

  /// A value that fell since the last period.
  static const AppIconSpec arrowDown = AppIconSpec(SolarIcons.arrowDown);

  /// Forward, on a step or a "continue" affordance.
  static const AppIconSpec arrowRight = AppIconSpec(SolarIcons.arrowRight);

  /// A row nested under the one above it.
  static const AppIconSpec subEntry = AppIconSpec(SolarIcons.arrowRightDown);

  /// Opens somewhere outside the app.
  static const AppIconSpec openExternal = AppIconSpec(SolarIcons.arrowRightUp);

  // ------------------------------------------------------------------ actions

  /// Create a record.
  static const AppIconSpec add = AppIconSpec(SolarIcons.add);

  /// Create, where the affordance is a standalone circular button.
  static const AppIconSpec addCircle = AppIconSpec(SolarIcons.addCircle);

  /// Take one away from a count.
  static const AppIconSpec remove = AppIconSpec(SolarIcons.minus);

  /// Edit a record.
  static const AppIconSpec edit = AppIconSpec(SolarIcons.pen2);

  /// Delete a record, recoverably.
  static const AppIconSpec delete = AppIconSpec(
    SolarIcons.trashBinMinimalistic,
  );

  /// Delete for good - the confirm on a destructive, unrecoverable action.
  static const AppIconSpec deleteForever = AppIconSpec(
    SolarIcons.trashBinMinimalistic2,
  );

  /// Dismiss a sheet, dialog, chip or banner.
  static const AppIconSpec close = AppIconSpec(SolarIcons.close);

  /// Confirm a choice - the tick beside a selected menu row.
  static const AppIconSpec check = AppIconSpec(SolarIcons.checkCircle);

  /// Re-run the query behind the screen.
  static const AppIconSpec refresh = AppIconSpec(SolarIcons.refresh);

  /// Renew a loan, or any repeat of something already done.
  static const AppIconSpec renew = AppIconSpec(SolarIcons.restart);

  /// Put a record back the way it was.
  static const AppIconSpec restore = AppIconSpec(SolarIcons.history);

  /// Overflow menu.
  static const AppIconSpec more = AppIconSpec(SolarIcons.menuDots);

  /// Send a record to the printer.
  static const AppIconSpec printer = AppIconSpec(SolarIcons.printer);

  /// Pull data out of the app.
  static const AppIconSpec download = AppIconSpec(SolarIcons.download);

  /// Copy text to the clipboard.
  static const AppIconSpec copy = AppIconSpec(SolarIcons.copy);

  /// Push data into the app.
  static const AppIconSpec upload = AppIconSpec(SolarIcons.upload);

  /// Look at a record without opening it for editing.
  static const AppIconSpec preview = AppIconSpec(SolarIcons.eye);

  /// Search.
  static const AppIconSpec search = AppIconSpec(SolarIcons.magnifier);

  /// A search that matched nothing - the empty state, not the field.
  static const AppIconSpec noResults = AppIconSpec(SolarIcons.magnifierBug);

  /// Browse the whole catalogue rather than searching it.
  static const AppIconSpec discover = AppIconSpec(SolarIcons.globe);

  // ---------------------------------------------------------------- catalogue

  /// A title in the catalogue.
  static const AppIconSpec book = AppIconSpec(SolarIcons.book2);

  /// A title being read - reading history, an issued copy.
  static const AppIconSpec openBook = AppIconSpec(SolarIcons.book);

  /// Add a title to the catalogue.
  static const AppIconSpec addToCatalog = AppIconSpec(SolarIcons.addSquare);

  /// The library itself, as a place.
  static const AppIconSpec library = AppIconSpec(SolarIcons.libraryIcon);

  /// Saved for later.
  static const AppIconSpec bookmark = AppIconSpec(SolarIcons.bookmark);

  /// Save this for later.
  static const AppIconSpec addBookmark = AppIconSpec(SolarIcons.bookmarkOpened);

  /// Physical copies on the shelf.
  static const AppIconSpec inventory = AppIconSpec(SolarIcons.box);

  /// A copy's barcode.
  static const AppIconSpec barcode = AppIconSpec(SolarIcons.barcode);

  /// A copy's QR label.
  static const AppIconSpec qrCode = AppIconSpec(SolarIcons.qrCode);

  /// Read a barcode or QR label with a scanner.
  static const AppIconSpec scan = AppIconSpec(SolarIcons.codeScan);

  /// Many barcodes entered at once, typed or pasted.
  static const AppIconSpec bulkEntry = AppIconSpec(SolarIcons.clipboardList);

  /// A written piece - an article, a periodical entry.
  static const AppIconSpec article = AppIconSpec(SolarIcons.documentText);

  /// An audio item in the catalogue.
  static const AppIconSpec audio = AppIconSpec(SolarIcons.headphonesRound);

  /// A video item in the catalogue.
  static const AppIconSpec video = AppIconSpec(SolarIcons.clapperboardPlay);

  /// An exported or attached PDF.
  static const AppIconSpec pdf = AppIconSpec(SolarIcons.fileText);

  // -------------------------------------------------------------- circulation

  /// A copy leaving the desk.
  static const AppIconSpec checkOut = AppIconSpec(SolarIcons.inboxOut);

  /// A copy coming back to the desk.
  static const AppIconSpec checkIn = AppIconSpec(SolarIcons.inboxIn);

  /// A loan that has been returned and closed.
  static const AppIconSpec returned = AppIconSpec(SolarIcons.clipboardCheck);

  /// A copy moving between branches.
  static const AppIconSpec transfer = AppIconSpec(
    SolarIcons.transferHorizontal,
  );

  /// A copy in transit.
  static const AppIconSpec delivery = AppIconSpec(SolarIcons.delivery);

  /// A due date.
  static const AppIconSpec calendar = AppIconSpec(SolarIcons.calendar);

  /// A dated event on the calendar.
  static const AppIconSpec event = AppIconSpec(SolarIcons.calendarMark);

  /// Time - a loan period, an overdue count.
  static const AppIconSpec clock = AppIconSpec(SolarIcons.clockCircle);

  // -------------------------------------------------------------------- money

  /// An amount owed or held.
  static const AppIconSpec wallet = AppIconSpec(SolarIcons.wallet);

  /// A payment taken at the desk.
  static const AppIconSpec payment = AppIconSpec(SolarIcons.banknote2);

  /// A fine written off.
  static const AppIconSpec waiveFine = AppIconSpec(SolarIcons.billCross);

  // ------------------------------------------------------------------- people

  /// One member or staff account.
  static const AppIconSpec person = AppIconSpec(SolarIcons.user);

  /// A group of members.
  static const AppIconSpec people = AppIconSpec(SolarIcons.usersGroupRounded);

  static const AppIconSpec bookBookmark = AppIconSpec(
    SolarIcons.bookmarkSquare,
  );

  /// Enrol someone new.
  static const AppIconSpec addPerson = AppIconSpec(SolarIcons.userPlusRounded);

  /// A member's card or a staff badge.
  static const AppIconSpec idCard = AppIconSpec(SolarIcons.userId);

  /// A membership tier or plan.
  static const AppIconSpec membership = AppIconSpec(SolarIcons.cardholder);

  /// A member barred from borrowing.
  static const AppIconSpec blocked = AppIconSpec(SolarIcons.forbiddenCircle);

  /// A staff account with administrative rights.
  static const AppIconSpec admin = AppIconSpec(SolarIcons.shieldUser);

  /// A member enrolled as a teacher.
  static const AppIconSpec teacher = AppIconSpec(SolarIcons.userSpeakRounded);

  /// A member enrolled as a child.
  static const AppIconSpec child = AppIconSpec(SolarIcons.smileCircle);

  /// A member enrolled as a student.
  static const AppIconSpec education = AppIconSpec(SolarIcons.diploma);

  /// Contact a member by email.
  static const AppIconSpec email = AppIconSpec(SolarIcons.letter);

  /// End the session.
  static const AppIconSpec signOut = AppIconSpec(SolarIcons.logout2);

  /// Reveal what a password field is masking.
  static const AppIconSpec revealPassword = AppIconSpec(SolarIcons.eye);

  /// Mask a revealed password field again.
  static const AppIconSpec hidePassword = AppIconSpec(SolarIcons.eyeClosed);

  /// Send a staff member a new password.
  static const AppIconSpec resetPassword = AppIconSpec(SolarIcons.lockPassword);

  // --------------------------------------------------------------- navigation

  /// The dashboard section.
  static const AppIconSpec dashboard = AppIconSpec(SolarIcons.widget);

  /// The reports section, and a trend chart inside it.
  static const AppIconSpec insights = AppIconSpec(SolarIcons.graphUp);

  /// The settings section.
  static const AppIconSpec settings = AppIconSpec(SolarIcons.settings);

  static const AppIconSpec options = AppIconSpec(SolarIcons.menuDotsSquare);

  /// Notifications, none waiting.
  static const AppIconSpec notifications = AppIconSpec(SolarIcons.bell);

  /// Notifications with something waiting.
  static const AppIconSpec notificationsActive = AppIconSpec(
    SolarIcons.bellRing,
  );

  /// Switch a list to a card grid.
  static const AppIconSpec gridView = AppIconSpec(SolarIcons.widget5);

  /// Switch a list to a table.
  static const AppIconSpec tableView = AppIconSpec(SolarIcons.list);

  /// An unfilled bullet - an unselected row marker.
  static const AppIconSpec circle = AppIconSpec(SolarIcons.recordCircle);

  // -------------------------------------------------------------------- state

  /// Something went wrong and the screen has nothing to show.
  static const AppIconSpec error = AppIconSpec(SolarIcons.dangerCircle);

  /// A caution the operator can proceed past.
  static const AppIconSpec warning = AppIconSpec(SolarIcons.dangerTriangle);

  /// A damaged copy.
  static const AppIconSpec damage = AppIconSpec(SolarIcons.dangerSquare);

  /// The action completed.
  static const AppIconSpec success = AppIconSpec(SolarIcons.checkCircle);

  /// An aside the operator may want but does not have to read.
  static const AppIconSpec info = AppIconSpec(SolarIcons.infoCircle);

  /// Documentation or a hint.
  static const AppIconSpec help = AppIconSpec(SolarIcons.questionCircle);

  // ----------------------------------------------------------------- settings

  /// Theme and colour settings.
  static const AppIconSpec appearance = AppIconSpec(SolarIcons.palette);

  /// The light theme.
  static const AppIconSpec lightMode = AppIconSpec(SolarIcons.sun2);

  /// The dark theme.
  static const AppIconSpec darkMode = AppIconSpec(SolarIcons.moon);

  /// Follow the operating system's theme.
  static const AppIconSpec systemMode = AppIconSpec(SolarIcons.devices);

  /// Design-system settings and the component gallery.
  static const AppIconSpec design = AppIconSpec(SolarIcons.rulerPen);

  /// Permissions and access control.
  static const AppIconSpec security = AppIconSpec(SolarIcons.shield);

  /// Data handling and retention.
  static const AppIconSpec privacy = AppIconSpec(SolarIcons.shieldKeyhole);

  /// Circulation rules and policies.
  static const AppIconSpec rules = AppIconSpec(
    SolarIcons.checklistMinimalistic,
  );

  /// Copy the catalogue somewhere safe.
  static const AppIconSpec backup = AppIconSpec(SolarIcons.cloudUpload);

  /// A backup that is safely stored.
  static const AppIconSpec cloudDone = AppIconSpec(SolarIcons.cloudCheck);

  /// No backup destination is reachable.
  static const AppIconSpec cloudOff = AppIconSpec(SolarIcons.cloudCross);

  /// The devices this install runs on.
  static const AppIconSpec devices = AppIconSpec(SolarIcons.devices);

  /// This machine.
  static const AppIconSpec desktop = AppIconSpec(SolarIcons.monitor);

  /// Reach the people who maintain the app.
  static const AppIconSpec support = AppIconSpec(SolarIcons.headphonesRound);
}
