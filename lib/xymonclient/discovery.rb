require 'xymonclient/exception'

module XymonClient
  ##
  # static methods of servers discovery
  class ServerDiscovery
    def find_from_file(file = '/etc/xymon/xymonclient.cfg')
      result = []
      open(file, 'r').read.each_line do |line|
        next unless line =~ /^XYMSRV=/ || line =~ /^XYMSERVERS=/
        ip = line.scan(/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/)
        if ip[0] != '0.0.0.0' && line =~ /^XYMSRV=/
          result << xymsrv_ip
          break
        else
          result = ip
        end
      end
      raise NoXymonServerDefined if result.empty?
      result.map { |ip| { host: ip, port: 1984 } }
    end
  end
end
