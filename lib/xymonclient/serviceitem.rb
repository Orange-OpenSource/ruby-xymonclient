require 'xymonclient'

module XymonClient
  ##
  # Manage an item to monitor
  class ServiceItem
    attr_writer :value
    attr_reader :info

    def initialize(config)
      raise InvalidServiceItemName if config.fetch('label', '') == ''
      @info = {
        'label' => config['label'],
        'type' => config['type'],
        'description' => config.fetch('description', ''),
        'enabled' => config.fetch('enabled', true),
        'status' => 'purple'
      }
    end

    def value=(value)
      @info['value'] = value
      status
    end

    def status
      @info['status'] = \
        if !@info['enabled']
          'clear'
        elsif XymonClient::Client.valid_status?(@info['value'])
          @info['value']
        else
          'red'
        end
    end
  end

  ##
  class ServiceItemGauge < ServiceItem
    def initialize(config)
      super(config)
      @info['threshold'] = config.fetch('threshold', {})
      @info['nan_status'] = config.fetch('nan_status', 'green')
    end

    def status
      @info['status'] = \
        if !@info['enabled']
          'clear'
        elsif value.instance_of?(Float) && value.nan?
          @info['threshold'].fetch('nan_status', 'red')
        elsif @info['threshold'].key?('critical') && \
              _threshold_reached?('critical')
          'red'
        elsif @info['threshold'].key?('warning') && \
              _threshold_reached?('warning')
          'yellow'
        else
          'green'
        end
    end

    private

    def _threshold_reached?(threshold)
      value = @info['value']
      case @info['threshold'].fetch('order', '<')
      when '<'
        value < threshold
      when '>'
        value > threshold
      when '<='
        value <= threshold
      when '>='
        value >= threshold
      end
    end
  end

  ##
  class ServiceItemString < ServiceItem
    def initialize(config)
      super(config)
      @info['threshold'] = config.fetch('threshold', {})
    end

    def status
      @info['status'] = \
        if !@info['enabled']
          'clear'
        elsif @info['threshold'].key?('critical') && \
              _string_threshold_reached?('critical')
          'red'
        elsif @info['threshold'].key?('warning') && \
              _string_threshold_reached?('warning')
          'yellow'
        else
          'green'
        end
    end

    private

    def _threshold_reached?(threshold)
      inclusive = @info['threshold'].fetch('inclusive', true)
      values = @info['value']
      if values.instance_of?(Array)
        value_is_included = values.any? do |value|
          @info['threshold'][threshold].include?(value)
        end
      else
        value_is_included = @info['threshold'][threshold].include?(values)
      end
      (inclusive && value_is_included) || (!inclusive && !value_is_included)
    end
  end
end
