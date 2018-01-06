#!/usr/bin/env ruby

require 'bindata'

# the header spec is:
#  4 byte magic string 'MPS7'
#  1 byte version
#  4 byte number of records
#
class MpsHeader < BinData::Record
  endian  :big
  string  :magic,       :length => 4
  uint8   :version,     :length => 1
  uint32  :num_records, :length => 4
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
  uint8   :record_type,   :length => 1
  uint32  :timestamp,     :length => 4   
  uint64  :uid,           :length => 8
  double  :credit,        :length => 8, :onlyif => :is_credit?
  double  :debit,         :length => 8, :onlyif => :is_debit?
  string  :start_autopay, :length => 0, :onlyif => :is_start_autopay?
  string  :end_autopay,   :length => 0, :onlyif => :is_end_autopay?

  def is_debit?
    return true if record_type == 0x00
  end
  def is_credit?
    return true if record_type == 0x01
  end
  def is_start_autopay?
    return true if record_type == 0x02
  end
  def is_end_autopay?
    return true if record_type == 0x03
  end
end

# read the header
io = File.open('txnlog.dat')
header = MpsHeader.read(io)

puts 'Header information'
puts '------------------'
puts 'Magic string: ' + header.magic
puts 'Version: ' + header.version.to_s
puts 'Total number of records found: ' + header.num_records.to_s
puts '------------------'

# set some vars
i = 0
debits = []
credits = []
end_autopays = []
start_autopays = []
noted_uid_balance = 0

# loop through the data
while i <= header.num_records
  i += 1
  r = MpsRecord.read(io)

  # I'm hopeful there's a better way to do this, but
  #   as yet I haven't been able to figure it out, since
  #   MPS returns empty strings for keys even when they 
  #   aren't found in the record. For example:
  #
  #   {:record_type=>0, :timestamp=>1389762186, :uid=>4280841143732940727, :debit=>313.44737449991106}
  #
  #   This record contains no :start_autopay key, but calling record.start_autopay
  #   returns an empty string rather than nil.
  #
  #   Following up with maintainer...
  r.to_s.match('end_autopay') ? start_autopays.push(1) : false
  r.to_s.match('start_autopay') ? end_autopays.push(1) : false

  # Same as above, but with records that don't actually
  #   contain a debit or a credit float, MPS inserts
  #   a float of 0.0 that we can use to ignore them
  debits.push(r.debit) unless r.debit == 0.0
  credits.push(r.credit) unless r.credit == 0.0

  # figure out our special friend's balance
  if r.uid == 2456938384156277127
    balance = r.credit - r.debit
    noted_uid_balance = noted_uid_balance + balance
  end
end

# sum our debits and credits arrays
total_debits = debits.inject(0){|sum,x| sum + x }
total_credits = credits.inject(0){|sum,x| sum + x }

puts 
puts 'Total debits: ' + total_debits.to_s
puts 'Total credits: ' + total_credits.to_s
puts 'Autopays started: ' + start_autopays.length.to_s
puts 'Autopays ended: ' + end_autopays.length.to_s
puts 'Balance for uid 2456938384156277127: ' + noted_uid_balance.to_s
