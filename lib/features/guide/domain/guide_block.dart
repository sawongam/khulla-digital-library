// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// One piece of an article.
///
/// The manual is written as data rather than as widgets so that a section can
/// be searched, counted and re-ordered without touching the rendering: the
/// guide's search walks every block's [searchText], and `GuideBlockView` is
/// the single switch that turns one into pixels.
sealed class GuideBlock {
  const GuideBlock();

  /// Everything in this block a reader might search for, lowercased by the
  /// search itself rather than here.
  String get searchText;
}

/// A paragraph of prose.
class GuideParagraph extends GuideBlock {
  const GuideParagraph(this.text);

  /// The sentence, already localized.
  final String text;

  @override
  String get searchText => text;
}

/// An ordered walkthrough: do this, then this.
///
/// Numbers come from position, never from the copy, so re-ordering or
/// translating a walkthrough can never leave a "3." above the second step.
class GuideSteps extends GuideBlock {
  const GuideSteps(this.steps);

  /// The steps, in the order they are done.
  final List<GuideStep> steps;

  @override
  String get searchText =>
      steps.map((step) => '${step.title} ${step.body}').join(' ');
}

/// One step of a [GuideSteps] walkthrough.
class GuideStep {
  const GuideStep({required this.title, required this.body, this.route});

  /// What the step accomplishes.
  final String title;

  /// What the operator actually does.
  final String body;

  /// The screen the step happens on, when there is one. Rendering it as a
  /// link is the difference between a manual and a manual you can follow
  /// without hunting the rail for the screen it just named.
  final String? route;
}

/// A short aside with a standing: a tip, a caution, a hard warning.
class GuideCallout extends GuideBlock {
  const GuideCallout({
    required this.tone,
    required this.title,
    required this.body,
  });

  /// How loudly it reads. [AppStatusTone.danger] is reserved for the things
  /// that lose records — restoring over a catalogue, resetting the database.
  final AppStatusTone tone;

  /// The one-line point.
  final String title;

  /// The explanation under it.
  final String body;

  @override
  String get searchText => '$title $body';
}

/// A vocabulary list: the words a screen uses and what they mean here.
///
/// Most of what confuses a new operator is not a button, it is a word — a
/// *title* is not a *copy*, a *hold* is not a *loan* — so the terms get a
/// block of their own rather than a parenthesis inside a paragraph.
class GuideTerms extends GuideBlock {
  const GuideTerms(this.terms);

  /// The entries, in the order they are met on the screen.
  final List<GuideTerm> terms;

  @override
  String get searchText =>
      terms.map((term) => '${term.term} ${term.meaning}').join(' ');
}

/// One entry of a [GuideTerms] list.
class GuideTerm {
  const GuideTerm(this.term, this.meaning);

  /// The word as the screen spells it.
  final String term;

  /// What it means in this app, in one sentence.
  final String meaning;
}

/// Questions the desk actually asks, each opening to its answer.
class GuideFaq extends GuideBlock {
  const GuideFaq(this.entries);

  /// The questions, most-asked first.
  final List<GuideFaqEntry> entries;

  @override
  String get searchText =>
      entries.map((entry) => '${entry.question} ${entry.answer}').join(' ');
}

/// One question and its answer.
class GuideFaqEntry {
  const GuideFaqEntry(this.question, this.answer);

  /// The question, as it would be asked out loud.
  final String question;

  /// The answer.
  final String answer;
}

/// A labelled diagram of the screen the section describes.
///
/// It is a drawing, not a screenshot: a screenshot goes stale the week the
/// button moves, ships as a light-mode PNG into a dark-mode window, and
/// cannot be translated. The mock is built from the same tokens the real
/// screen is, so it follows the theme, the density and the locale — and the
/// numbered markers on it are what the legend underneath refers to.
class GuideScreenshot extends GuideBlock {
  const GuideScreenshot({
    required this.caption,
    required this.parts,
    this.markers = const [],
  });

  /// What the reader is looking at.
  final String caption;

  /// The mock's body, top to bottom.
  final List<GuideMockPart> parts;

  /// The legend, in marker order: entry `i` explains marker `i + 1`.
  final List<String> markers;

  @override
  String get searchText => '$caption ${markers.join(' ')}';
}

/// One band of a [GuideScreenshot]'s body.
///
/// Every part carries an optional [marker]; a part that has one draws a
/// numbered chip on its leading edge, which is what ties the drawing to the
/// legend beneath it.
sealed class GuideMockPart {
  const GuideMockPart({this.marker});

  /// This part's number in the legend, counting from one. Null draws none.
  final int? marker;
}

/// The toolbar above a collection: a search field and one primary button.
class GuideMockToolbar extends GuideMockPart {
  const GuideMockToolbar({required this.search, this.action, super.marker});

  /// The search field's placeholder, as the real screen words it.
  final String search;

  /// The primary button's label, or null for a toolbar that only searches.
  final String? action;
}

/// A row of figure tiles — the dashboard's counts, a report's headline.
class GuideMockStats extends GuideMockPart {
  const GuideMockStats(this.labels, {super.marker});

  /// One label per tile. The figures themselves are drawn as bars, because a
  /// number invented for a drawing is a number somebody will quote back.
  final List<String> labels;
}

/// A table: a header row of column names over a few striped rows.
class GuideMockTable extends GuideMockPart {
  const GuideMockTable({
    required this.columns,
    this.rows = 4,
    this.tone,
    super.marker,
  });

  /// The column headers, left to right.
  final List<String> columns;

  /// How many body rows to draw.
  final int rows;

  /// Tints the last row — an overdue loan, a blocked member — so the section
  /// can point at what a status colour means without inventing a record.
  final AppStatusTone? tone;
}

/// A form: labelled fields over a submit button.
class GuideMockForm extends GuideMockPart {
  const GuideMockForm({required this.fields, this.submit, super.marker});

  /// The field labels, in tab order.
  final List<String> fields;

  /// The submit button's label, or null for a form drawn without one.
  final String? submit;
}

/// A list of records, each a leading disc and two lines of text.
class GuideMockList extends GuideMockPart {
  const GuideMockList({required this.rows, super.marker});

  /// How many rows to draw.
  final int rows;
}

/// A row of cards — the settings landing, a section's option tiles.
class GuideMockCards extends GuideMockPart {
  const GuideMockCards(this.labels, {super.marker});

  /// One label per card.
  final List<String> labels;
}
