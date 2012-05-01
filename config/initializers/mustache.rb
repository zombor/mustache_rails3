# Be sure to install mustache gem and include mustache gem in project Gemfile.

# Template Handler
require 'mustache_railstache'
# Generator
Rails.application.config.generators.template_engine :mustache
