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

class LocaleTest < ActiveSupport::TestCase
  LOCALE_PATH = File.expand_path("../../config/locales/en.yml", __dir__)

  test "the locale file has one root, rubylode_home" do
    assert_equal %w[rubylode_home], YAML.load_file(LOCALE_PATH).fetch("en").keys
  end

  test "no text a person reads has an em dash, an en dash or British spelling" do
    text = File.read(LOCALE_PATH)

    refute_match(/[–—]/, text)
    refute_match(/colour|licence|visualis/i, text)
  end
end
