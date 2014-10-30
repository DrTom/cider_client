# cider\_client -- Ruby client for Cider CI

[![Build Status](https://travis-ci.org/psy-q/cider_client.svg?branch=master)](https://travis-ci.org/psy-q/cider_client)
[![Coverage Status](https://img.shields.io/coveralls/psy-q/cider_client.svg)](https://coveralls.io/r/psy-q/cider_client?branch=master)

This is an attempt at a Ruby client/wrapper for the Cider CI API, which is REST/JSON/HAL-based.

If you're not familiar with Cider CI, have a look at this:

https://github.com/cider-ci/cider-ci

At the expense of having to write a few somewhat rigid test setup files around your tests, Cider can run e.g. Cucumber tests in parallel. That makes your test suite fast as a weasel, even if individually, your tests suck.

Without a Cider CI server, this gem is totally useless.

## Usage

Hell, how would I know? Maybe try something like this:

```ruby
require 'rubygems'
require 'cider_client'

cc = CiderClient.new
cc.host = 'your.cider.example.com'
cc.username = 'someone'
cc.password = 'nothing_special'
cc.execution_id = '61a04030-96d7-4322-9c65-fb24660ad8ea'

# Now you can retrieve the trials for that execution

cc.trials # This will take forever. My apologies.
```
