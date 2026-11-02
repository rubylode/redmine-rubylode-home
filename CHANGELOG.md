# Changelog

All notable changes to this plugin. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-11-01

A first working proposal of the home view, made before the requirements are written. Expect it to change.

### Added

- My page becomes a home view: a greeting with the date, four tiles (assigned and open, due this week, overdue,
  watched) that link to the matching issue lists, the tickets assigned to you grouped by project or by due date, and
  cards for due soon, watching, recently updated and recent activity.
- Status and priority chips, relative due labels, small progress bars, and overdue rows marked in red.
- Empty cards say what would fill them; a New issue button for people who may add tickets.
- The four tiles on the welcome page for a signed-in person.
- Unit tests for the due date rules, the groupings and the tiles; integration tests for the pages, permissions and
  query count.
- `bin/demo` and a seed script with made-up data, and screenshots in the README (including the classic fallback and a narrow screen).

### Changed

- Redmine's own My page blocks move to a collapsed section at the bottom, still fully working, and to
  `/my/page?view=classic`.
- The demo Redmine runs on port 3010.

### Removed

- The placeholder marker.

## [0.1.0] - 2026-10-31

Skeleton. Redmine 7.0 and newer.

### Added

- The plugin registers as Rubylode Home.
- A placeholder marker and one stylesheet on the My page, to show the plugin loads there.
- An integration test for the registration and the marker, a throwaway Redmine and a test runner in Docker, and CI.
