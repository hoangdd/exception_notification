Original documentation: [smartinez87/exception_notification](https://github.com/smartinez87/exception_notification).

Config multi slack channels:
```ruby
Rails.application.config.middleware.use ExceptionNotification::Rack,
  :multi_slack => {
    :webhook_url => "[Your webhook url]",
    :channels => {
        "default" => "#default_channel",
        "exception_name1" => "#channel1",
        "exception_name2" => "#channel2",
        "exception_name3" => "#channel4",
      },
    :additional_parameters => {
      :icon_url => "http://image.jpg",
      :mrkdwn => true
    }
  }
```
When one exception is raised, message will be sent to corresponding channel. In other case, message will be sent to default channel.