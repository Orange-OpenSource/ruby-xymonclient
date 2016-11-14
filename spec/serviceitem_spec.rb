require 'spec_helper'
require 'xymonclient'
require 'xymonclient/serviceitem'

describe XymonClient do
  describe XymonClient::ServiceItem do
    let(:config) { { 'label' => 'Item 1' } }

    it 'should return purple status at start' do
      expect(described_class.new(config).status).to eq('purple')
    end

    it 'should return red status on bad value' do
      baditem = described_class.new(config)
      baditem.value = 'badstatus'
      expect(baditem.status).to eq('red')
    end

    it 'should return clear status if disabled' do
      config['enabled'] = false
      expect(described_class.new(config).status).to eq('clear')
    end
  end

  describe XymonClient::ServiceItemGauge do
    let(:config) { { 'label' => 'Item 1' } }

    it 'should return red status when value is above critical threshold' do
      config['threshold'] = { 'order' => '>', 'critical' => 10, 'warning' => 5 }
      item = described_class.new(config)
      item.value = 11
      expect(item.status).to eq('red')
    end

    it 'should return yellow status when value is between warning and ' \
       'critical threshold' do
      config['threshold'] = { 'order' => '>', 'critical' => 10, 'warning' => 5 }
      item = described_class.new(config)
      item.value = 7
      expect(item.status).to eq('yellow')
    end

    it 'should return green status when value is under warning threshold' do
      config['threshold'] = { 'order' => '>', 'critical' => 10, 'warning' => 5 }
      item = described_class.new(config)
      item.value = 3
      expect(item.status).to eq('green')
    end
  end

  describe XymonClient::ServiceItemString do
    describe 'inclusive' do
      let(:config) { { 'label' => 'Item 1', 'threshold' => {'inclusive' => true, 'critical' => ['foo'], 'warning' => ['bar']}} }
      it 'should return red status when value is included in critical threshold' do
        item = described_class.new(config)
        item.value = 'foo'
        expect(item.status).to eq('red')
      end

      it 'should return yellow status when value is included in warning threshold' do
        item = described_class.new(config)
        item.value = 'bar'
        expect(item.status).to eq('yellow')
      end

      it 'should return green status when values is not included in critical/warning threshold' do
        item = described_class.new(config)
        item.value = 'other'
        expect(item.status).to eq('green')
      end
    end

    describe 'exclusive' do
      let(:config) { { 'label' => 'Item 1', 'threshold' => {'inclusive' => false, 'critical' => ['foo'], 'warning' => ['bar']}} }
      it 'should return red status when "foo" is not included in critical threshold' do
        item = described_class.new(config)
        item.value = ['bar']
        expect(item.status).to eq('red')
      end

      it 'should return yellow status when "bar" is not included in warning threshold' do
        item = described_class.new(config)
        item.value = ['foo']
        expect(item.status).to eq('yellow')
      end

      it 'should return green status when all values are included in critical/warning threshold' do
        item = described_class.new(config)
        item.value = ['foo', 'bar']
        expect(item.status).to eq('green')
      end
    end
  end
end
