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

class LinkLineParserTest < ActiveSupport::TestCase
  def parse(text)
    RubylodeHome::LinkLineParser.parse(text)
  end

  test "valid lines become name and URL pairs in order" do
    result = parse("Status | https://status.example.com\nWiki | http://wiki.example.com/home")

    assert_predicate result, :valid?
    assert_equal [["Status", "https://status.example.com"], ["Wiki", "http://wiki.example.com/home"]],
                 result.links.map { |link| [link.name, link.url] }
  end

  test "blank lines and comment lines are skipped without an error" do
    result = parse("# the team's links\n\n   \nStatus | https://status.example.com\n  # indented comment\n")

    assert_predicate result, :valid?
    assert_equal ["Status"], result.links.map(&:name)
  end

  test "extra whitespace around the name and the URL is removed" do
    result = parse("   Status   |   https://status.example.com   \r\n")

    assert_equal [["Status", "https://status.example.com"]], result.links.map { |link| [link.name, link.url] }
  end

  test "a line without a URL is reported with its line number and the others are still read" do
    result = parse("Status | https://status.example.com\nBroken\nWiki | https://wiki.example.com")

    assert_equal %w[Status Wiki], result.links.map(&:name)
    assert_equal [2], result.errors.map(&:line_number)
    refute_predicate result, :valid?
  end

  test "a line with an empty name or an empty URL is reported" do
    result = parse(" | https://status.example.com\nStatus |")

    assert_empty result.links
    assert_equal [1, 2], result.errors.map(&:line_number)
  end

  test "a line with more than two fields is reported" do
    result = parse("Status | https://status.example.com | extra")

    assert_empty result.links
    assert_equal [1], result.errors.map(&:line_number)
  end

  test "only http and https are accepted" do
    result = parse(
      "Script | javascript:alert(1)\nData | data:text/html,hi\nFile | file:///etc/passwd\nFtp | ftp://example.com\n" \
      "Relative | /issues\nNo host | https://\nSecure | https://example.com"
    )

    assert_equal ["Secure"], result.links.map(&:name)
    assert_equal [1, 2, 3, 4, 5, 6], result.errors.map(&:line_number)
  end

  test "a name with markup is kept as text, to be escaped when it is drawn" do
    result = parse("<script>alert(1)</script> | https://example.com")

    assert_equal ["<script>alert(1)</script>"], result.links.map(&:name)
  end

  test "nil and empty text give no links and no errors" do
    [nil, "", "\n\n"].each do |text|
      result = parse(text)

      assert_empty result.links
      assert_predicate result, :valid?
    end
  end
end
