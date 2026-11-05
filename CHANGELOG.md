# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.1.0] - 2026-11-05

No change to what the plugin does. This release carries the documentation and the build.

### Changed

- The workflows use the current versions of the GitHub actions, and Dependabot sends one grouped update a month instead of one pull request per action.
- The version number is no longer asserted exactly by the tests, so a release does not need a test edit.

## [2.0.0] - 2026-11-04

Brings the plugin to the Rubylode plugin standard: one settings class, one locale root, one README layout.

### Upgrading

- Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production` and restart Redmine, as for any upgrade.
- No saved settings key is renamed (`welcome_page_content`, `welcome_page_column` and `dates_without_times` already match the standard), so this release has no migration and nothing to move or reverse. Saved settings carry over unchanged.
- If you override this plugin's translations in your own locale file, move them to the new keys. Every key now sits under `rubylode_home`; the old flat `label_rubylode_home_*` and `text_rubylode_home_*` keys are gone. The lookup of old to new is in the Changed list below.
- If other code calls `RedmineRubylodeHome::Defaults`, `RubylodeHome::Configuration` or the `RedmineRubylodeHome` module, use `RubylodeHome::Settings` and the `RubylodeHome` module instead.

### Changed

- `RubylodeHome::Settings` replaces `RubylodeHome::Configuration` and `RedmineRubylodeHome::Defaults`. The defaults are `RubylodeHome::Settings::DEFAULTS`. The `RedmineRubylodeHome` module is now `RubylodeHome`.
- The locale file has one root, `rubylode_home`. Settings are under `rubylode_home.settings.<key>.label` and `.hint`; the rest is grouped by screen (`greeting`, `summary`, `classic`, `tiles`, `cards`, `activity`, `grouping`, `buckets`, `due`, `dates`, `welcome`, `errors`).
- The welcome page column setting is labeled "Column" and is a select with Left and Right. Its choice labels and hints are reworded.
- The description in Administration, Plugins reads "A home view for Redmine's My page: your tickets, due dates and watched tickets on one page". It no longer promises the Overview and My tickets, which are not built.
- "Open tickets you follow" is now "Open tickets you watch", and "Open your home" is now "Open My page".
- The "Showing N of M" line under the welcome page tickets ends with a period.
- The README follows the standard headings: Install, Settings, Where it shows, Troubleshooting, Tests, License.


## [1.2.1] - 2026-11-04

### Changed

- Needs Redmine 5.1 or newer instead of 5.0. Redmine 5.0 cannot be tested in CI (the sqlite3 gem it pins does not build
  there), and this plugin only claims what CI verifies. No code changed.

## [1.2.0] - 2026-11-04

### Changed

- Runs on Redmine 5.0 and newer. The plugin's own tests pass unchanged on those versions; no code changed.

## [1.1.1] - 2026-11-03

### Added

- A Rubylode thumbnail at the top of the README.

### Changed

- The README is shorter and has a License section.
- Reworded the changelog entries.

## [1.1.0] - 2026-11-02

Adds a settings page, tickets on the welcome page and dates without times. Every default keeps the 1.0.0 behavior.

### Added

- Three settings under Administration, Plugins, Configure, validated on save.
- "Welcome page content": the four tiles (default), or the tiles plus the signed-in person's open assigned tickets, grouped by project or by due date, with status, priority, due or overdue badge and milestone. The list stops at 30 rows with a link to the full issue list, and the number of queries stays fixed.
- "Column for the tickets" on the welcome page: left or right (default right).
- "Show dates without times in issue lists" (default off): the created, updated and closed columns, and the added by and updated by lines on an issue page, show the date only.

### Changed

- The Assigned to me card of My page is now a partial shared with the welcome page. Its rows load the milestone in the same preload, with no extra query per ticket.

### Fixed

- The "Due this week" and "Overdue" tiles showed "Translation missing" under the number when nothing was assigned to the person. Every tile now has its text line, and a test covers it.

## [1.0.0] - 2026-11-02

First stable release. A My page with a greeting, four tiles and cards for the tickets assigned to you, due soon, watched and recently updated, plus status and priority chips and relative due dates. The README lists the known limits.

### Added

- The name, author and version match the redmine.org listing, and the plugin shows its project address on Administration, Plugins.

## [0.2.0] - 2026-11-01

A first working version of the home view, made before the requirements were written. Expect it to change.

### Added

- My page becomes a home view: a greeting with the date, four tiles (assigned and open, due this week, overdue,
  watched) that link to the matching issue lists, the tickets assigned to you grouped by project or by due date, and
  cards for due soon, watching, recently updated and recent activity.
- Status and priority chips, relative due labels, small progress bars, and overdue rows marked in red.
- A line on empty cards that says what would fill them, and a New issue button for people who may add tickets.
- The four tiles on the welcome page for a signed-in person.
- Unit tests for the due date rules, the groupings and the tiles; integration tests for the pages, permissions and
  query count.
- `bin/demo` and a seed script with made-up data, and screenshots in the README (including the classic fallback and a narrow screen).

### Changed

- Redmine's own My page blocks move to a collapsed section at the bottom, where they still work, and to
  `/my/page?view=classic`.
- The demo Redmine runs on port 3010.

### Removed

- The placeholder marker.

## [0.1.0] - 2026-10-31

Skeleton. Redmine 7.0 and newer.

### Added

- The plugin registers as Rubylode Home.
- A placeholder marker and one stylesheet on My page, to show that the plugin loads.
- An integration test for the registration and the marker, a throwaway Redmine and a test runner in Docker, and CI.
