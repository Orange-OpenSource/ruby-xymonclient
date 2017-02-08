require 'erb'
require 'xymonclient'
require 'xymonclient/helpers'
require 'xymonclient/serviceitem'

module XymonClient
  ##
  # Manage a Service, can contains multiple items to monitor
  class Service < XymonClient::Client
    attr_reader :name
    attr_reader :status
    attr_reader :items
    attr_accessor :enabled
    attr_accessor :lifetime

    DEFAULT_DETAILS_TEMPLATE = \
      "Generated at <%= @timestamp %> for <%= @lifetime %> \n" \
      '<% @items.each do |item| %>' \
      "&<%= item['status'] %> <%= item['label'] %>: <%= item['value'] %>\n" \
      "<% end %>\n".freeze

    def initialize(servers, config)
      super(servers)
      @items = {}
      @current_state = 'purple'
      update_config(config)
    end

    def update_config(config)
      raise InvalidService if config.fetch('name', '') == ''
      raise InvalidService if config.fetch('host', '') == ''
      @name = config['name']
      @host = config['host']
      @details_template = config.fetch(
        'details_template',
        DEFAULT_DETAILS_TEMPLATE
      )
      @lifetime = config.fetch('lifetime', '30m')
      @enabled = config.fetch('enabled', true)
      if config.fetch('items', {}).empty?
        @items = {}
      else
        _update_items_config(config['items'])
      end
      @purple_item_status = config.fetch('purple_item_status', 'red')
    end

    def update_item(name, value, attrs = {})
      raise InvalidServiceItem unless @items.include?(name)
      @items[name].value = value
      @items[name].attributes.merge!(attrs)
    end

    def status
      @timestamp = Time.now
      return 'clear' unless @enabled
      items_status = @items.map do |_key, value|
        if value.status == 'purple'
          @purple_item_status
        else
          value.status
        end
      end
      @current_state = unless items_status.empty?
                         if items_status.include?('red')
                           'red'
                         elsif items_status.include?('yellow') && \
                               @current_state != 'red'
                           'yellow'
                         else
                           'green'
                         end
                       end
      details = _details
      super(@host, @name, @current_state, details, @lifetime)
      [@current_state, details]
    end

    def enable
      super(@host, @name)
    end

    def disable(duration, message)
      super(@host, @name, duration, message)
    end

    def board(fields = [])
      super(@host, @name, fields)
    end

    def ack(duration, message)
      super(@host, @name, duration, message)
    end

    private

    def _details
      context = {
        'name' => @name,
        'host' => @host,
        'status' => @current_state,
        'items' => {},
        'enabled' => @enabled,
        'lifetime' => @lifetime,
        'timestamp' => @timestamp
      }
      context['items'] = @items.map { |_name, item| item.context }
      ERB.new(@details_template).result(
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

    def _update_items_config(items)
      # cleanup old items and update old items
      @items.keep_if { |key, _value| items.key?(key) }
      @items.each do |item_name, item_value|
        item_value.update_config(items[item_name])
      end
      # add new items
      items.each do |item_name, item_config|
        @items[item_name] = _create_serviceitem(item_config) \
          unless @items.keys.include?(item_name)
      end
    end
  end
end
