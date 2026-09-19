// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/guide/domain/guide_article.dart';
import 'package:khulla/features/guide/domain/guide_block.dart';
import 'package:khulla/features/guide/domain/guide_topic.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The manual, as data.
///
/// Every article is built here from [AppLocalizations], which is what keeps
/// the guide translatable: a page that wrote its own prose would be English
/// forever, and a Nepali desk would be reading an English manual about a
/// Nepali screen.
///
/// It is a plain function rather than a cubit because nothing here is read
/// from anywhere - there is no query behind the guide, so there is no
/// loading state, no failure, and nothing to hold between builds.
List<GuideArticle> guideArticles(AppLocalizations l10n) => [
  _gettingStarted(l10n),
  _dashboard(l10n),
  _catalog(l10n),
  _circulation(l10n),
  _members(l10n),
  _reports(l10n),
  _staff(l10n),
  _settings(l10n),
];

/// The article for [topic].
GuideArticle guideArticleFor(AppLocalizations l10n, GuideTopic topic) =>
    guideArticles(l10n).firstWhere((article) => article.topic == topic);

/// The walkthrough the guide's landing page shows above everything else.
///
/// It is the first article's first block, taken from the same source rather
/// than written twice: the landing page's "start here" strip and the
/// getting-started article can never drift apart.
GuideSteps guideQuickStart(AppLocalizations l10n) =>
    _gettingStarted(l10n).sections.first.blocks.whereType<GuideSteps>().first;

GuideArticle _gettingStarted(AppLocalizations l10n) => GuideArticle(
  topic: GuideTopic.gettingStarted,
  title: l10n.guideGettingStartedTitle,
  summary: l10n.guideGettingStartedSummary,
  sections: [
    GuideSection(
      anchor: 'first-hour',
      title: l10n.guideGettingStartedSetupHeading,
      blocks: [
        GuideParagraph(l10n.guideGettingStartedSetupBody),
        GuideSteps([
          GuideStep(
            title: l10n.helpGuideStep1Title,
            body: l10n.helpGuideStep1Body,
            route: Routes.settingsLibrary,
          ),
          GuideStep(
            title: l10n.helpGuideStep2Title,
            body: l10n.helpGuideStep2Body,
            route: Routes.users,
          ),
          GuideStep(
            title: l10n.helpGuideStep3Title,
            body: l10n.helpGuideStep3Body,
            route: Routes.catalogTitles,
          ),
          GuideStep(
            title: l10n.helpGuideStep4Title,
            body: l10n.helpGuideStep4Body,
            route: Routes.catalogLabels,
          ),
          GuideStep(
            title: l10n.helpGuideStep5Title,
            body: l10n.helpGuideStep5Body,
            route: Routes.members,
          ),
          GuideStep(
            title: l10n.helpGuideStep6Title,
            body: l10n.helpGuideStep6Body,
            route: Routes.circulationCheckOut,
          ),
          GuideStep(
            title: l10n.helpGuideStep7Title,
            body: l10n.helpGuideStep7Body,
            route: Routes.reports,
          ),
          GuideStep(
            title: l10n.helpGuideStep8Title,
            body: l10n.helpGuideStep8Body,
            route: Routes.settingsBackup,
          ),
        ]),
        GuideCallout(
          tone: AppStatusTone.info,
          title: l10n.guideGettingStartedOrderTitle,
          body: l10n.guideGettingStartedOrderBody,
        ),
      ],
    ),
    GuideSection(
      anchor: 'how-it-works',
      title: l10n.guideGettingStartedModelHeading,
      blocks: [
        GuideParagraph(l10n.guideGettingStartedModelBody),
        GuideTerms([
          GuideTerm(
            l10n.guideTermLocalFirst,
            l10n.guideTermLocalFirstMeaning,
          ),
          GuideTerm(l10n.guideTermTitle, l10n.guideTermTitleMeaning),
          GuideTerm(l10n.guideTermCopy, l10n.guideTermCopyMeaning),
          GuideTerm(l10n.guideTermMember, l10n.guideTermMemberMeaning),
          GuideTerm(l10n.guideTermLoan, l10n.guideTermLoanMeaning),
          GuideTerm(l10n.guideTermHold, l10n.guideTermHoldMeaning),
        ]),
        GuideCallout(
          tone: AppStatusTone.warning,
          title: l10n.guideGettingStartedBackupTitle,
          body: l10n.guideGettingStartedBackupBody,
        ),
      ],
    ),
    GuideSection(
      anchor: 'daily-rhythm',
      title: l10n.guideGettingStartedDayHeading,
      blocks: [
        GuideParagraph(l10n.guideGettingStartedDayBody),
        GuideSteps([
          GuideStep(
            title: l10n.guideGettingStartedDayStep1Title,
            body: l10n.guideGettingStartedDayStep1Body,
            route: Routes.dashboard,
          ),
          GuideStep(
            title: l10n.guideGettingStartedDayStep2Title,
            body: l10n.guideGettingStartedDayStep2Body,
            route: Routes.circulationReturn,
          ),
          GuideStep(
            title: l10n.guideGettingStartedDayStep3Title,
            body: l10n.guideGettingStartedDayStep3Body,
            route: Routes.circulationReservations,
          ),
          GuideStep(
            title: l10n.guideGettingStartedDayStep4Title,
            body: l10n.guideGettingStartedDayStep4Body,
            route: Routes.settingsBackup,
          ),
        ]),
        GuideFaq([
          GuideFaqEntry(
            l10n.guideGettingStartedFaq1Q,
            l10n.guideGettingStartedFaq1A,
          ),
          GuideFaqEntry(
            l10n.guideGettingStartedFaq2Q,
            l10n.guideGettingStartedFaq2A,
          ),
          GuideFaqEntry(
            l10n.guideGettingStartedFaq3Q,
            l10n.guideGettingStartedFaq3A,
          ),
        ]),
      ],
    ),
  ],
);

