require 'spec_helper'
require 'xymonclient/service'

describe XymonClient do
  describe XymonClient::Client do
    let(:client) { XymonClient::Client.new(['foo', 'bar:19840']) }

    it 'initialize should parse servers list' do
      expect(client.servers).to eq(
        [{ host: 'foo', port: 1984 }, { host: 'bar', port: 19_840 }]
      )
    end

    it 'hostsvc should return xymon encoded host/service' do
      expect(client.hostsvc('foo.bar', 'sensor')).to eq('foo,bar.sensor')
    end
  end

  describe XymonClient::Service do
    let(:service) do
      XymonClient::Service.new(
        XymonClient::Client.new(['localhost']),
        'name' => 'SVC',
        'host' => 'localhost',
        'header' => 'One header',
        'footer' => 'One footer',
        'items' => {
          'ITEM1' => {
            'label' => 'Item 1',
            'type' => 'gauge',
            'threshold' => {
              'order' => '<',
              'critical' => 5,
              'warning' => 10,
              'nan_status' => 'red'
            }
          },
          'ITEM2' => {
            'label' => 'Item 2',
            'type' => 'string',
            'threshold' => {
              'inclusive' => false,
              'critical' => ['alert']
            }
          }
        }
      )
    end

    it 'should generate details' do
      # rubocop:disable LineLength
      expect(service.details).to match(
        /Generated at .* for 30m \\n\\nOne header\\n\\n&purple Item 1: \\n&purple Item 2: \\n\\nOne footer/
      )
      # rubocop:enable LineLength
    end
  end
end
