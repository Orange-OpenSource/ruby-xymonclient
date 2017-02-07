require 'erb'
require 'xymonclient'
require 'xymonclient/helpers'
require 'xymonclient/serviceitem'

module XymonClient
  ##
  # Manage a Service, can contains multiple items to monitor
  class Service < XymonClient::Client
    attr_reader :name
    attr_accessor :status
    attr_reader :details
    DEFAULT_DETAILS_TEMPLATE = 'Generated at <%= @timestamp %> ' \
      "for <%= @lifetime %> \n<%= @header %>\n" \
      '<% @items.each do |item| %>' \
      "&<%= item['status'] %> <%= item['label'] %>: <%= item['value'] %>\n" \
      "<% end %>\n" \
      "<%= @footer %>\n".freeze

    def initialize(servers, config)
      super(servers)
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
      @info['purple_item_status'] = config.fetch('purple_item_status', 'red')
      @info['status'] = @info.fetch('status', config.fetch('status', 'purple'))
    end

    def update_item(name, value, attrs = {})
      raise InvalidServiceItem unless @info['items'].include?(name)
      @info['items'][name].value = value
      @info['items'][name].attributes = attrs
    end

    def status
      return 'clear' unless @info['enabled']
      items_status = @info['items'].map do |_key, value|
        if value.info['status'] == 'purple'
          @info['purple_item_status']
        else
          value.info['status']
        end
      end
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
      details = _details
      super(
        @info['host'],
        @info['name'],
        @info['status'],
        details,
        @info['lifetime']
      )
      [@info['status'], details]
    end

    def enable
      super(@info['host'], @info['name'])
    end

    def disable(duration, message)
      super(@info['host'], @info['name'], duration, message)
    end

    def board(fields = [])
      super(@info['host'], @info['name'], fields)
    end

    def ack(duration, message)
      super(@info['host'], @info['name'], duration, message)
    end

    private

    def _details
      @info['timestamp'] = Time.now
      context = @info.reject { |key, _value| key == 'items' }
      context['items'] = @info['items'].map { |_key, value| value.info }
      ERB.new(@info['details_template']).result(
        XymonClient::ERBContext.new(context).context
      )
    end

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
