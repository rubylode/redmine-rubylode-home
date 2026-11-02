# Rubylode Home: better home views for Redmine
# Copyright (C) 2026  Nick Gorbikoff
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require "redmine"

Redmine::Plugin.register :redmine_rubylode_home do
  name "Rubylode Home"
  author "Rubylode"
  author_url "https://github.com/rubylode"
  description "Better home views for Redmine: My page, the Overview and My tickets"
  version "0.2.0"
  requires_redmine version_or_higher: "7.0.0"
end

require_relative "lib/redmine_rubylode_home/hooks"

# Redmine renders only a controller's own helpers, so the two pages the plugin draws on get the plugin's helper too.
# This file runs on every code reload, and adding the same helper twice is harmless.
MyController.helper(RubylodeHomeHelper)
WelcomeController.helper(RubylodeHomeHelper)
