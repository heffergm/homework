#!/usr/bin/env ruby

require 'bindata'

# the header spec is:
#  4 byte magic string 'MPS7'
#  1 byte version
#  4 byte number of records
#
class MpsHeader < BinData::Record
  endian  :big
  string  :magic,       length: 4
  uint8   :version,     length: 1
  uint32  :num_records, length: 4
end

# the record spec is:
#   1 byte record_type
#   4 byte unix timestamp
#   8 byte uid
#   8 byte double for debit/credits
#
#   record_type enum:
#     0x00: Debit
#     0x01: Credit
#     0x02: StartAutopay
#     0x03: EndAutopay
#
class MpsRecord < BinData::Record
  endian  :big
  uint8   :record_type,   length: 1
  uint32  :timestamp,     length: 4
  uint64  :uid,           length: 8
  double  :credit,        length: 8, onlyif: :_credit?
  double  :debit,         length: 8, onlyif: :_debit?
  string  :start_autopay, length: 0, onlyif: :_start_autopay?
  string  :end_autopay,   length: 0, onlyif: :_end_autopay?

  def _debit?
    return true if record_type == 0x00
  end

  def _credit?
    return true if record_type == 0x01
  end

  def _start_autopay?
    return true if record_type == 0x02
  end

  def _end_autopay?
    return true if record_type == 0x03
  end
end

# read the header
io = File.open('txnlog.dat')
header = MpsHeader.read(io)

puts 'Header information'
puts '------------------'
puts 'Magic: ' + header.magic
puts 'Version: ' + header.version.to_s
puts 'Record count: ' + header.num_records.to_s
puts '------------------'

# build the structured data set
def build_data(datafile, mps_header)
  array = []

  i = 0
  while i <= mps_header.num_records
    i += 1
    array.push(MpsRecord.read(datafile).snapshot)
  end

  return array
end

# helper method to find any user's balance
def find_user_balance(uid, array)
  debits = []
  credits = []

  array.each do |i|
    if i[:uid] == uid
      i[:debit].nil? ? true : debits.push(i[:debit])
      i[:credit].nil? ? true : credits.push(i[:credit])
    end
  end

  balance = credits.inject(:+) - debits.inject(:+)
  return balance
end

mps_data = build_data(io, header)

# set some vars
debits = []
credits = []
end_autopays = 0
start_autopays = 0
noted_uid_balance = 0

mps_data.each do |i|
  # sum the debits and credits
  i[:debit].nil? ? true : debits.push(i[:debit])
  i[:credit].nil? ? true : credits.push(i[:credit])

  # get autopays
  i[:start_autopay].nil? ? true : start_autopays += 1
  i[:end_autopay].nil? ? true : end_autopays += 1
end

puts
puts 'Total debits: ' + debits.inject(:+).to_s
puts 'Total credits: ' + credits.inject(:+).to_s
puts 'Autopays started: ' + start_autopays.to_s
puts 'Autopays ended: ' + end_autopays.to_s
puts 'Balance for uid 2456938384156277127: ' + find_user_balance(2456938384156277127, mps_data).to_s
