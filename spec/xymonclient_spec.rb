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

    it 'could not send a status to some servers' do
      times_called = 0
      allow(client).to receive(:_send) do
        times_called += 1
        raise Errno::ECONNREFUSED if times_called == 2
      end
      expect do
        client.status('my.host', 'myservice', 'green', 'all is good')
      end.to raise_error(XymonClient::PartialSendFailure)
    end

    it 'could not send a status to all servers' do
      allow(client).to receive(:_send).and_raise Errno::ECONNREFUSED
      expect do
        client.status('my.host', 'myservice', 'green', 'all is good')
      end.to raise_error(XymonClient::SendFailure)
    end

    it 'retry sending a status to some servers' do
      client.retry_count = 2
      times_called = 0
      allow(client).to receive(:_send) do
        times_called += 1
        raise Errno::ECONNREFUSED if times_called == 1
      end
      expect do
        client.status('my.host', 'myservice', 'green', 'all is good')
      end.not_to raise_error
    end
  end
end
