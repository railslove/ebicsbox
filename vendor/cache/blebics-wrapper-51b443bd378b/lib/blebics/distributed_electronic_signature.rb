class Blebics::DistributedElectronicSignature
  extend Forwardable

  attr_accessor :client
  def_delegators :client, :download, :session

  def initialize(client)
    self.client = client
  end

  def overview(order_types = nil)
    distributed_signature.get_overview(order_types)
  end

  def orders(order_types = nil)
    overview(order_types).get_orders()
  end

  def signer_infos_for(order_details)
    distributed_signature.get_details(order_details).get_signer_infos()
  end

  def sign_order(order_details)
    hvd = distributed_signature.get_details(order_details)
    distributed_signature.sign(order_details, hvd.get_data_digest().get_value())
  end

  private

  def distributed_signature
    @distributed_signature ||= DistributedSignature.new(session)
  end
end