GuideArticle _dashboard(AppLocalizations l10n) => GuideArticle(
  topic: GuideTopic.dashboard,
  title: l10n.guideDashboardTitle,
  summary: l10n.guideDashboardSummary,
  route: Routes.dashboard,
  sections: [
    GuideSection(
      anchor: 'what-it-shows',
      title: l10n.guideDashboardReadingHeading,
      blocks: [
        GuideParagraph(l10n.guideDashboardReadingBody),
        GuideScreenshot(
          caption: l10n.guideDashboardShotCaption,
          parts: [
            GuideMockStats(
              [
                l10n.dashboardStatBorrowed,
                l10n.dashboardStatOverdue,
                l10n.dashboardStatReturned,
                l10n.dashboardStatFines,
              ],
              marker: 1,
            ),
            const GuideMockList(rows: 3, marker: 2),
            GuideMockCards(
              [l10n.navCirculationCheckOut, l10n.navCirculationReturn],
              marker: 3,
            ),
          ],
          markers: [
            l10n.guideDashboardShotMarker1,
            l10n.guideDashboardShotMarker2,
            l10n.guideDashboardShotMarker3,
          ],
        ),
      ],
    ),
    GuideSection(
      anchor: 'acting-on-it',
      title: l10n.guideDashboardActingHeading,
      blocks: [
        GuideSteps([
          GuideStep(
            title: l10n.guideDashboardActingStep1Title,
            body: l10n.guideDashboardActingStep1Body,
            route: Routes.circulationLoans,
          ),
          GuideStep(
            title: l10n.guideDashboardActingStep2Title,
            body: l10n.guideDashboardActingStep2Body,
            route: Routes.circulationCheckOut,
          ),
          GuideStep(
            title: l10n.guideDashboardActingStep3Title,
            body: l10n.guideDashboardActingStep3Body,
            route: Routes.reports,
          ),
        ]),
        GuideCallout(
          tone: AppStatusTone.info,
          title: l10n.guideDashboardFiguresTitle,
          body: l10n.guideDashboardFiguresBody,
        ),
      ],
    ),
  ],
);

