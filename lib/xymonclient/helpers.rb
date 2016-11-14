module XymonClient
  TIMESTRING_DEFINITION = {
    '' => 60,
    'm' => 60,
    'h' => 60 * 60,
    'd' => 60 * 60 * 24,
    'w' => 60 * 60 * 24 * 7
  }.freeze

  def self.valid_status?(status)
    %w(green yellow red purple blue clear).include?(status)
  end

  def self.valid_duration?(duration)
    duration =~ /^[0-9]+[hmwd]?$/
  end

  def self.timestring_to_time(timestring)
    time_matched = /^([0-9]+)([hmdw]{0,1})$/.match(timestring)
    raise InvalidTimeString unless time_matched
    time_matched[1].to_i * TIMESTRING_DEFINITION[time_matched[2]]
  end

  def self.hostsvc(host, service)
    raise XymonClient::InvalidHost, host if host == ''
    raise XymonClient::InvalidService, service if service == ''
    host.tr('.', ',') + '.' + service
  end

  ##
  # Class container for isolating context for ERB templating
  class ERBContext
    def initialize(hash)
      hash.each_pair do |key, value|
        instance_variable_set('@' + key.to_s, value)
      end
    end

    def context
      binding
    end
  end
end
