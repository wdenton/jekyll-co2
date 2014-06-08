#!/usr/bin/env ruby

require 'open-uri'

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

puts data
