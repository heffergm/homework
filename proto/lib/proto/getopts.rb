# frozen_string_literal: true

require 'optparse'

# top level
module Proto
  def self.getopts
    @getopts ||= GetOpts.new
  end

  # get options
  class GetOpts
    attr_reader :datafile, :uid, :list_uids

    def initialize
      OptionParser.new do |opts|
        @datafile = 'txnlog.dat'
        opts.on(
          '--mps-datafile DATA_FILE',
          '-f DATA_FILE',
          String,
          'Location of the MPS data file (default: txnlog.dat).'
        ) do |df|
          @datafile = df
        end

        @uid = 2456938384156277127
        opts.on(
          '--uid UID',
          '-u UID',
          Integer,
          'UID to find the balance for (default: 2456938384156277127).'
        ) do |id|
          @uid = id
        end

        @list_uids = false
        opts.on(
          '--list-uids',
          '-l',
          'List unique UIDs in the MPS data set'
        ) do |luid|
          @list_uids = luid
        end
      end.parse!
    end
  end
end
