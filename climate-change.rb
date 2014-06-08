#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'date'
require 'open-uri'
require 'json'

mlo_data = "ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_mlo.txt"

data = Hash.new

begin
  open(mlo_data) do |f|
    raw = f.read
    # puts raw
    raw.each_line do |line|
      next if /^#/.match(line)
      (year, month, decimal_date, interpolated, trend, days) = line.split("\s")
      month = "%02d" % month # Add a leading zero if none exists
      yyyymm = year + "-" + month
      data[yyyymm] = { "decimal_date" => decimal_date,
        "interpolated" => interpolated,
        "trend" => trend,
        "days" => trend
      }
    end
  end

rescue Exception => e
  STDERR.puts "Could not download data: #{e}"
end

# Now we want to get the most recent month of data available
# It will never be the current month, because it's not over yet.
# It will usually be the previous month, but it might be the
# month before that (for example if it's 01 June, the May data
# may not be processed yet, so we need to get April's).

latest_month = (DateTime.now << 1).strftime("%Y-%m") # << 1 subtracts one month.

if data.has_key? latest_month
  last_year = (DateTime.now << 13).strftime("%Y-%m")
  two_years_ago = (DateTime.now << 25).strftime("%Y-%m")
else
  latest_month = (DateTime.now << 2).strftime("%Y-%m")
  last_year = (DateTime.now << 14).strftime("%Y-%m")
  two_years_ago = (DateTime.now << 26).strftime("%Y-%m")
end

puts "CO₂ in #{latest_month} was #{data[latest_month]["interpolated"]}"
puts "CO₂ in #{last_year} was #{data[last_year]["interpolated"]}"
puts "CO₂ in #{two_years_ago} was #{data[two_years_ago]["interpolated"]}"
