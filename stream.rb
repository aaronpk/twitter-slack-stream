require 'bundler'
Bundler.require :default
require 'yaml'

#logger = Logger.new('search.log')
logger = Logger.new(STDOUT)

$user_ids = JSON.parse(IO.read('user_ids.json'))
$usernames = JSON.parse(IO.read('usernames.json'))
$config = YAML.load(IO.read('config.yml'))


def process_tweet(logger, tweet)
  if tweet.text.downcase.match Regexp.new($config['regex']) \
    and tweet.retweeted_status.nil? \
    and $usernames.include? tweet.user.screen_name

    #jj tweet.to_hash

    # Build the string to send to Slack.
    # Slack auto-expands twitter URLs so we only need to send the URL.
    # We can set the "display text" of the URL to a space character, which
    # makes Slack render only the embedded tweet which is much cleaner.
    msg_text = "<https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}| >"

    logger.debug ''
    logger.debug msg_text
    logger.debug tweet.text

    # Post to Slack
    HTTParty.post $config['slack_web_hook'], {
      :body => {
        :text => msg_text,
        :username => tweet.user.screen_name,
        :icon_url => tweet.user.profile_image_url
      }.to_json,
      :headers => { 'Content-Type' => 'application/json' }
    }

    # Also retweet on Twitter
    if $config['retweet']
      $twitter.retweet tweet.id
    end

  end
end

client = TweetStream::Client.new(
  consumer_key: $config['consumer_key'],
  consumer_secret: $config['consumer_secret'],
  oauth_token: $config['your_token'],
  oauth_token_secret: $config['your_secret'],
  auth_method: :oauth
)

$twitter = Twitter::REST::Client.new do |config|
  config.consumer_key        = $config['consumer_key']
  config.consumer_secret     = $config['consumer_secret']
  config.access_token        = $config['your_token']
  config.access_token_secret = $config['your_secret']
end

Signal.trap("TERM") do
  logger.info "Shutting down streaming connection..."
  client.stop
  logger.info "Terminating."
  exit
end

client.on_delete do |status_id, user_id|
  #logger.info "#{user_id} deleted #{status_id}"
end

client.on_limit do |skip_count|
  logger.info "Got limit message: #{skip_count}"
end

client.on_enhance_your_calm do
  logger.warn "Enhance your calm"
end

client.on_inited do
  logger.info "inited"
end

client.on_reconnect do |timeout,retries|
  logger.info "reconnect timeout #{timeout} retries #{retries}"
end

client.on_no_data_received do
  logger.info "no_data_received"
end

client.on_error do |message|
  logger.info "error: #{message}"
end

logger.info "Creating new streaming search client following #{$user_ids.length} users"
client.follow($user_ids.join(',')) do |tweet|
  process_tweet logger, tweet
end