GuideArticle _catalog(AppLocalizations l10n) => GuideArticle(
  topic: GuideTopic.catalog,
  title: l10n.guideCatalogTitle,
  summary: l10n.guideCatalogSummary,
  route: Routes.catalogTitles,
  sections: [
    GuideSection(
      anchor: 'titles-and-copies',
      title: l10n.guideCatalogModelHeading,
      blocks: [
        GuideParagraph(l10n.guideCatalogModelBody),
        GuideTerms([
          GuideTerm(l10n.guideTermTitle, l10n.guideTermTitleMeaning),
          GuideTerm(l10n.guideTermCopy, l10n.guideTermCopyMeaning),
          GuideTerm(l10n.guideTermIsbn, l10n.guideTermIsbnMeaning),
          GuideTerm(
            l10n.guideTermCallNumber,
            l10n.guideTermCallNumberMeaning,
          ),
          GuideTerm(l10n.guideTermBarcode, l10n.guideTermBarcodeMeaning),
          GuideTerm(l10n.guideTermFormat, l10n.guideTermFormatMeaning),
        ]),
        GuideCallout(
          tone: AppStatusTone.brand,
          title: l10n.guideCatalogOneTitleTitle,
          body: l10n.guideCatalogOneTitleBody,
        ),
      ],
    ),
    GuideSection(
      anchor: 'adding-a-title',
      title: l10n.guideCatalogAddHeading,
      blocks: [
        GuideScreenshot(
          caption: l10n.guideCatalogShotCaption,
          parts: [
            GuideMockToolbar(
              search: l10n.titlesSearchHint,
              action: l10n.titlesAdd,
              marker: 1,
            ),
            GuideMockTable(
              columns: [
                l10n.titlesColumnTitle,
                l10n.titlesColumnAuthor,
                l10n.titlesColumnAvailable,
              ],
              marker: 2,
            ),
          ],
          markers: [
            l10n.guideCatalogShotMarker1,
            l10n.guideCatalogShotMarker2,
          ],
        ),
        GuideSteps([
          GuideStep(
            title: l10n.guideCatalogAddStep1Title,
            body: l10n.guideCatalogAddStep1Body,
            route: Routes.catalogTitles,
          ),
          GuideStep(
            title: l10n.guideCatalogAddStep2Title,
            body: l10n.guideCatalogAddStep2Body,
          ),
          GuideStep(
            title: l10n.guideCatalogAddStep3Title,
            body: l10n.guideCatalogAddStep3Body,
            route: Routes.catalogCopies,
          ),
          GuideStep(
            title: l10n.guideCatalogAddStep4Title,
            body: l10n.guideCatalogAddStep4Body,
            route: Routes.catalogLabels,
          ),
        ]),
      ],
    ),
    GuideSection(
      anchor: 'labels',
      title: l10n.guideCatalogLabelsHeading,
      blocks: [
        GuideParagraph(l10n.guideCatalogLabelsBody),
        GuideCallout(
          tone: AppStatusTone.warning,
          title: l10n.guideCatalogLabelsWarnTitle,
          body: l10n.guideCatalogLabelsWarnBody,
        ),
      ],
    ),
    GuideSection(
      anchor: 'catalog-questions',
      title: l10n.guideCatalogFaqHeading,
      blocks: [
        GuideFaq([
          GuideFaqEntry(l10n.guideCatalogFaq1Q, l10n.guideCatalogFaq1A),
          GuideFaqEntry(l10n.guideCatalogFaq2Q, l10n.guideCatalogFaq2A),
          GuideFaqEntry(l10n.guideCatalogFaq3Q, l10n.guideCatalogFaq3A),
          GuideFaqEntry(l10n.guideCatalogFaq4Q, l10n.guideCatalogFaq4A),
        ]),
      ],
    ),
  ],
);

