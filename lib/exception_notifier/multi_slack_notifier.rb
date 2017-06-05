module ExceptionNotifier
  class MultiSlackNotifier < SlackNotifier
    include ExceptionNotifier::BacktraceCleaner
 
    def initialize(options)
      super
      begin
        # Channel control
        @channels = options.fetch(:channels)
        @default_channel = @channels["default"]
      rescue
        @notifier = nil
      end
    end
 
    def call(exception, options={})
      errors_count = options[:accumulated_errors_count].to_i
      exception_name = "*Exception*: `#{exception.class.to_s}` \n"
      fields = []
 
      text = exception_name
      message_text = ">>> " + exception.message.gsub("`", "'") + "\n\n"
 
      if options[:env].nil?
        data = options[:data] || {}
        env_text = "*Process:* occured in background\n"
      else
        env = options[:env]
        data = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})
 
        kontroller = env['action_controller.instance']
        request = "`#{env['REQUEST_METHOD']}` <#{env['REQUEST_URI']}>"
        env_text = "*Request*: #{request}\n"
        env_text += "*Process*: `#{kontroller.class.name}##{kontroller.action_name}`" if kontroller
        env_text += "\n"
      end
 
      fields.push({ title: 'Message', value: message_text })
      fields.push({ title: '', value: env_text })
      fields.push({ title: 'Hostname', value: Socket.gethostname })
 
      if exception.backtrace
        backtrace = exception.backtrace.first(@backtrace_lines)
        formatted_backtrace = "```#{backtrace.join("\n")}```"
        gem_paths = ENV["GEM_PATH"].split(':')
        gem_paths.each do |path|
          formatted_backtrace.gsub! path.to_s, "GEM_PATH"
        end
        formatted_backtrace.gsub! Rails.root.to_s, ""
 
        fields.push({ title: 'Backtrace', value: formatted_backtrace, short: true })
      end
 
      unless data.empty?
        deep_reject(data, @ignore_data_if) if @ignore_data_if.is_a?(Proc)
        data_string = data.map{|k,v| "#{k}: #{v}"}.join("\n")
        fields.push({ title: 'Data', value: "```#{data_string}```" })
      end
 
      attchs = [color: @color, text: text, fields: fields, mrkdwn_in: %w(text fields)]
 
      if valid?
        @message_opts[:channel] = @channels[exception.class.name] || @default_channel
        send_notice(exception, options, text, @message_opts.merge(attachments: attchs)) do |msg, message_opts|
          @notifier.ping '', message_opts
        end
      end
    end
  end
 end