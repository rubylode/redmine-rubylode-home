# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.1] - 2026-11-03

### Added

- A Rubylode thumbnail at the top of the README.

### Changed

- The README is plainer and has a licence section.
- The changelog entries are plainer.

## [1.1.0] - 2026-11-02

Adds a settings page, tickets on the welcome page and dates without times. Every default keeps the 1.0.0 behaviour.

### Added

- Three settings under Administration, Plugins, Configure, validated on save.
- "Welcome page content": the four tiles (default), or the tiles plus the signed-in person's open assigned tickets, grouped by project or by due date, with status, priority, due or overdue badge and milestone. The list stops at 30 rows with a link to the full issue list, and the number of queries stays fixed.
- "Column for the tickets" on the welcome page: left or right (default right).
- "Show dates without times in issue lists" (default off): the created, updated and closed columns, and the added by and updated by lines on an issue page, show the date only.

### Changed

- Move the Assigned to me card of My page into a partial shared with the welcome page. Its rows load the milestone in the same preload, with no extra query per ticket.

### Fixed

- The "Due this week" and "Overdue" tiles showed "Translation missing" under the number when nothing was assigned to the person. Every tile now has its text line, and a test covers it.

## [1.0.0] - 2026-11-02

First stable release. A My page with a greeting, four tiles and cards for the tickets assigned to you, due soon, watched and recently updated, plus status and priority chips and relative due dates. The README lists the known limits.
The name, author and version match the redmine.org listing, and the plugin shows its project address on Administration, Plugins.

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