GuideArticle _circulation(AppLocalizations l10n) => GuideArticle(
  topic: GuideTopic.circulation,
  title: l10n.guideCirculationTitle,
  summary: l10n.guideCirculationSummary,
  route: Routes.circulationLoans,
  sections: [
    GuideSection(
      anchor: 'check-out',
      title: l10n.guideCirculationCheckOutHeading,
      blocks: [
        GuideParagraph(l10n.guideCirculationCheckOutBody),
        GuideScreenshot(
          caption: l10n.guideCirculationShotCaption,
          parts: [
            GuideMockForm(
              fields: [
                l10n.checkOutMemberSection,
                l10n.checkOutCopiesSection,
              ],
              submit: l10n.checkOutConfirm,
              marker: 1,
            ),
            const GuideMockList(rows: 2, marker: 2),
          ],
          markers: [
            l10n.guideCirculationShotMarker1,
            l10n.guideCirculationShotMarker2,
          ],
        ),
        GuideSteps([
          GuideStep(
            title: l10n.guideCirculationCheckOutStep1Title,
            body: l10n.guideCirculationCheckOutStep1Body,
            route: Routes.circulationCheckOut,
          ),
          GuideStep(
            title: l10n.guideCirculationCheckOutStep2Title,
            body: l10n.guideCirculationCheckOutStep2Body,
          ),
          GuideStep(
            title: l10n.guideCirculationCheckOutStep3Title,
            body: l10n.guideCirculationCheckOutStep3Body,
          ),
        ]),
      ],
    ),
    GuideSection(
      anchor: 'returns',
      title: l10n.guideCirculationReturnHeading,
      blocks: [
        GuideParagraph(l10n.guideCirculationReturnBody),
        GuideCallout(
          tone: AppStatusTone.warning,
          title: l10n.guideCirculationReturnWarnTitle,
          body: l10n.guideCirculationReturnWarnBody,
        ),
      ],
    ),
    GuideSection(
      anchor: 'holds',
      title: l10n.guideCirculationHoldsHeading,
      blocks: [
        GuideParagraph(l10n.guideCirculationHoldsBody),
        GuideTerms([
          GuideTerm(l10n.guideTermHold, l10n.guideTermHoldMeaning),
          GuideTerm(
            l10n.guideTermHoldShelf,
            l10n.guideTermHoldShelfMeaning,
          ),
          GuideTerm(l10n.guideTermRenewal, l10n.guideTermRenewalMeaning),
          GuideTerm(l10n.guideTermOverdue, l10n.guideTermOverdueMeaning),
        ]),
      ],
    ),
    GuideSection(
      anchor: 'fines',
      title: l10n.guideCirculationFinesHeading,
      blocks: [
        GuideParagraph(l10n.guideCirculationFinesBody),
        GuideSteps([
          GuideStep(
            title: l10n.guideCirculationFinesStep1Title,
            body: l10n.guideCirculationFinesStep1Body,
            route: Routes.circulationFines,
          ),
          GuideStep(
            title: l10n.guideCirculationFinesStep2Title,
            body: l10n.guideCirculationFinesStep2Body,
          ),
          GuideStep(
            title: l10n.guideCirculationFinesStep3Title,
            body: l10n.guideCirculationFinesStep3Body,
            route: Routes.settingsLoanRules,
          ),
        ]),
        GuideCallout(
          tone: AppStatusTone.danger,
          title: l10n.guideCirculationWaiveTitle,
          body: l10n.guideCirculationWaiveBody,
        ),
      ],
    ),
    GuideSection(
      anchor: 'circulation-questions',
      title: l10n.guideCirculationFaqHeading,
      blocks: [
        GuideFaq([
          GuideFaqEntry(
            l10n.guideCirculationFaq1Q,
            l10n.guideCirculationFaq1A,
          ),
          GuideFaqEntry(
            l10n.guideCirculationFaq2Q,
            l10n.guideCirculationFaq2A,
          ),
          GuideFaqEntry(
            l10n.guideCirculationFaq3Q,
            l10n.guideCirculationFaq3A,
          ),
          GuideFaqEntry(
            l10n.guideCirculationFaq4Q,
            l10n.guideCirculationFaq4A,
          ),
        ]),
      ],
    ),
  ],
);

