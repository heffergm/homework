# frozen_string_literal: true

require 'bindata'
require 'text-table'
require 'proto/meta'
require 'proto/getopts'
require_relative 'proto/include/methods.rb'

# top level
module Proto
  def self.start
    getopts = Proto.getopts

    # read the header
    begin
      io = File.open(getopts.datafile)
    rescue StandardError => e
      abort "Failed to open #{getopts.datafile}: #{e}"
    end
    header = MpsHeader.read(io)

    # basic check to make sure this is really MPS data
    if header.magic == 'MPS7'
      true
    else
      abort 'Aborting! This does not appear to be an MPS data file. ' \
        'Header magic is: ' + header.magic + ', expected MPS7.'
    end

    # build and display data
    mps_data = build_data(io, header)

    if getopts.list_uids == true
      puts list_uids(mps_data)
    else
      header_array = [['Header Information', ''],
                      ['Magic', header.magic],
                      ['Version', header.version],
                      ['Record count', header.num_records]]

      puts
      puts header_array.to_table(first_row_is_head: true)

      puts
      data_array = [['Total debits', sum_type(:debit, mps_data).to_s],
                    ['Total credits', sum_type(:credit, mps_data).to_s],
                    ['Autopays started', count_type(:start_autopay, mps_data).to_s],
                    ['Autopays ended', count_type(:end_autopay, mps_data).to_s],
                    ["Balance for UID #{getopts.uid}", find_user_balance(getopts.uid, mps_data).to_s]]

      puts data_array.to_table
      puts
    end
  end
end
