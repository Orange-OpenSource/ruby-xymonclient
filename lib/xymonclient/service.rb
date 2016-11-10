require 'erb'
require 'xymonclient'
require 'xymonclient/serviceitem'

##
# Class container for isolating context for ERB templating
class ERBContext
  def initialize(hash)
    hash.each_pair do |key, value|
      instance_variable_set('@' + key.to_s, value)
    end
  end

  def get_binding
    binding
  end
end

module XymonClient
  ##
  # Manage a Service, can contains multiple items to monitor
  class Service
    attr_reader :name
    attr_accessor :status
    attr_reader :details
    # rubocop:disable LineLength
    DEFAULT_DETAILS_TEMPLATE = 'Generated at <%= @timestamp %> ' \
      'for <%= @lifetime %> \n\n<%= @header %>\n\n' \
      '<% @items.each do |item| %>' \
      '&<%= item[\'status\'] %> <%= item[\'label\'] %>: <%= item[\'value\'] %>\n' \
      '<% end %>\n' \
      '<%= @footer %>'.freeze
    # rubocop:enable LineLength

    def initialize(client, config)
      raise NotXymonClientInstance \
        unless client.instance_of?(XymonClient::Client)
      @client = client
      @info = { 'items' => {} }
      update_config(config)
    end

    def update_config(config)
      raise InvalidService if config.fetch('name', '') == ''
      raise InvalidService if config.fetch('host', '') == ''
      @info['name'] = config['name']
      @info['host'] = config['host']
      @info['details_template'] = config.fetch(
        'details_template',
        DEFAULT_DETAILS_TEMPLATE
      )
      @info['lifetime'] = config.fetch('lifetime', '30m')
      @info['enabled'] = config.fetch('enabled', true)
      @info['header'] = config.fetch('header', '')
      @info['footer'] = config.fetch('footer', '')
      if config.fetch('items', {}).empty?
        @info['items'] = {}
      else
        _update_items_config(config)
      end
      @info['status'] = @info.fetch('status', config.fetch('status', 'purple'))
    end

    def update_item(name, value)
      raise InvalidServiceItem unless @info['items'].include?(name)
      @info['items'][name].value = value
    end

    def send
      @client.status(@host, @name, @status, @details, @lifetime)
    end

    def status
      return 'clear' unless @enabled
      items_status = @items.map { |item| item.info['status'] }
      @info['status'] = unless items_status.empty?
                          if items_status.include?('red')
                            'red'
                          elsif items_status.include?('yellow') && \
                                @status != 'red'
                            'yellow'
                          else
                            'green'
                          end
                        end
      @info['status']
    end

    def details
      @info['timestamp'] = Time.now
      context = @info.reject { |key, _value| key == 'items' }
      context['items'] = @info['items'].map { |_key, value| value.info }
      ERB.new(@info['details_template']).result(
        ERBContext.new(context).get_binding
      )
    end

    private

    def _create_serviceitem(config)
      case config.fetch('type', '')
      when 'gauge'
        ServiceItemGauge.new(config)
      when 'string'
        ServiceItemString.new(config)
      else
        ServiceItem.new(config)
      end
    end

    def _update_items_config(config)
      # cleanup old items and update old items
      @info['items'].keep_if { |key, _value| config.fetch('items').key?(key) }
      @info['items'].each do |item_name, item_value|
        item_value.update_config(config['items'][item_name])
      end
      # add new items
      config['items'].each do |item_name, item_config|
        @info['items'][item_name] = _create_serviceitem(item_config)
      end
    end
  end
end