GuideArticle _members(AppLocalizations l10n) => GuideArticle(
  topic: GuideTopic.members,
  title: l10n.guideMembersTitle,
  summary: l10n.guideMembersSummary,
  route: Routes.members,
  sections: [
    GuideSection(
      anchor: 'register',
      title: l10n.guideMembersRegisterHeading,
      blocks: [
        GuideParagraph(l10n.guideMembersRegisterBody),
        GuideScreenshot(
          caption: l10n.guideMembersShotCaption,
          parts: [
            GuideMockToolbar(
              search: l10n.membersSearchHint,
              action: l10n.membersAdd,
              marker: 1,
            ),
            GuideMockTable(
              columns: [
                l10n.membersColumnName,
                l10n.membersColumnCard,
                l10n.membersColumnCategory,
              ],
              tone: AppStatusTone.danger,
              marker: 2,
            ),
          ],
          markers: [
            l10n.guideMembersShotMarker1,
            l10n.guideMembersShotMarker2,
          ],
        ),
        GuideSteps([
          GuideStep(
            title: l10n.guideMembersRegisterStep1Title,
            body: l10n.guideMembersRegisterStep1Body,
            route: Routes.members,
          ),
          GuideStep(
            title: l10n.guideMembersRegisterStep2Title,
            body: l10n.guideMembersRegisterStep2Body,
          ),
          GuideStep(
            title: l10n.guideMembersRegisterStep3Title,
            body: l10n.guideMembersRegisterStep3Body,
          ),
        ]),
      ],
    ),
    GuideSection(
      anchor: 'categories',
      title: l10n.guideMembersCategoriesHeading,
      blocks: [
        GuideParagraph(l10n.guideMembersCategoriesBody),
        GuideTerms([
          GuideTerm(
            l10n.guideTermMemberType,
            l10n.guideTermMemberTypeMeaning,
          ),
          GuideTerm(
            l10n.guideTermCardNumber,
            l10n.guideTermCardNumberMeaning,
          ),
          GuideTerm(l10n.guideTermStanding, l10n.guideTermStandingMeaning),
        ]),
      ],
    ),
    GuideSection(
      anchor: 'standing',
      title: l10n.guideMembersStandingHeading,
      blocks: [
        GuideParagraph(l10n.guideMembersStandingBody),
        GuideCallout(
          tone: AppStatusTone.warning,
          title: l10n.guideMembersBlockedTitle,
          body: l10n.guideMembersBlockedBody,
        ),
        GuideFaq([
          GuideFaqEntry(l10n.guideMembersFaq1Q, l10n.guideMembersFaq1A),
          GuideFaqEntry(l10n.guideMembersFaq2Q, l10n.guideMembersFaq2A),
          GuideFaqEntry(l10n.guideMembersFaq3Q, l10n.guideMembersFaq3A),
        ]),
      ],
    ),
  ],
);

