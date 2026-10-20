require 'rails_helper'

describe Kuroko2::User do
  describe '#google_account?' do
    subject { user.google_account? }

    context 'provider is google_oauth2' do
      let(:user) { create(:user, provider: 'google_oauth2') }
      it { is_expected.to be_truthy }
    end

    context 'provider is not google_oauth2' do
      let(:user) { create(:user, provider: 'group_email') }
      it { is_expected.to be_falsey }
    end
  end

  describe '.find_or_create_user' do
    let(:attributes) do
      { name: 'Bob Smith', email: 'bob@example.com', first_name: 'Bob', last_name: 'Smith' }
    end

    it 'creates a user and stores a gravatar image' do
      user = described_class.find_or_create_user('oauth-uid', attributes)

      expect(user).to be_persisted
      expect(user.email).to eq('bob@example.com')
      expect(user.image).to eq(format(described_class::GRAVATAR_URL, Digest::MD5.hexdigest('bob@example.com')))
    end

    it 'returns the existing user without overwriting attributes' do
      created = described_class.find_or_create_user('oauth-uid', attributes)
      found = described_class.find_or_create_user('oauth-uid', attributes.merge(name: 'Other', email: 'other@example.com'))

      expect(found.id).to eq(created.id)
      expect(found.name).to eq('Bob Smith')
      expect(described_class.where(uid: 'oauth-uid').count).to eq(1)
    end
  end
end
