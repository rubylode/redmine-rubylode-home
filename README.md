# Rubylode Home for Redmine

[![tests](https://github.com/rubylode/redmine-rubylode-home/actions/workflows/tests.yml/badge.svg)](https://github.com/rubylode/redmine-rubylode-home/actions/workflows/tests.yml)

TL;DR: a friendlier My page for [Redmine](https://www.redmine.org): what's assigned to you, what's due, what's overdue
and what you follow, on one page you can read at a glance.

**Status: proposal, requirements pending.** Version 0.2.0 is a first working proposal, built before the owner's
reference design arrived. The layout, wording and colours are expected to change; see `docs/roadmap/ROADMAP.md` for what
is built, what waits for the reference, and the open questions.

![My page, grouped by project](docs/screenshots/my-page-by-project.png)

Contents:

- [What it does](#what-it-does)
- [Installation](#installation)
- [Try it](#try-it)
- [Restyling it](#restyling-it)
- [Compatibility and known limits](#compatibility-and-known-limits)
- [Tests](#tests)
- [License](#license)
- [Disclaimer](#disclaimer)

## What it does

My page (`/my/page`, where Redmine sends you after login) becomes a home view:

- A greeting with today's date and one sentence on where you stand.
- Four tiles: open tickets assigned to you, due this week, overdue, and open tickets you watch. Each tile links to the
  issue list holding exactly those tickets, so the number and the list always agree.
- **Assigned to me**, grouped by project or by due date (overdue, today, later this week, next week, later, no due
  date), with status and priority chips, a short due label ("2 days overdue", "Due in 3 days"), a small progress bar,
  and a red edge on overdue rows. Normal priority gets no chip, so the unusual ones stand out.
- Side cards: **Due soon** (overdue and the next two weeks), **Watching**, **Recently updated** (tickets you wrote,
  commented on or are assigned to) and a compact **Activity** list.
- Every empty card says what would fill it.
- A **New issue** button, shown when you may add tickets somewhere.
- The welcome page (`/`) shows a signed-in person the same four tiles and a link to their home.

Nothing is lost: Redmine's own My page blocks stay at the bottom under "Your My page blocks", collapsed, and still
work as before (add, remove, drag to reorder). **Classic My page** (`/my/page?view=classic`) shows them alone.

Every list goes through Redmine's own visibility rules, so a ticket you can't open never shows, and no list costs a
query per row. Weeks start on the day set in Administration, Settings, Display (or your language's default).

| Grouped by due date | Your own blocks, opened | Welcome page |
|---|---|---|
| ![](docs/screenshots/my-page-by-due-date.png) | ![](docs/screenshots/my-page-classic-blocks-open.png) | ![](docs/screenshots/welcome-page.png) |

| Classic fallback (`?view=classic`) | Narrow screen |
|---|---|
| ![](docs/screenshots/my-page-classic-fallback.png) | ![](docs/screenshots/my-page-narrow.png) |

All screenshots show the made-up demo data from `script/seed_demo.rb`.

## Installation

Redmine 7.0 or newer, on any database Redmine supports. The plugin adds no table and no setting. The folder must be named
`redmine_rubylode_home`, the same as the plugin id.

1. Put the plugin in your Redmine's `plugins` folder:

       cd /path/to/redmine/plugins
       git clone https://github.com/rubylode/redmine-rubylode-home.git redmine_rubylode_home

2. Restart Redmine ([Passenger](https://www.phusionpassenger.com), [Puma](https://puma.io), whatever serves it).

3. Open My page.

With [Docker](https://www.docker.com), mount or copy the plugin to `/usr/src/redmine/plugins/redmine_rubylode_home`
and restart the container.

To upgrade, `git pull` and restart.

To remove it, delete the folder and restart. Nothing is stored in the database, so there is nothing to clean up.

## Try it

A throwaway Redmine 7 runs from this folder on http://localhost:3010, with the repository mounted as the plugin:

    bin/demo up        start it and load the demo data (six projects, six people, 300 made-up tickets)
    bin/demo restart   pick up a change to the plugin (it runs in production mode)
    bin/demo down      stop it, keep the data
    bin/demo reset     stop it and wipe the data

Sign in as `sam.rivera` with the password `demo-password-1` to see a well-filled home, or as admin / admin. The
other demo people are jordan.lee, priya.shah, marco.bianchi, emma.novak and li.wei, with the same password. Running
`bin/demo up` again changes nothing. The data is throwaway; never point the seed script at a real tracker.

## Restyling it

Every colour, radius and gap is a CSS custom property on `.rubylode-home` (`--rubylode-home-accent`,
`--rubylode-home-card-background`, `--rubylode-home-warning` and so on, listed at the top of
`assets/stylesheets/rubylode_home.css`). A theme restyles the page by setting them; the defaults fall back to Redmine
7's own palette. There is no JavaScript of its own.

The variables: `--rubylode-home-accent`, `-accent-soft`, `-accent-strong`, `-bar-fill`, `-bar-track`,
`-card-background`, `-card-border`, `-card-radius`, `-card-shadow`, `-caution`, `-caution-soft`, `-chip-radius`, `-gap`,
`-neutral-soft`, `-page-background`, `-success`, `-success-soft`, `-text`, `-text-muted`, `-warning` and `-warning-soft`,
each with the `--rubylode-home` prefix. For example, in a theme's stylesheet:

    .rubylode-home { --rubylode-home-accent: #6b3fa0; --rubylode-home-card-radius: 4px; }

## Compatibility and known limits

- Redmine 7.x (7.0.2 and the 7.0 stable branch are tested). Older versions are not supported.
- "Due this week" means up to the end of the calendar week, with the first day taken from Redmine's "Start calendars on"
  setting. Late in the week it is a short window: on a Saturday it covers two days. Overdue tickets are counted in
  "Overdue" only.
- The plugin replaces Redmine's `my/page` view. Another plugin or theme that replaces the same view will clash, and
  whichever loads last wins. Use `?view=classic` or remove one of them.
- There is no dark mode. The stylesheet has no dark palette; a theme can supply one through the custom properties.
- Layout, wording and colours are a proposal: the owner's design requirements are still pending (see
  `docs/roadmap/ROADMAP.md`).
- The Overview (project page) and My tickets are not changed yet.
- There are no settings and no permissions of its own; the English locale is the only one shipped.

## Tests

    bin/test                                       all unit and integration tests
    bin/test test/integration/home_page_test.rb    one file

The rules (what counts as overdue or due this week, the groupings, the tile numbers) have unit tests. The pages have
integration tests, one of which checks that the number of queries does not grow with the number of tickets. They run
in a Redmine 7 image with its test gems (`docker/test.Dockerfile`) and send the requests a browser would send.

## Releasing

Push a `vX.Y.Z` tag whose version matches `version` in `init.rb` and has an entry in `CHANGELOG.md`. CI runs the tests, builds `redmine_rubylode_home-X.Y.Z.zip` and publishes the GitHub release with the changelog entry as its notes. To build a release for a tag that already exists, use Actions, release, Run workflow.

## License

GNU General Public License, version 2 or (at your option) any later version, the same as Redmine. See `LICENSE`.

Copyright (C) 2026 Nick Gorbikoff. Each Ruby file carries the same short notice Redmine puts on its own.

## Disclaimer

Use it at your own risk. It comes with no warranty of any kind, as the license says: the software is provided "as is",
without any promise that it works, that it fits your purpose or that it's free of bugs. I'm not liable for any damage,
data loss or downtime that comes from using it, installing it or removing it.

The plugin replaces the My page view and adds to the welcome page; it stores nothing. Back up your Redmine database and try
it on a test instance first anyway. I've tested it on Redmine 7.0.2 and the 7.0 stable branch, and nothing else.
