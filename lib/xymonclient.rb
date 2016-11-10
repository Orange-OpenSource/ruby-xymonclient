require 'xymonclient/version'
require 'xymonclient/exception'
require 'xymonclient/discovery'
require 'socket'

module XymonClient
  ##
  # Client object for interacting with Xymon server(s)
  # Params:
  # - servers: array of string 'hostname' or 'hostname:port'
  #            (port default to 1984)
  class Client
    attr_reader :servers

    def initialize(servers = [])
      @servers = \
        if servers.empty?
          XymonClient::ServerDiscovery.find_from_file
        else
          _parse_servers(servers)
        end
    end

    def status(host, service, status, message, lifetime = '30m')
      raise XymonClient::InvalidDuration, lifetime unless valid_duration?(lifetime)
      raise XymonClient::InvalidStatus, status unless valid_status?(status)
      _send("status+#{lifetime} #{hostsvc(host, service)} #{status} #{message}")
    end

    def disable(host, service, duration, message)
      raise XymonClient::InvalidDuration, duration unless valid_duration?(duration)
      _send("disable #{hostsvc(host, service)} #{duration} #{message}")
    end

    def enable(host, service)
      _send("enable #{hostsvc(host, service)}")
    end

    def ack(host, service, duration, message)
      raise XymonClient::InvalidDuration, duration unless valid_duration?(duration)
      cookie = _send(
        "xymondboard host=#{host} test=#{service} fields=cookie"
      ).to_i
      _send("xymondack #{cookie} #{duration} #{message}") if cookie.nonzero?
    end

    def hostsvc(host, service)
      raise XymonClient::InvalidHost, host if host == ''
      raise XymonClient::InvalidService, service if service == ''
      host.tr('.', ',') + '.' + service
    end

    def valid_status?(status)
      %w(green yellow red purple blue clear).include?(status)
    end

    def valid_duration?(duration)
      duration =~ /^[0-9]+[hmwd]?$/
    end

    private

    def _send(message)
      # TODO: validate response from all servers ( and retry ?)
      @servers.each do |server|
        begin
          socket = TCPSocket.open(server[:host], server[:port])
          socket.puts message
          socket.close_write
          socket.gets
        ensure
          socket.close if socket
        end
      end
    end

    def _parse_servers(servers = [])
      raise XymonClient::NoXymonServerDefined if servers.empty?
      servers.map do |server|
        case server
        when /[^:]+:[0-9]*/
          { host: server.split(':')[0], port: server.split(':')[1].to_i }
        when /[^:]*/
          { host: server, port: 1984 }
        else
          raise XymonClient::InvalidServer, server
        end
      end
    end
  end
end
