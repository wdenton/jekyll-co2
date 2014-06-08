#!/usr/bin/env ruby

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
# If it isn't the current month, step back 28 days.
# That should always be enough.

yyyymm = Date.today.strftime("%Y-%m")

if data.has_key? yyyymm
  previous_year = (Date.today - 365).strftime("%Y-%m")
else
  yyyymm = (Date.today - 28).strftime("%Y-%m")
  previous_year = (Date.today - 28 - 365 ).strftime("%Y-%m")
end

puts yyyymm
puts data[yyyymm]
puts previous_year
puts data[previous_year]

annual_increase = 100 * data[yyyymm]["interpolated"].to_f / data[previous_year]["interpolated"].to_f

puts annual_increase
