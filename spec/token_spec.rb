# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JWT::Auth::Token do
  ##
  # Configuration
  #
  ##
  # Test variables
  #
  let(:user) { User.create! :activated => true }

  ##
  # Subject
  #
  subject(:token) { described_class.new }

  ##
  # Tests
  #
  describe 'properties' do
    it { is_expected.to respond_to :issued_at }
    it { is_expected.to respond_to :subject }
    it { is_expected.to respond_to :token_version }
    it { is_expected.to respond_to :type }

    it { is_expected.to have_attributes :issued_at => nil, :subject => nil, :token_version => nil, :type => nil }

    describe 'constructor' do
      subject(:token) { described_class.new :issued_at => 'foo', :subject => 'bar', :token_version => 'bat', :type => 'bat' }

      it { is_expected.to have_attributes :issued_at => 'foo', :subject => 'bar', :token_version => 'bat', :type => 'bat' }
    end
  end

  describe '#valid?' do
    before do
      # Allow JWT::Auth::Token to provide a lifetime for test purposes
      # This should actually be implemented in the subclasses
      allow_any_instance_of(described_class).to receive(:lifetime).and_return 2.hours.to_i
    end

    subject(:token) { described_class.new :subject => user, :issued_at => Time.now.to_i, :token_version => user.token_version }

    it { is_expected.to be_valid }

    context 'when the subject is nil' do
      before { token.subject = nil }

      it { is_expected.not_to be_valid }
    end

    context 'when the subject is destroyed' do
      before { user.destroy }

      it { is_expected.not_to be_valid }
    end

    context 'when issued_at is nil' do
      before { token.issued_at = nil }

      it { is_expected.not_to be_valid }
    end

    context 'when token_version is nil' do
      before { token.token_version = nil }

      it { is_expected.not_to be_valid }
    end

    context 'when token_version is incremented' do
      # Explicitly call `token` to initialize it with the old token_version
      before { token; user.increment! :token_version }

      it { is_expected.not_to be_valid }
    end

    context 'when the token has expired' do
      before { token.issued_at = JWT::Auth.access_token_lifetime.ago.to_i }

      it { is_expected.not_to be_valid }
    end

    context 'when the issued_at is in the future' do
      before { token.issued_at = 1.year.from_now.to_i }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#to_jwt' do
    let(:token) { described_class.new :subject => user }
    subject(:payload) { JWT.decode(token.to_jwt, JWT::Auth.secret).first }

    it { is_expected.to eq 'iat' => Time.now.to_i, 'sub' => user.id, 'ver' => user.token_version, 'typ' => nil }
  end

  describe '.from_jwt' do
    let(:jwt) { described_class.new(:subject => user, :type => type).to_jwt }
    let(:type)  { :access }
    subject(:token) { described_class.from_jwt jwt }

    it { is_expected.to have_attributes :issued_at => a_kind_of(Integer), :type => type, :subject => user, :token_version => user.token_version }

    context 'when the typ payload parameter is nil' do
      let(:type) { nil }

      it { is_expected.to be_nil }
    end

    context 'when the typ payload parameter is "access"' do
      let(:type) { :access }

      it { is_expected.to be_a_kind_of JWT::Auth::AccessToken }
      it { is_expected.to have_attributes :type => :access }
    end

    context 'when the typ payload parameter is "refresh"' do
      let(:type) { :refresh }

      it { is_expected.to be_a_kind_of JWT::Auth::RefreshToken }
      it { is_expected.to have_attributes :type => :refresh }
    end

    it 'calls the User#find_by_token method' do
      expect(User).to receive(:find_by_token)
                  .with :id => user.id, :token_version => user.token_version

      described_class.from_jwt jwt
    end
  end
end
