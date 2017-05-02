module XymonClient
  class NoXymonServerDefined < StandardError
  end

  class InvalidStatus < StandardError
  end

  class InvalidServer < StandardError
  end

  class InvalidDuration < StandardError
  end

  class InvalidService < StandardError
  end

  class InvalidHost < StandardError
  end

  class InvalidServiceItem < StandardError
  end

  class PartialSendFailure < StandardError
  end

  class SendFailure < StandardError
  end
end
