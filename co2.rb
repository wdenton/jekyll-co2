#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Style/AsciiComments

# This file is part of Jekyll CO₂
#
# Jekyll CO₂ is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Jekyll CO₂ is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Jekyll CO₂.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2014--2020 William Denton <wtd@pobox.com>

# rubocop:enable Style/AsciiComments

require "csv"
require "date"
require "open-uri"

module Jekyll
  # Here follows the plugin.
  class CO2Generator < Generator
    # This generator is safe from arbitrary code execution.
    safe true

    # This generator should be passive with regard to its execution
    priority :low

    def generate(site)
      @site = site

      make_data_dir_if_needed
      download_mlo_csv

      @co2_data = read_mlo_csv

      # Now we want to get the most recent month of data available
      # It will never be the current month, which is not finished.
      # It will usually be the previous month, but it might be the
      # month before that (for example if it's 01 June, the May data
      # may not be processed yet, so we need to get April's).
      latest_year = (DateTime.now << 1).strftime("%Y").to_i # Subtracts one year
      latest_month = (DateTime.now << 1).strftime("%m").to_i

      if @co2_data[latest_year][latest_month]
        month_now = latest_month
        yyyy_now = latest_year
      else
        # << 2 subtracts two months.
        # Simplest to handle it this way in case we need to go back to
        # the previous year.
        month_now = (DateTime.now << 2).strftime("%m").to_i
        yyyy_now = (DateTime.now << 2).strftime("%Y").to_i
      end

      years_back = 50 # TODO: Move this default somewhere more sensible
      years_back = @site.config["co2"]["years"].to_i if @site.config.key?("co2") && @site.config["co2"].key?("years")

      yyyy_then = yyyy_now - years_back
      month_then = month_now

      if years_back.zero? || yyyy_then < 1958
        # The NOAA data starts in March 1958.
        # If years is 0, start there.
        # Also start there is the user set it to go back before 1958.
        yyyy_then = 1958
        month_then = 3
      end

      co2_then = @co2_data[yyyy_then][month_then]["average"].to_f
      co2_now = @co2_data[yyyy_now][month_now]["average"].to_f
      co2_increase = (co2_now - co2_then).round(2)
      co2_growth = (100 * co2_increase / co2_then).round(1)

      co2_html = <<~HTML
        <div id="co2">
          <h2>Atmospheric CO₂</h2>
          <div id="co2_inside">
             <p>
              #{month_name(month_then)} #{yyyy_then}: #{co2_then} ppm
              <br />
              #{month_name(month_now)} #{yyyy_now}: #{co2_now} ppm
            </p>
            <p>
              Increase: <span class="highlight">#{co2_increase} ppm</span>
              <br />
              Change: <span class="highlight">#{co2_growth} %</span>
            </p>

          <span class="co2_source">
          At Mauna Loa:
          <a href="https://www.esrl.noaa.gov/gmd/ccgg/trends/">data</a>,
          <a href="https://github.com/wdenton/jekyll-co2">code</a>.
          </span>
        </div>
        </div>
      HTML

      begin
        write_co2_includes_file(co2_html)
      rescue StandardError => e
        warn "Cannot write to _includes/: #{e}"
      end
    end

    private

    # Turn a month number (02) into a name (February).
    def month_name(mmm)
      Date::MONTHNAMES[mmm.to_i]
    end

    # Path to _data/
    def site_data_dir
      "#{@site.source}/_data"
    end

    def mlo_csv
      "#{site_data_dir}/co2_mm_mlo.csv"
    end

    def mlo_csv_url
      # See http://www.esrl.noaa.gov/gmd/ccgg/trends/ for details.
      "ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_mlo.csv"
    end

    def make_data_dir_if_needed
      return if Dir.exist?(site_data_dir)

      warn "Creating #{site_data_dir}"
      Dir.mkdir(site_data_dir)
    end

    def download_mlo_csv
      # Download the data and store locally.
      File.open(mlo_csv, "wt") do |file|
        file << URI.parse(mlo_csv_url).open.read.gsub(/^#.*\n/, "") # Strip all the comments.
      end
    rescue StandardError => e
      # TODO:  This doesn't work right.  Make it work even if NOAA site is down.
      warn "Error on #{mlo_csv_url}: #{e}"
      warn "Could not download data: using stored file"
      # exit 0
    end

    def read_mlo_csv
      # Set up the hash of hashes we'll use.
      co2_data = Hash.new { |h, k| h[k] = {} }

      CSV.foreach(mlo_csv, headers: true, header_converters: :symbol) do |row|
        yyyy = row[:year].to_i
        month_num = row[:month].to_i # January is 1, not 01
        co2_data[yyyy][month_num] = {
          # Throw out the other fields.
          "average" => row[:average]
        }
      end
      co2_data
    end

    def write_co2_includes_file(co2_html)
      # Dump the little chunk of HTML to the _includes directory,
      # where it can be included with {% include co2.html %} as
      # needed.
      co2_includes_file = "#{@site.source}/_includes/co2.html"
      File.write(co2_includes_file, co2_html)
    end
  end
end