GuideArticle _reports(AppLocalizations l10n) => GuideArticle(
  topic: GuideTopic.reports,
  title: l10n.guideReportsTitle,
  summary: l10n.guideReportsSummary,
  route: Routes.reports,
  sections: [
    GuideSection(
      anchor: 'what-it-answers',
      title: l10n.guideReportsQuestionsHeading,
      blocks: [
        GuideParagraph(l10n.guideReportsQuestionsBody),
        GuideTerms([
          GuideTerm(
            l10n.reportsCirculationTitle,
            l10n.guideReportsCirculationMeaning,
          ),
          GuideTerm(
            l10n.reportsCollectionTitle,
            l10n.guideReportsCollectionMeaning,
          ),
          GuideTerm(
            l10n.reportsMembersTitle,
            l10n.guideReportsMembersMeaning,
          ),
          GuideTerm(l10n.reportsFinesTitle, l10n.guideReportsFinesMeaning),
          GuideTerm(
            l10n.reportsTopTitlesTitle,
            l10n.guideReportsTopTitlesMeaning,
          ),
        ]),
        GuideScreenshot(
          caption: l10n.guideReportsShotCaption,
          parts: [
            GuideMockStats(
              [
                l10n.reportsStatBorrowed,
                l10n.reportsStatReturned,
                l10n.reportsStatNewMembers,
                l10n.reportsStatFines,
              ],
              marker: 1,
            ),
            GuideMockTable(
              columns: [
                l10n.reportsColumnRank,
                l10n.reportsColumnTitle,
                l10n.reportsColumnLoans,
              ],
              rows: 3,
              marker: 2,
            ),
          ],
          markers: [
            l10n.guideReportsShotMarker1,
            l10n.guideReportsShotMarker2,
          ],
        ),
      ],
    ),
    GuideSection(
      anchor: 'exporting',
      title: l10n.guideReportsExportHeading,
      blocks: [
        GuideSteps([
          GuideStep(
            title: l10n.guideReportsExportStep1Title,
            body: l10n.guideReportsExportStep1Body,
            route: Routes.reports,
          ),
          GuideStep(
            title: l10n.guideReportsExportStep2Title,
            body: l10n.guideReportsExportStep2Body,
          ),
          GuideStep(
            title: l10n.guideReportsExportStep3Title,
            body: l10n.guideReportsExportStep3Body,
          ),
        ]),
        GuideCallout(
          tone: AppStatusTone.info,
          title: l10n.guideReportsExportTipTitle,
          body: l10n.guideReportsExportTipBody,
        ),
      ],
    ),
  ],
);

GuideArticle _staff(AppLocalizations l10n) => GuideArticle(
  topic: GuideTopic.staff,
  title: l10n.guideStaffTitle,
  summary: l10n.guideStaffSummary,
  route: Routes.users,
  sections: [
    GuideSection(
      anchor: 'accounts',
      title: l10n.guideStaffAccountsHeading,
      blocks: [
        GuideParagraph(l10n.guideStaffAccountsBody),
        GuideSteps([
          GuideStep(
            title: l10n.guideStaffAccountsStep1Title,
            body: l10n.guideStaffAccountsStep1Body,
            route: Routes.users,
          ),
          GuideStep(
            title: l10n.guideStaffAccountsStep2Title,
            body: l10n.guideStaffAccountsStep2Body,
            route: Routes.usersRoles,
          ),
          GuideStep(
            title: l10n.guideStaffAccountsStep3Title,
            body: l10n.guideStaffAccountsStep3Body,
          ),
        ]),
      ],
    ),
    GuideSection(
      anchor: 'roles',
      title: l10n.guideStaffRolesHeading,
      blocks: [
        GuideParagraph(l10n.guideStaffRolesBody),
        GuideTerms([
          GuideTerm(l10n.roleAdministrator, l10n.guideStaffRoleAdminMeaning),
          GuideTerm(l10n.roleLibrarian, l10n.guideStaffRoleLibrarianMeaning),
          GuideTerm(l10n.roleAssistant, l10n.guideStaffRoleAssistantMeaning),
          GuideTerm(l10n.roleReadOnly, l10n.guideStaffRoleReadOnlyMeaning),
        ]),
        GuideCallout(
          tone: AppStatusTone.danger,
          title: l10n.guideStaffSharedTitle,
          body: l10n.guideStaffSharedBody,
        ),
      ],
    ),
    GuideSection(
      anchor: 'passwords',
      title: l10n.guideStaffPasswordsHeading,
      blocks: [
        GuideParagraph(l10n.guideStaffPasswordsBody),
        GuideFaq([
          GuideFaqEntry(l10n.guideStaffFaq1Q, l10n.guideStaffFaq1A),
          GuideFaqEntry(l10n.guideStaffFaq2Q, l10n.guideStaffFaq2A),
          GuideFaqEntry(l10n.guideStaffFaq3Q, l10n.guideStaffFaq3A),
        ]),
      ],
    ),
  ],
);

