#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# encoding: UTF-8

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
# along with Laertes.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2014 William Denton

require 'date'
require 'open-uri'
require 'json'

module Jekyll

  class CO2Generator < Generator

    # This generator is safe from arbitrary code execution.
    safe true

    # This generator should be passive with regard to its execution
    priority :low

    def generate(site)

      # We get the data by downloading and parsing a text file, and we
      # only want to do this once.  Here we get the file and do some
      # work and build the chunk of HTML that will be added to any
      # web page with the {% co2 %} tag on it.  The actual Liquid tag,
      # below, really doesn't do anything except output the HTML.

      # See http://www.esrl.noaa.gov/gmd/ccgg/trends/ for additional details.
      mlo_data = "ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_mlo.txt"

      # Store all the data here so we can easily pick out the three months we want later.
      data = Hash.new

      co2_html = ""

      begin
        open(mlo_data) do |f|
          # STDERR.puts "--- DOWNLOADING"
          raw = f.read
          raw.each_line do |line|
            next if /^#/.match(line)
            (year, month, decimal_date, interpolated, trend, days) = line.split("\s") # Splits nicely on multiple spaces
            month = "%02d" % month # Add a leading zero if none exists
            yyyymm = year + "-" + month
            data[yyyymm] = {
              "decimal_date" => decimal_date,
              "interpolated" => interpolated,
              "trend" => trend,
              "days" => trend
            }
          end
        end

        # Now we want to get the most recent month of data available
        # It will never be the current month, because it's not over yet.
        # It will usually be the previous month, but it might be the
        # month before that (for example if it's 01 June, the May data
        # may not be processed yet, so we need to get April's).

        latest_month = (DateTime.now << 1).strftime("%Y-%m") # << 1 subtracts one month.

        if data.has_key? latest_month
          last_year     = (DateTime.now << 13).strftime("%Y-%m")
          two_years_ago = (DateTime.now << 25).strftime("%Y-%m")
        else
          latest_month  = (DateTime.now <<  2).strftime("%Y-%m")
          last_year     = (DateTime.now << 14).strftime("%Y-%m")
          two_years_ago = (DateTime.now << 26).strftime("%Y-%m")
        end

        co2_html = <<HTML
<div id="co2">
<span class="co2_head">Atmospheric CO₂ at Mauna Loa:</span> <br>
#{latest_month}: #{data[latest_month]["interpolated"]} ppm. <br>
#{last_year}: #{data[last_year]["interpolated"]} ppm. <br>
#{two_years_ago}: #{data[two_years_ago]["interpolated"]} ppm.<br>
<span id="co2_foot">(Monthly averages.)</span>
</div>
HTML

      rescue Exception => e
        Jekyll.logger warn "Could not download data: #{e}"
        @co2_html = %Q{<div id="co2">Could not download data: #{e}"</div>}
      end

      co2_includes_file = site.source + "/_includes/" + "co2.html"

      STDERR.puts co2_includes_file

      File.open(co2_includes_file, "w") do |f|
        f.write co2_html
      end

    end

  end

end
