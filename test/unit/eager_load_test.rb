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

# Production loads every file under the plugin's autoload paths at boot. The test environment does not, so a file whose
# path and constant disagree passes every other test and then stops Redmine from starting.
class EagerLoadTest < ActiveSupport::TestCase
  test "every file in the plugin's code paths defines the constant its path names" do
    Zeitwerk::Loader.eager_load_all
  end

  test "no lib folder is named after the old module" do
    refute Dir.exist?(File.expand_path("../../lib/redmine_rubylode_home", __dir__))
  end
end
