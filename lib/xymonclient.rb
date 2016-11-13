require 'xymonclient/version'
require 'xymonclient/exception'
require 'xymonclient/discovery'
require 'xymonclient/helpers'
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
      raise XymonClient::InvalidDuration, lifetime \
        unless XymonClient.valid_duration?(lifetime)
      raise XymonClient::InvalidStatus, status \
        unless XymonClient.valid_status?(status)
      _send_to_all(
        "status+#{lifetime} " \
        "#{XymonClient.hostsvc(host, service)} #{status} #{message}"
      )
    end

    def disable(host, service, duration, message)
      raise XymonClient::InvalidDuration, duration \
        unless XymonClient.valid_duration?(duration)
      _send_to_all(
        "disable #{XymonClient.hostsvc(host, service)} #{duration} #{message}"
      )
    end

    def enable(host, service)
      _send_to_all("enable #{XymonClient.hostsvc(host, service)}")
    end

    def drop(host, service = '')
      _send_to_all("drop #{host} #{service}")
    end

    def board(host, service, fields = [])
      response = {}
      @servers.each do |server|
        response[server] = _send(
          server,
          "xymondboard host=#{host} test=#{service} fields=#{fields.join(';')}"
        )
      end
      response
    end

    def ack(host, service, duration, message)
      raise XymonClient::InvalidDuration, duration \
        unless XymonClient.valid_duration?(duration)
      cookies = board(host, service, ['cookie'])
      @servers.each do |server|
        _send(
          server,
          "xymondack #{cookies[server].to_i} #{duration} #{message}"
        ) if cookies[server].to_i != -1
      end
    end

    private

    def _send_to_all(message)
      @servers.each { |server| _send(server, message) }
    end

    def _send(server, message)
      # TODO: validate response from all servers ( and retry ?)
      socket = TCPSocket.open(server[:host], server[:port])
      socket.puts message
      socket.close_write
      socket.gets
    ensure
      socket.close if socket
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
