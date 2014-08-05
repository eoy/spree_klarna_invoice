SpreeKlarnaInvoice
==================

Introduction goes here.

Installation
------------

Add spree_klarna_invoice to your Gemfile:

```ruby
gem 'spree_klarna_invoice', git: 'https://github.com/2rba/spree_klarna_invoice.git'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails generate spree_klarna_invoice:migration
bundle exec rake db:migrate
```

Add KlarnaInvoice at backend


There is a rake task which check klarna invoice with pending status
```shell
bundle exec rake klarna:check
```


Copyright (c) 2014 Serg Tyatin, released under the New BSD License
