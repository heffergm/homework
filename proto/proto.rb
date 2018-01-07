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

# set some vars
debits = []
credits = []
end_autopays = 0
start_autopays = 0
noted_uid_balance = 0

# loop through the data
i = 0
while i < header.num_records
  i += 1
  r = MpsRecord.read(io)

  # increment autopay counters
  r.snapshot[:start_autopay].nil? ? true : start_autopays += 1
  r.snapshot[:end_autopay].nil? ? true : end_autopays += 1

  # push debits/credits into arrays
  r.snapshot[:debit].nil? ? true : debits.push(r.debit)
  r.snapshot[:credit].nil? ? true : credits.push(r.credit)

  # figure out our special friend's balance
  if r.uid == 2456938384156277127
    balance = r.credit - r.debit
    noted_uid_balance += balance
  end
end

puts
puts 'Total debits: ' + debits.inject(:+).to_s
puts 'Total credits: ' + credits.inject(:+).to_s
puts 'Autopays started: ' + start_autopays.to_s
puts 'Autopays ended: ' + end_autopays.to_s
puts 'Balance for uid 2456938384156277127: ' + noted_uid_balance.to_s
