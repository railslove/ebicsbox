$stdout.sync = true

class Epics::Http::Worker



  def initialize
    @beanstalk  ||= Beaneater::Pool.new(['localhost:11300'])
    @redis  ||= Redis.new
    @logger ||= Logger.new(STDOUT)
  end

  def process!
    @beanstalk.jobs.register('cdd') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      pain = Nokogiri::XML(Base64.strict_decode64(message[:document]))

      @redis.set(pain.at_xpath("//xmlns:EndToEndId").text, message[:callback])
      @logger.info("debit")
    end

    @beanstalk.jobs.register('cd1') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      pain = Nokogiri::XML(Base64.strict_decode64(message[:document]))

      @redis.set(pain.at_xpath("//xmlns:EndToEndId").text, message[:callback])
      @logger.info("debit")
    end

    @beanstalk.jobs.register('cct') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      pain = Nokogiri::XML(Base64.strict_decode64(message[:document]))

      @redis.set(pain.at_xpath("//xmlns:EndToEndId").text, message[:callback])
      @logger.info("credit")
    end

    @beanstalk.jobs.register('sta') do |job|
      File.open(File.expand_path("~/sta.mt940")).each do |line|
        if trx = @redis.get(line.gsub!(/\n/,''))
          @logger.info("#{line} -> found")
          @beanstalk.tubes['web'].put({callback: trx}.to_json)
        else
          @logger.debug("#{line} -> not found")
        end
      end
    end

    @beanstalk.jobs.register('web') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      HTTParty.post(message[:callback], body: Time.now.to_s)
      @logger.info("callback")
    end

    @beanstalk.jobs.process!
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


