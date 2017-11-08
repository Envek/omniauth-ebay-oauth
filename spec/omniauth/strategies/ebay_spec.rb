# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::Ebay do
  subject { described_class.new(nil, options) }

  describe '#callback_url' do
    let(:callback_url) { 'https://api.com/callback' }
    let(:options) { { callback_url: callback_url } }
    it 'uses options callback_url' do
      expect(subject.callback_url).to eql(callback_url)
    end
  end

  describe '#options' do
    let(:options) { {} }

    before { subject.setup_phase }

    it 'default mode is sandbox' do
      expect(subject.options.client_options.user_info_endpoint)
        .to eq('https://api.sandbox.ebay.com/ws/api.dll')
    end

    context 'when setup block passed' do
      let(:block) { proc { |_env| (@result ||= 0) && @result += 1 } }
      let(:options) { { setup: block } }

      it 'runs the setup block if passed one' do
        expect(block.call).to eql 2
      end
    end

    context "when scopes aren't passed" do
      let(:options) { {} }

      it 'uses empty string as scope' do
        expect(subject.options.scope).to eql ''
      end
    end

    context 'when scopes passed' do
      context 'as array' do
        let(:options) { { scope: %w[array like scopes] } }

        it 'concatenates passed scopes with space' do
          expect(subject.options.scope).to eql 'array like scopes'
        end
      end

      context 'as string' do
        let(:options) { { scope: 'scope as string' } }

        it 'keeps scopes the same' do
          expect(subject.options.scope).to eql 'scope as string'
        end
      end
    end

    context 'sandbox mode' do
      let(:options) { { sandbox: true } }

      it 'has correct eBay sandbox user info endpoint' do
        expect(subject.options.client_options.user_info_endpoint)
          .to eq('https://api.sandbox.ebay.com/ws/api.dll')
      end

      it 'has correct eBay sandbox token url' do
        expect(subject.options.client_options.token_url)
          .to eq('https://api.sandbox.ebay.com/identity/v1/oauth2/token')
      end

      it 'has correct eBay sandbox authorize url' do
        expect(subject.options.client_options.authorize_url)
          .to eq('https://signin.sandbox.ebay.com/authorize')
      end
    end

    context 'production mode' do
      let(:options) { { sandbox: false } }

      it 'has correct eBay production user info endpoint' do
        expect(subject.options.client_options.user_info_endpoint)
          .to eq('https://api.ebay.com/ws/api.dll')
      end

      it 'has correct eBay production token url' do
        expect(subject.options.client_options.token_url)
          .to eq('https://api.ebay.com/identity/v1/oauth2/token')
      end

      it 'has correct eBay production authorize url' do
        expect(subject.options.client_options.authorize_url)
          .to eq('https://signin.ebay.com/authorize')
      end
    end
  end

  describe '#user_info' do
    let(:access_token) { instance_double(OAuth2::AccessToken, token: :token) }
    let(:options) { {} }
    let(:user_info) { instance_double(OmniAuth::EbayOauth::UserInfo) }
    let(:request) do
      instance_double(OmniAuth::EbayOauth::UserInfoRequest, call: {})
    end

    before do
      expect(subject).to receive(:access_token).and_return(access_token)
      expect(OmniAuth::EbayOauth::UserInfoRequest)
        .to receive(:new).and_return(request)
      expect(OmniAuth::EbayOauth::UserInfo)
        .to receive(:new).with({}).and_return(user_info)
    end

    it 'returns wrapped user info request' do
      expect(subject.send(:user_info)).to eql(user_info)
    end
  end

  describe '#credentials' do
    let(:access_token) { OAuth2::AccessToken.new(client, token, opts) }
    let(:options) { {} }

    let(:client) { instance_double(OAuth2::Client) }
    let(:token)  { 'v^1.1#i^1#f^0#I^3#r^0#p^3#t^H4sIAAAAAAAAAOlongstringtoken' }
    let(:opts) do
      {
        'expires_in' => 7200,
        'refresh_token' => refresh_token,
        'refresh_token_expires_in' => expiration_time,
        'token_type' => 'User Access Token'
      }
    end

    let(:refresh_token) { 'v^1.1#i^1#r^1#f^0#I^3#p^3#t^Urefreshtoken=' }
    let(:expiration_time) { 47_304_000 }
    let(:current_time) { Time.now.to_i }

    before { allow(subject).to receive(:access_token).and_return(access_token) }

    it 'adds refresh_token_expires_at for default OAuth2 credentials hash' do
      expect(subject.credentials['refresh_token_expires_at'])
        .to be_between(current_time, current_time + expiration_time)
    end
  end
end
