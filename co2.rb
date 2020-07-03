#!/usr/bin/env ruby
# frozen_string_literal: true

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

    # Turn a month number (02) into a name (February).
    def month_name(mmm)
      Date::MONTHNAMES[mmm.to_i]
    end

    def generate(site)
      @site = site

      # See http://www.esrl.noaa.gov/gmd/ccgg/trends/ for additional details.
      mlo_csv_url = "ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_mlo.csv"

      site_data_dir = site.source + "/_data/"
      mlo_csv = site_data_dir + "co2_mm_mlo.csv"

      unless Dir.exist?(site_data_dir)
        warn "Creating #{site_data_dir}"
        Dir.mkdir(site_data_dir)
      end

      # Download the data and store locally.
      begin
        File.open(mlo_csv, "wt") do |file|
          file << URI.open(mlo_csv_url).read.gsub(/^#.*\n/, "") # Strip all the comments.
        end
      rescue StandardError => e
        # TODO:  This doesn't work right.  Make it work even if NOAA site is down.
        warn "Error on #{mlo_csv_url}: #{e}"
        warn "Could not download data: using stored file"
        exit 0
      end

      # Store all the data here so we can easily pick out the three
      # months we want.
      co2_data = Hash.new { |h, k| h[k] = {} }

      CSV.foreach(mlo_csv, headers: true, header_converters: :symbol) do |row|
        yyyy = row[:year]
        month_num = format("%<name>02d", name: row[:month]) # Add a leading zero if none exists
        co2_data[yyyy][month_num] = {
          # "decimal_date" => row[:decimal_date],
          # "average" => row[:average],
          "interpolated" => row[:interpolated]
          # "trend" => row[:trend],
          # "days" => row[:days]
        }
      end

      co2_html = ""

      # Now we want to get the most recent month of data available
      # It will never be the current month, because it's not over yet.
      # It will usually be the previous month, but it might be the
      # month before that (for example if it's 01 June, the May data
      # may not be processed yet, so we need to get April's).
      latest_year = (DateTime.now << 1).strftime("%Y").to_i # Subtracts one year
      latest_month = (DateTime.now << 1).strftime("%m") # Keep as string, need leading 0

      if co2_data[latest_year][latest_month]
        # << 1 subtracts one month.
        month_now = (DateTime.now << 1).strftime("%m")
        yyyy_now = (DateTime.now << 1).strftime("%Y").to_i
      else
        month_now = (DateTime.now << 2).strftime("%m")
        yyyy_now = (DateTime.now << 2).strftime("%Y").to_i
      end

      years_back = 50 # TODO: Move this default somewhere more sensible
      years_back = site.config["co2"]["years"].to_i if site.config.key?("co2") && site.config["co2"].key?("years")

      yyyy_then = (yyyy_now - years_back).to_s
      month_then = month_now

      if years_back.zero?
        # The NOAA data starts in March 1958.
        yyyy_then = "1958"
        month_then = "03"
      end

      co2_then = co2_data[yyyy_then][month_then.to_s]["interpolated"].to_f

      # mm = "05"

      co2_now = co2_data[yyyy_now.to_s][month_now.to_s]["interpolated"].to_f

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
          Sources:
          <a href="http://www.esrl.noaa.gov/gmd/ccgg/trends/">data</a>,
          <a href="https://github.com/wdenton/jekyll-co2">code</a>.
          </span>
        </div>
        </div>
      HTML

      # Dump the little chunk of HTML to the _includes directory,
      # where it can be included with {% include co2.html %} as
      # needed.

      co2_includes_file = site.source + "/_includes/" + "co2.html"

      begin
        File.open(co2_includes_file, "w") do |f|
          f.write co2_html
        end
      rescue StandardError => e
        Jekyll.logger warn "Cannot write to #{co2_includes_file}: #{e}"
      end
    end
  end
end
