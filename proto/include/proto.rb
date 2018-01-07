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

# build the structured data set
def build_data(datafile, mps_header)
  array = []

  i = 0
  while i < mps_header.num_records
    i += 1
    array.push(MpsRecord.read(datafile).snapshot)
  end

  array
end

def find_user_balance(uid, array)
  debits = []
  credits = []

  array.each do |i|
    if i[:uid] == uid
      i[:debit].nil? ? true : debits.push(i[:debit])
      i[:credit].nil? ? true : credits.push(i[:credit])
    end
  end

  total_credits = credits.inject(:+)
  total_debits = debits.inject(:+)

  total_credits.nil? ? total_credits = 0 : false
  total_debits.nil? ? total_debits = 0 : false
  
  balance = total_credits - total_debits
  balance
end

def sum_type(type, array)
  results = []
  array.each do |i|
    i[type].nil? ? true : results.push(i[type])
  end

  sum = results.inject(:+)
  sum
end

def count_type(type, array)
  counter = 0
  array.each do |i|
    i[type].nil? ? true : counter += 1
  end

  counter
end