GuideArticle _settings(AppLocalizations l10n) => GuideArticle(
  topic: GuideTopic.settings,
  title: l10n.guideSettingsTitle,
  summary: l10n.guideSettingsSummary,
  route: Routes.settingsLibrary,
  sections: [
    GuideSection(
      anchor: 'library-profile',
      title: l10n.guideSettingsProfileHeading,
      blocks: [
        GuideParagraph(l10n.guideSettingsProfileBody),
        GuideScreenshot(
          caption: l10n.guideSettingsShotCaption,
          parts: [
            GuideMockCards(
              [
                l10n.settingsLibraryTitle,
                l10n.settingsLoanRulesTitle,
                l10n.settingsAppearanceTitle,
                l10n.settingsBackupTitle,
              ],
              marker: 1,
            ),
            GuideMockForm(
              fields: [
                l10n.fieldLibraryName,
                l10n.fieldOpeningHours,
                l10n.fieldCurrency,
              ],
              submit: l10n.settingsLibrarySave,
              marker: 2,
            ),
          ],
          markers: [
            l10n.guideSettingsShotMarker1,
            l10n.guideSettingsShotMarker2,
          ],
        ),
      ],
    ),
    GuideSection(
      anchor: 'loan-rules',
      title: l10n.guideSettingsRulesHeading,
      blocks: [
        GuideParagraph(l10n.guideSettingsRulesBody),
        GuideTerms([
          GuideTerm(
            l10n.fieldLoanPeriodDays,
            l10n.guideSettingsRuleLoanPeriod,
          ),
          GuideTerm(l10n.fieldRenewalLimit, l10n.guideSettingsRuleRenewals),
          GuideTerm(
            l10n.fieldBorrowingLimit,
            l10n.guideSettingsRuleBorrowLimit,
          ),
          GuideTerm(l10n.fieldFinePerDay, l10n.guideSettingsRuleFinePerDay),
          GuideTerm(l10n.fieldGraceDays, l10n.guideSettingsRuleGraceDays),
          GuideTerm(
            l10n.fieldMaxOutstandingFine,
            l10n.guideSettingsRuleMaxOutstanding,
          ),
        ]),
        GuideCallout(
          tone: AppStatusTone.info,
          title: l10n.guideSettingsRulesForwardTitle,
          body: l10n.guideSettingsRulesForwardBody,
        ),
      ],
    ),
    GuideSection(
      anchor: 'appearance',
      title: l10n.guideSettingsAppearanceHeading,
      blocks: [GuideParagraph(l10n.guideSettingsAppearanceBody)],
    ),
    GuideSection(
      anchor: 'backup',
      title: l10n.guideSettingsBackupHeading,
      blocks: [
        GuideParagraph(l10n.guideSettingsBackupBody),
        GuideSteps([
          GuideStep(
            title: l10n.guideSettingsBackupStep1Title,
            body: l10n.guideSettingsBackupStep1Body,
            route: Routes.settingsBackup,
          ),
          GuideStep(
            title: l10n.guideSettingsBackupStep2Title,
            body: l10n.guideSettingsBackupStep2Body,
          ),
          GuideStep(
            title: l10n.guideSettingsBackupStep3Title,
            body: l10n.guideSettingsBackupStep3Body,
          ),
        ]),
        GuideCallout(
          tone: AppStatusTone.danger,
          title: l10n.guideSettingsRestoreTitle,
          body: l10n.guideSettingsRestoreBody,
        ),
        GuideFaq([
          GuideFaqEntry(l10n.guideSettingsFaq1Q, l10n.guideSettingsFaq1A),
          GuideFaqEntry(l10n.guideSettingsFaq2Q, l10n.guideSettingsFaq2A),
          GuideFaqEntry(l10n.guideSettingsFaq3Q, l10n.guideSettingsFaq3A),
        ]),
      ],
    ),
  ],
);
