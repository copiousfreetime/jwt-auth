# frozen_string_literal: true

require 'securerandom'

require 'rails_helper'

RSpec.describe JWT::Auth do
  it 'configures correctly' do
    JWT::Auth.configure do |config|
      config.refresh_token_lifetime = 1.year
      config.access_token_lifetime = 2.hours
      config.secret = 'mysecret'
    end

    expect(subject.refresh_token_lifetime).to eq 1.year
    expect(subject.access_token_lifetime).to eq 2.hours
    expect(subject.secret).to eq 'mysecret'
    expect(subject.model).to eq 'User'
  end
end
