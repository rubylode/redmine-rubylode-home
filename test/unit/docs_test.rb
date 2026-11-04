# Rubylode Home: a home view for Redmine's My page
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

require_relative "../test_helper"

class DocsTest < ActiveSupport::TestCase
  ROOT = File.expand_path("../..", __dir__)

  test "the README has the standard headings in order, with the four install steps" do
    readme = File.read(File.join(ROOT, "README.md"))

    assert_equal ["Install", "Settings", "Where it shows", "Troubleshooting", "Tests", "License"], readme.scan(/^## (.+)$/).flatten
    assert_equal 4, readme[/^## Install$(.*?)^## /m, 1].scan(/^\d\. /).size
  end

  test "the changelog has a 2.0.0 entry" do
    assert_match(/^## \[2\.0\.0\] - Unreleased$/, File.read(File.join(ROOT, "CHANGELOG.md")))
  end

  test "the description does not promise what is not built" do
    description = Redmine::Plugin.find(:redmine_rubylode_home).description

    refute_match(/Overview|My tickets/, description)
    refute_match(/Overview|My tickets/, File.read(File.join(ROOT, "docs/redmine-org-listing.md")).lines.grep(/Short description|Version 2/).join)
  end
end
