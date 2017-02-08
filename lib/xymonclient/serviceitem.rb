require 'xymonclient'
require 'xymonclient/helpers'

module XymonClient
  ##
  # Manage an item to monitor
  class ServiceItem
    attr_accessor :value
    attr_accessor :attributes
    attr_accessor :enabled
    attr_accessor :description
    attr_accessor :lifetime
    attr_accessor :label
    attr_reader :status
    attr_reader :time

    def initialize(config)
      raise InvalidServiceItemName if config.fetch('label', '') == ''
      @time = Time.at(0)
      @threshold = config.fetch('threshold', {})
      @attributes = config.fetch('attributes', {})
      update_config(config)
    end

    def value=(value)
      @value = value
      @time = Time.now
      status
    end

    def status
      @status = \
        if !@enabled
          'clear'
        elsif Time.now - @time > \
              XymonClient.timestring_to_time(@lifetime)
          'purple'
        elsif XymonClient.valid_status?(@value)
          @value
        else
          'red'
        end
    end

    def update_config(config)
      raise InvalidServiceItemName if config.fetch('label', '') == ''
      @label = config['label']
      @description = config.fetch('description', '')
      @enabled = config.fetch('enabled', true)
      @lifetime = config.fetch('lifetime', '30m')
      @threshold = config.fetch('threshold', {})
      @attributes.merge!(config.fetch('attributes', {}))
    end

    def context
      {
        'label' => @label,
        'description' => @description,
        'enabled' => @enabled,
        'lifetime' => @lifetime,
        'timestamp' => @timestamp,
        'threshold' => @threshold,
        'attributes' => @attributes,
        'status' => @status,
        'value' => @value
      }
    end
  end

  ##
  class ServiceItemGauge < ServiceItem
    def initialize(config)
      super(config)
      update_config(config)
    end

    def status
      @status = \
        if !@enabled
          'clear'
        elsif Time.now - @time > \
              XymonClient.timestring_to_time(@lifetime)
          'purple'
        elsif value.instance_of?(Float) && value.nan?
          @threshold.fetch('nan_status', 'red')
        elsif @threshold.key?('critical') && \
              _threshold_reached?('critical')
          'red'
        elsif @threshold.key?('warning') && \
              _threshold_reached?('warning')
          'yellow'
        else
          'green'
        end
    end

    def update_config(config)
      super(config)
      @nan_status = config.fetch('nan_status', 'green')
    end

    def context
      {
        'nan_status' => @nan_status
      }.merge(super)
    end

    private

    def _threshold_reached?(threshold)
      case @threshold.fetch('order', '<')
      when '<'
        @value < @threshold[threshold]
      when '>'
        @value > @threshold[threshold]
      when '<='
        @value <= @threshold[threshold]
      when '>='
        @value >= @threshold[threshold]
      end
    end
  end

  ##
  class ServiceItemString < ServiceItem
    def status
      @status = \
        if !@enabled
          'clear'
        elsif Time.now - @time > \
              XymonClient.timestring_to_time(@lifetime)
          'purple'
        elsif @threshold.key?('critical') && \
              _threshold_reached?('critical')
          'red'
        elsif @threshold.key?('warning') && \
              _threshold_reached?('warning')
          'yellow'
        else
          'green'
        end
    end

    private

    def _threshold_reached?(threshold)
      inclusive = @threshold.fetch('inclusive', true)
      values = @value
      if values.instance_of?(Array)
        value_is_included = values.any? do |value|
          @threshold[threshold].include?(value)
        end
      else
        value_is_included = @threshold[threshold].include?(values)
      end
      (inclusive && value_is_included) || (!inclusive && !value_is_included)
    end
  end
end
