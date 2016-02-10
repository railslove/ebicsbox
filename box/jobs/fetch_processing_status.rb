module Box
  module Jobs
    class FetchProcessingStatus
      def self.process!(message)
        log(:debug, "Check orders.")
        message[:account_ids].each do |account_id|
          log(:debug, "Reconciling orders by HAC.", { account_id: account_id })
          remote_records(account_id).each do |data|
            update_transaction(account_id, data)
          end
        end
      end

      def self.update_transaction(account_id, info)
        if order_id = info[:ids]["OrderID"]
          # TODO: Scope this by account? Just as a security precaution?
          if trx = Transaction[ebics_order_id: order_id]
            # Extract this to transaction #set_state_from
            old_status = trx.status
            new_status = trx.set_state_from(info[:action], info[:reason_code])
            if old_status != new_status
              log(:debug, "Status changed. From #{old_status} to #{new_status}.", { account_id: account_id, ebics_order_id: order_id })
            end
            log(:info, "#{trx.pk} - #{info[:action]} for #{info[:ids]["OrderID"]} with #{info[:reason_code]}.", { account_id: account_id })
          else
            log(:info, "No transactions with order id found.", { account_id: account_id, order_id: order_id })
          end
        else
          log(:debug, "No order id found.", { account_id: account_id, action: info[:action], reason: info[:reason_code], data: info[:ids] })
        end
      end

      def self.remote_records(account_id)
        account = Account[account_id]
        file = account.transport_client.HAC
        Nokogiri::XML(file).remove_namespaces!.xpath("//OrgnlPmtInfAndSts").map do |info|
          {
            reason_code: info.xpath("./StsRsnInf/Rsn/Cd").text,
            action: info.xpath("./OrgnlPmtInfId").text.downcase,
            ids: info.xpath("./StsRsnInf/Orgtr/Id/OrgId/Othr").inject({}) do |memo, node|
              memo[node.at_xpath("./SchmeNm/Prtry").text] = node.at_xpath("./Id").text
              memo
            end
          }
        end
      end

      def self.log(type, message, data = {})
        data = data.map { |k, v| "#{k}=#{v}" }.join(' ')
        Box.logger.public_send(type, "[Jobs::FetchProcessingStatus] #{message} #{data}")
      end
    end
  end
end
