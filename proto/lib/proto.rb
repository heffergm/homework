# frozen_string_literal: true

require 'bindata'
require 'rainbow'
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
      puts
      puts Rainbow('Header information').green
      puts Rainbow('------------------').red
      puts Rainbow('Magic: ').blue + header.magic
      puts Rainbow('Version: ').blue + header.version.to_s
      puts Rainbow('Record count: ').blue + header.num_records.to_s
      puts Rainbow('------------------').red

      puts
      puts Rainbow('Total debits: ').yellow + sum_type(:debit, mps_data).to_s
      puts Rainbow('Total credits: ').yellow + sum_type(:credit, mps_data).to_s
      puts Rainbow('Autopays started: ').yellow + count_type(:start_autopay, mps_data).to_s
      puts Rainbow('Autopays ended: ').yellow + count_type(:end_autopay, mps_data).to_s

      # color the output if the UID wasn't found
      print Rainbow("Balance for uid #{getopts.uid}: ").yellow
      ub = find_user_balance(getopts.uid, mps_data).to_s
      if ub == 'UID NOT FOUND'
        puts Rainbow(ub).red.bright
      else
        puts ub
      end
      puts
    end
  end
end
