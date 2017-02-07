require 'spec_helper'
require 'xymonclient/service'
require 'socket'

describe XymonClient do
  describe XymonClient::Service do
    let(:service) do
      XymonClient::Service.new(
        ['localhost'],
        'name' => 'service1',
        'host' => 'myhost',
        'header' => 'A sample header',
        'footer' => 'A sample footer',
        'items' => {
          'ITEM1' => {
            'label' => 'Gauge Item 1',
            'type' => 'gauge',
            'threshold' => {
              'order' => '<',
              'critical' => 5,
              'warning' => 10,
              'nan_status' => 'red'
            }
          },
          'ITEM2' => {
            'label' => 'String Item 2',
            'type' => 'string',
            'threshold' => {
              'inclusive' => false,
              'critical' => ['all is Ok !']
            }
          }
        }
      )
    end

    it 'should send a valid status and details' do
      service.update_item('ITEM1', 3)
      service.update_item('ITEM2', 'all is Ok !')
      allow(service).to receive(:_send) { '' }
      # rubocop:disable LineLength
      expect(service.status[0]).to eq('red')
      expect(service.status[1]).to match(
        /Generated at .* for 30m \nA sample header\n&red Gauge Item 1: 3\n&green String Item 2: all is Ok !\n\nA sample footer/
      )
      # rubocop:enable LineLength
    end

    context 'use attributes' do
      let(:service) do
        XymonClient::Service.new(
          ['localhost'],
          'name' => 'service1',
          'host' => 'myhost',
          'details_template' => '<% @items.each do |item| %>' \
                "&<%= item['status'] %> " \
                "<%= item['label'] %>: <%= item['value'] %>\n" \
                "foo : <%= item['attributes']['foo'] %>\n" \
                "<% end %>\n",
          'items' => {
            'ITEM1' => {
              'label' => 'String Item 2',
              'type' => 'string',
              'threshold' => {
                'inclusive' => false,
                'critical' => ['all is Ok !']
              }
            }
          }
        )
      end
      it 'should access item\'s attributes from template' do
        service.update_item('ITEM1', 'all is KO !', 'foo' => 'bar')
        allow(service).to receive(:_send) { '' }
        expect(service.status[1]).to match(
          /&red String Item 2: all is KO !\nfoo : bar\n/
        )
      end
    end
  end
end
