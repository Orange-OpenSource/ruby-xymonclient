require 'xymonclient/exception'

module XymonClient
  ##
  # static methods of servers discovery
  class ServerDiscovery
    def find_from_file(file = '/etc/xymon/xymonclient.cfg')
      result = []
      open(file, 'r').read.each_line do |line|
        if line =~ /^XYMSRV=/
          xymsrv_ip = line.scan(
            /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/
          )
          if xymsrv_ip[0] != '0.0.0.0'
            result << xymsrv_ip
            break
          end
        elsif line =~ /^XYMSERVERS=/
          result = line.scan(
            /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/
          )
        end
      end if File.exist?(file)
      raise NoXymonServerDefined if result.empty?
      result.map do |ip|
        { host: ip, port: 1984 }
      end
    end
  end
end
