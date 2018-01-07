#!/usr/bin/env ruby

require 'bindata'
require 'optparse'
require_relative 'include/options.rb'
require_relative 'include/proto.rb'

# read the header
io = File.open(@options[:datafile])
header = MpsHeader.read(io)

# basic check to make sure this is really MPS data
if header.magic == 'MPS7'
  true
else
  abort 'Aborting! This does not appear to be an MPS data file. ' \
    'Header magic is: ' + header.magic + ', expected MPS7.'
end

puts 'Header information'
puts '------------------'
puts 'Magic: ' + header.magic
puts 'Version: ' + header.version.to_s
puts 'Record count: ' + header.num_records.to_s
puts '------------------'

# build and display data
mps_data = build_data(io, header)

puts
puts 'Total debits: ' + sum_type(:debit, mps_data).to_s
puts 'Total credits: ' + sum_type(:credit, mps_data).to_s
puts 'Autopays started: ' + count_type(:start_autopay, mps_data).to_s
puts 'Autopays ended: ' + count_type(:end_autopay, mps_data).to_s
puts "Balance for uid #{@options[:uid]}: " \
  + find_user_balance(@options[:uid], mps_data).to_s
