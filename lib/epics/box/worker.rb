$stdout.sync = true

class Epics::Box::Worker

  def initialize
    @queue  ||= Epics::Box::QUEUE.new
    @logger ||= Logger.new(STDOUT)
  end

  def process!
    @queue.process!
  end

  # def listen!
  #   @_redis = Redis.new
  #   @redis.subscribe("cdd", "cd1", "ctt", "web", "sta") do |on|
  #     on.message do |channel, message|
  #       @logger.info("#{channel}: #{message}")
  #       message = JSON.parse(message, symbolize_names: true)

  #       case channel
  #       when "cdd"
  #         @logger.info("debit")
  #         @_redis.set(message[:document], message[:callback])
  #       when "cd1"
  #         @logger.info("debit")
  #         @_redis.set(message[:document], message[:callback])
  #       when "ctt"
  #         @logger.info("credit")
  #         @_redis.set(message[:document], message[:callback])
  #       when "sta"
  #         File.open(File.expand_path("~/sta.mt940")).each do |line|
  #           if trx = @_redis.get(line.gsub!(/\n/,''))
  #             @logger.info("#{line} -> found")
  #             @_redis.publish 'web', {callback: trx}.to_json
  #           else
  #             @logger.debug("#{line} -> not found")
  #           end
  #         end
  #       when "web"
  #         HTTParty.post(message[:callback], body: Time.now.to_s)
  #         @logger.info("callback")
  #       end
  #     end
  #   end
  # end
end


