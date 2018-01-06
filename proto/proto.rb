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
puts 'Number of records: ' + header.num_records.to_s
puts '------------------'

# set some vars
i = 0
debits = []
credits = []
end_autopays = 0
start_autopays = 0
noted_uid_balance = 0

# loop through the data
while i <= header.num_records
  i += 1
  r = MpsRecord.read(io)

  # Search for any autopay records, increment
  #   the counter if we find one.
  #
  r.to_s =~ /start_autopay/ ? start_autopays += 1 : false
  r.to_s =~ /end_autopay/ ? end_autopays += 1 : false

  # Push any debit or credit records into their
  #   respective arrays so we can sum them later.
  #
  debits.push(r.debit) unless r.debit == 0.0
  credits.push(r.credit) unless r.credit == 0.0

  # figure out our special friend's balance
  if r.uid == 2456938384156277127
    balance = r.credit - r.debit
    noted_uid_balance += balance
  end
end

# sum our debits and credits arrays
total_debits = debits.inject(:+)
total_credits = credits.inject(:+)

puts
puts 'Total debits: ' + total_debits.to_s
puts 'Total credits: ' + total_credits.to_s
puts 'Autopays started: ' + start_autopays.to_s
puts 'Autopays ended: ' + end_autopays.to_s
puts 'Balance for uid 2456938384156277127: ' + noted_uid_balance.to_s
