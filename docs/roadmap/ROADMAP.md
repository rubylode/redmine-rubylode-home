# Roadmap

**Status: version 2.0.0.** The list below is what is built and what is open.

## Goal

Improve the home views of Redmine: the page a person lands on after login. The first target was a My page that is much
easier to scan than Redmine's block layout. The Overview (project page) and My tickets are not changed.

## Built

- My page (`/my/page`) replaced by a home view: greeting with today's date, a one-line summary, four tiles (assigned and
  open, due this week, overdue, watched), each linking to the matching issue list.
- Assigned to me grouped by project or by due date, with status and priority chips, relative due labels, progress
  bars and emphasized overdue rows. At most 30 rows, with a link to the full list.
- Side cards: Due soon (overdue plus the next 14 days), Watching, Recently updated (written, commented on or assigned),
  Activity (last 30 days, eight entries). Each empty card says what to do.
- A New issue button when the person may add tickets anywhere.
- Redmine's own blocks kept below, collapsed, fully working; a "Classic My page" link shows them alone.
- The welcome page shows a signed-in person the four tiles and a link to My page.
- Rules in plain Ruby classes with unit tests: `DueDateRules` (overdue, due this week, due soon, buckets),
  `IssueGroups`, `SummaryTiles`, `HomePage` (the queries, through `Issue.visible`, preloaded).
- Plain CSS with custom properties, so a theme can restyle it. No JavaScript of its own.
- A demo on port 3010 with made-up data (`bin/demo up`).
- A settings page with three settings: Welcome page content, Column and Show dates without times in issue lists.
  Welcome page content can add the signed-in person's open tickets to the welcome page. No permission of its own.

Rules, each easy to change in `app/models/rubylode_home/due_date_rules.rb`:

- Overdue: an open ticket whose due date is before today.
- Due this week: from today to the last day of the week, using Redmine's "Start calendars on" setting. Overdue tickets
  are not counted again here.
- Due soon: overdue, or due within the next 14 days.
- Assigned to me: assigned to the person or to one of their groups, as Redmine's "me" filter does.

## Open

- The Overview (project page) and My tickets get no treatment yet.
- Should Redmine's block layout stay at the bottom of the page, move behind the "Classic My page" link only, or become
  a per-person choice (a preference to land on the classic page)?
- Should the grouping choice (project or due date) be remembered per person instead of living in the address?
- Are "this week" (calendar week) and "due soon" (14 days) the right windows, or should both be "the next 7 days"? Late
  in the week the calendar week is short (on a Saturday it is two days).
- Should Activity show everything the person can see, only their projects, or only their own tickets?
- The plugin replaces Redmine's `my/page` view. Another plugin that replaces the same view clashes with it. The README
  says so under Troubleshooting.
- Should "Resolved" count as open? Today it follows Redmine: only statuses marked closed are closed.

## Done

- 2.0.0: the Rubylode plugin standard (one settings class, one locale root, one README layout).
- 1.2.1: needs Redmine 5.1 or newer.
- 1.1.0: the settings page, tickets on the welcome page and dates without times.
- 1.0.0: the first stable release of the home view.
- 0.2.0: the first working version of the home view.
- 0.1.0: skeleton. Plugin registration, a placeholder marker and stylesheet on the My page, an integration test, a
  throwaway Redmine, CI.
