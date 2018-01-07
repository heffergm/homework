@options = {}
OptionParser.new do |opts|
  @options[:datafile] = 'txnlog.dat'
  opts.on(
    '--mps-datafile DATA_FILE',
    '-f DATA_FILE',
    String,
    'Location of the MPS data file (default: txnlog.dat).'
  ) do |datafile|
    @options[:datafile] = datafile
  end

  @options[:uid] = 2456938384156277127
  opts.on(
    '--uid UID',
    '-u UID',
    Integer,
    'UID to find the balance for (default: 2456938384156277127).'
  ) do |uid|
    @options[:uid] = uid
  end

  @options[:list_uids] = false
  opts.on(
    '--list-uids',
    '-l',
    'List unique UIDs in the MPS data set'
  ) do |list_uids|
    @options[:list_uids] = list_uids
  end
end.parse!
