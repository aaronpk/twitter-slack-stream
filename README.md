# Twitter/Slack Stream

Stream tweets from conference attendees to a Slack channel

## Setup

Copy `config.example.yml` to `config.yml` where you'll fill everything in.

### Enable or disable retweets
This script can optionally retweet all tweets it finds. This offers an alternate view of the tweets other than the Slack channel. If the account that is retweeting things is private, then the RT won't appear unless you're following the account. This offers another way to provide a protected view of the filtered stream.

To enable retweets, set `retweet: true` in `config.yml`.

### Twitter Tokens
First, you'll need to get a bunch of Twitter tokens. The easiest way is the steps below, since you can do it from the Twitter website without involving OAuth or anything. Keep in mind that this means the application will be acting on behalf of the user you create the app under.

* [Create a Twitter application](https://apps.twitter.com/)
* On the Twitter application page, click "Keys and Access Tokens"
* Copy the consumer key and secret to the config file
* Under the "Your Access Token" section, copy the access token and secret to the config file

### Twitter Users
The Twitter streaming API works with a list of Twitter user IDs rather than usernames. This unfortunately adds a bit of a setup process to build the list of user IDs since you probably have a list of usernames you want to follow. You'll need to build the list of user IDs yourself.

* `usernames.json` - A JSON-encoded list of usernames, e.g. `["jack","ev"]`
* `user_ids.json` - A JSON-encoded list of user IDs as integers, e.g. `[1,2]`

### Slack Integration
Create an "Incoming Web Hook" integration for the Slack channel you want the Tweets to appear in. Don't worry about the name or photo for the bot, since the script will overwrite those with the name of the Twitter users when messages are copied in.

Set the web hook URL in `config.yml`.

### Search Term
Define your search term as a regex in the config file. Be sure to escape any backslashes with an additional backslash. A common example is to search for a few variants of a conference's hashtag such as:

```
regex: "\\btest(conf|2015|conf2015)\\b"
```

which would match:

* testconf
* test2015
* testconf2015

If you want to match tweets more aggressively, make the suffixes optional:

```
regex: "\\btest(conf|2015|conf2015)?\\b"
```

which adds the following:

* test


## Running

Start the script by running:

```
bundle exec ruby stream.rb
```

If you need to stop and re-start the script, make sure you wait 10 seconds or so to avoid getting rate limited.

## Startup Script

For running under Ubuntu, you can copy the below into an init script so that it starts on boot. You may need to adjust the paths tailored to your environment.

```
start on runlevel [2345]
stop on runlevel [016]

respawn

exec sudo -u ubuntu /usr/local/bin/bundle exec /usr/local/bin/ruby /path/to/stream.rb
```

## License

Copyright 2015 by Aaron Parecki.

Available under the Apache 2.0 License
