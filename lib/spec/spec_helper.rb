require 'bundler/setup'
Bundler.require(:default, :test)

require 'webmock/rspec'

require_relative '../kobana'

RSpec.configure do |config|
  # Bloqueia todas as requisições HTTP reais durante os testes
  WebMock.disable_net_connect!(allow_localhost: true)
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

