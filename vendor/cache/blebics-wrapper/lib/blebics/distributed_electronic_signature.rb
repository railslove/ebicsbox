require 'bigdecimal'

module Blebics
  class Order
    attr_accessor :client, :raw_data

    def initialize(client, data)
      self.client = client
      self.raw_data = data
    end

    def order_id
      raw_data.get_order_id.get_value
    end

    def order_type
      raw_data.get_order_type.get_value
    end

    def digest
      raw_data.get_data_digest.value
    end

    def digest_signature_version
      raw_data.get_data_digest.get_signature_version.get_value
    end

    def items
      @details ||= begin
        if raw_data.get_order_details_available.boolean_value
          # TODO: Parse and return a proper object
          client.fetch_order_details(raw_data, 0, 0)
        else
          []
        end
      end
    end

    def display_file
      @display_file ||= begin
        java.lang.String.new(client.get_details(raw_data).get_display_file.value, "ISO-8859-1").to_s
      end
    end

    def total_orders
      raw_data.get_total_orders.int_value
    end

    def total_amount
      BigDecimal.new(raw_data.get_total_amount.get_value.to_s)
    end

    def total_amount_type
      raw_data.get_total_amount.is_credit.boolean_value ? "credit" : "debit"
    end

    def originator
      @originator ||= begin
        o = raw_data.get_originator_info
        {
          name: o.get_name.get_value,
          partner_id: o.get_partner_id.get_value,
          user_id: o.get_user_id.get_value,
          timestamp: Time.at(o.get_timestamp.get_date.get_time/1000),
        }
      end
    end

    def signers
      raw_data.get_signers.map do |signer|
        {
          name: signer.get_name.get_value,
          partner_id: signer.get_partner_id.get_value,
          user_id: signer.get_user_id.get_value,
          signature_class: signer.get_permission.get_authorisation_level,
        }
      end
    end

    def required_signatures
      signing_info.get_num_sig_required
    end

    def applied_signatures
      signing_info.get_num_sig_done
    end

    def ready_for_signature
      signing_info.is_ready_to_be_signed
    end

    def as_json(options = {})
      {
        order_id: order_id,
        order_type: order_type,
        total_amount: total_amount,
        total_amount_type: total_amount_type,
        total_orders: total_orders,
        digest: digest,
        digest_signature_version: digest_signature_version,
        originator: originator,
        signers: signers,
        required_signatures: required_signatures,
        applied_signatures: applied_signatures,
        ready_for_signature: ready_for_signature,
        file: display_file,
      }
    end

    private

    def details
      @details ||= client.get_details(raw_data)
    end

    def signing_info
      @signing_info ||= raw_data.get_signing_info
    end
  end

  class DistributedElectronicSignature
    extend Forwardable

    attr_accessor :client
    def_delegators :client, :download, :session

    def initialize(client)
      self.client = client
    end

    # Perfom a HVZ to fetch detailed information for all orders
    def overview(order_types = nil)
      distributed_signature.get_detailed_overview(order_types).get_orders.to_a.map do |order|
        Order.new(distributed_signature, order)
      end
    end

    def orders(order_types = nil)
      overview(order_types).get_orders()
    end

    def signer_infos_for(order_details)
      distributed_signature.get_details(order_details).get_signer_infos()
    end

    def sign_order(order_id)
      order = find_order(order_id)
      digest = order.get_data_digest().get_value()
      distributed_signature.sign(order, digest).get_value
    end

    def cancel_order(order_id)
      order = find_order(order_id)
      digest = order.get_data_digest().get_value()
      distributed_signature.cancel(order, digest).get_value
    end

    # private

    def find_order(order_id)
      distributed_signature.get_detailed_overview(nil).get_orders.to_a.select{ |order| order.get_order_id.get_value == order_id }.first
    end

    def distributed_signature
      @distributed_signature ||= DistributedSignature.new(session)
    end
  end
end
