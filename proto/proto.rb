#!/usr/bin/env ruby

require 'bindata'
require 'optparse'
require_relative 'include/proto.rb'

@options = {}
OptionParser.new do |opts|
  @options[:datafile] = 'txnlog.dat'
  opts.on(
    '--mps-datafile DATA_FILE',
    '-f DATA_FILE',
    String,
    'Location of the MPS data file'
  ) do |datafile|
    @options[:datafile] = datafile
  end

  @options[:uid] = 2456938384156277127
  opts.on(
    '--uid UID',
    '-u UID',
    Integer,
    'UID to find the balance for.'
  ) do |uid|
    @options[:uid] = uid
  end
end.parse!

# read the header
io = File.open(@options[:datafile])
header = MpsHeader.read(io)

# basic check to make sure this is really MPS data
abort 'Aborting! This does not appear to be an MPS data file. Header magic is: ' \
  + header.magic + ', expected MPS7.' unless header.magic == 'MPS7'

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
puts "Balance for uid #{@options[:uid]}: " + find_user_balance(@options[:uid], mps_data).to_s
