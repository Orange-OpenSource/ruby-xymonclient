require 'xymonclient'

module XymonClient
  ##
  # Manage an item to monitor
  class ServiceItem
    attr_writer :value
    attr_reader :info

    def initialize(config)
      raise InvalidServiceItemName if config.fetch('label', '') == ''
      raise InvalidServiceItemType if config.fetch('type', '') == ''
      @info = {
        'label' => config['label'],
        'type' => config['type'],
        'description' => config.fetch('description', ''),
        'enabled' => config.fetch('enabled', true),
        'nan_status' => config.fetch('nan_status', 'green'),
        'threshold' => config.fetch('threshold', {}),
        'status' => 'purple'
      }
    end

    def value=(value)
      @info['value'] = value
      case @info['type']
      when 'gauge'
        @info['status'] = _get_status_gauge(value)
      when 'string'
        @info['status'] = _get_status_string(value)
      end
    end

    private

    def _threshold_reached?(value, threshold, order)
      case order
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

    def _get_status_gauge(value)
      return 'clear' unless @info['enabled']
      return @info['threshold'].fetch('nan_status', 'red') \
        if value.instance_of?(Float) && value.nan?
      order = @info['threshold'].fetch('order', '<')
      if @info['threshold'].key?('critical')
        if _threshold_reached?(value, @info['threshold']['critical'], order)
          'red'
        elsif @info['threshold'].key?('warning') && \
              _threshold_reached?(value, @info['threshold']['warning'], order)
          'yellow'
        else
          'green'
        end
      elsif @info['threshold'].key?('warning') && \
            _threshold_reached?(value, @info['threshold']['warning'], order)
        'yellow'
      else
        'green'
      end
    end

    def _get_status_string(values)
      return 'clear' unless @info['enabled']
      inclusive = @info['threshold'].fetch('inclusive', true)
      if @info['threshold'].key?('critical')
        if (inclusive && values.any? { |value| @info['threshold']['critical'].include?(value) }) || \
           (!inclusive && !values.any? { |value| @info['threshold']['critical'].include?(value) })
          'red'
        elsif @info['threshold'].key?('warning') && \
              ((inclusive && values.any? { |value| @info['threshold']['warning'].include?(value) }) || \
              (!inclusive && !values.any? { |value| @info['threshold']['warning'].include?(value) }))
          'yellow'
        else
          'green'
        end
      elsif @info['threshold'].key?('warning') && \
            ((inclusive && values.any? { |value| @info['threshold']['warning'].include?(value) }) || \
            (!inclusive && !values.any? { |value| @info['threshold']['warning'].include?(value) }))
        'yellow'
      else
        'green'
      end
    end
  end
end
