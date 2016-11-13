require 'spec_helper'
require 'xymonclient/helpers'

describe XymonClient do
  describe XymonClient::Client do
    let(:client) { XymonClient::Client.new(['foo', 'bar:19840']) }

    it 'should send a status with default lifetime (30m)' do
      allow(client).to receive(:_send) { '' }
      expect(client).to receive(:_send).with(
        kind_of(Hash),
        'status+30m my,host.myservice green all is good'
      )
      client.status('my.host', 'myservice', 'green', 'all is good')
    end
  end
end
