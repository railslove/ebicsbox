require 'beaneater'

class Epics::Box::Queue::Beanstalk

  def initialize
    @beanstalk   ||= Beaneater::Pool.new(['localhost:11300'])
    @persistence ||= Redis.new
    @logger ||= Logger.new(STDOUT)
  end

  def publish(queue, payload, options = {})
    @beanstalk.tubes[queue.to_s].put payload.to_json
  end

  def process!
    @beanstalk.jobs.register('cdd') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      pain = Nokogiri::XML(Base64.strict_decode64(message[:document]))

      @persistence.set(pain.at_xpath("//xmlns:EndToEndId").text, message[:callback])
      @logger.info("debit")
    end

    @beanstalk.jobs.register('cd1') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      pain = Nokogiri::XML(Base64.strict_decode64(message[:document]))

      @persistence.set(pain.at_xpath("//xmlns:EndToEndId").text, message[:callback])
      @logger.info("debit")
    end

    @beanstalk.jobs.register('cct') do |job|
      message = JSON.parse(job.body, symbolize_names: true)
      pain = Nokogiri::XML(Base64.strict_decode64(message[:document]))

      @persistence.set(pain.at_xpath("//xmlns:EndToEndId").text, message[:callback])
      @logger.info("credit")
    end

    @beanstalk.jobs.register('sta') do |job|
      File.open(File.expand_path("~/sta.mt940")).each do |line|
        if trx = @persistence.get(line.gsub!(/\n/,''))
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

end