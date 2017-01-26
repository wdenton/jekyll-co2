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
# along with Jekyll CO₂.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2014, 2017 William Denton <wtd@pobox.com>

require "date"
require "open-uri"

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

      # Store all the data here so we can easily pick out the three
      # months we want.
      data = Hash.new { |h, k| h[k] = {} }

      co2_html = ""

      begin
        open(mlo_data) do |f|
          raw = f.read
          raw.each_line do |line|
            next if /^#/.match(line)
            (yyyy, month, decimal_date, average, interpolated, trend, days) = line.split("\s")
            yyyy = yyyy.to_i
            mm = ("%02d" % month) # Add a leading zero if none exists
            # yyyymm = year + "-" + month #
            data[yyyy][mm] = {
              "decimal_date" => decimal_date,
              "average" => average,
              "interpolated" => interpolated,
              "trend" => trend,
              "days" => trend
            }
          end
        end
      rescue Net::FTPTempError => e
        Jekyll.logger warn "Could not download data: #{e}"
        exit
      end

      # Now we want to get the most recent month of data available
      # It will never be the current month, because it's not over yet.
      # It will usually be the previous month, but it might be the
      # month before that (for example if it's 01 June, the May data
      # may not be processed yet, so we need to get April's).

      def month_name(mm)
        Date::MONTHNAMES[mm.to_i]
      end

      monthname = ""
      latest_year = (DateTime.now << 1).strftime("%Y").to_i # Subtracts one year
      latest_month = (DateTime.now << 1).strftime("%m") # Keep as string, need leading 0

      mm = ""
      yyyy = ""

      if data[latest_year][latest_month]
        # << 1 subtracts one month.
        mm = (DateTime.now << 1).strftime("%m")
        monthname = month_name(mm)
        yyyy = (DateTime.now << 1).strftime("%Y").to_i
      else
        mm = (DateTime.now << 2).strftime("%m")
        monthname = month_name(mm)
        yyyy = (DateTime.now << 2).strftime("%Y").to_i
      end

      ticks = %w(▁ ▂ ▃ ▄ ▅ ▆ ▇)

      years_to_sample = 20

      # Sparklines taken from https://gist.github.com/jcromartie/1367091
      values = (yyyy - years_to_sample..yyyy).map { |x| data[x][mm]["interpolated"] }
      min, range, scale = values.min.to_f, values.max.to_f - values.min.to_f, ticks.length - 1
      sparkline = values.map.with_index { |x, i| %Q(<span title="#{yyyy - (years_to_sample - i)}: #{x}">#{ticks[(((x.to_f - min) / range) * scale).round]}</span>) }.join
      # sparkline = values.map { |x| %Q(<span title="#{x}">#{ticks[(((x.to_f - min) / range) * scale).round]}</span>)}.join

      co2_html = <<HTML
<div id="co2">
<h2>CO₂</h2>
<span class="sparkline">#{sparkline}</span>
<p><span class="co2_title">Atmospheric CO₂ at Mauna Loa (ppm) in #{monthname} over the last #{years_to_sample} years.</span> </p>
<span class="co2_source">
Sources:
<a href="http://www.esrl.noaa.gov/gmd/ccgg/trends/">data</a>,
<a href="https://github.com/wdenton/jekyll-co2">code</a>.
</span>
</div>
HTML

      # This approach is taken from the Stack Overflow question
      #
      # Avoid repeated calls to an API in Jekyll Ruby plugin
      # https://stackoverflow.com/questions/15235023/avoid-repeated-calls-to-an-api-in-jekyll-ruby-plugin
      #

      # Dump the little chunk of HTML to the _includes directory,
      # and then let it be included with {% include co2.html %}
      # where desired.

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
