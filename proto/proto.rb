#!/usr/bin/env ruby

require 'bindata'
require_relative 'include/proto.rb'

# read the header
io = File.open('txnlog.dat')
header = MpsHeader.read(io)

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
puts 'Balance for uid 2456938384156277127: ' + find_user_balance(2456938384156277127, mps_data).to_s
