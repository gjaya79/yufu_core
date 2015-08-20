require 'rails_helper'

RSpec.describe Order::Verbal::TranslatorsQueue, :type => :model do

  RSpec.shared_examples 'queue builder' do
    it{is_expected.to be_a Order::Verbal::TranslatorsQueue}
    it{expect{subject}.to change{order.reload.translators_queues.count}.by(1)}
  end

  describe '.create_agent_queue' do
    subject{Order::Verbal::TranslatorsQueue.create_agent_queue order}

    context 'pass nil' do
      let(:order){nil}

      it{is_expected.to be_nil}
    end

    context 'order has not agents' do
      let(:order){create :order_verbal}

      it{is_expected.to be_nil}
    end

    context 'agent does not support order' do
      let(:order){create :order_verbal, referral_link: create(:user).referral_link}

      it{is_expected.to be_nil}
    end

    context 'agent support order' do
      let(:city){create :city}
      let(:language){create :language, senior: create(:profile_translator)}
      let(:user) do
        create :user, profile_translator: create(:profile_translator,
                                        services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                        city_approves: [build(:city_approve, is_approved: true, city: city)])
      end
      let(:translator){user.profile_translator}
      let(:order){create :order_verbal, referral_link: user.referral_link, location: city, language: language}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to eq DateTime.now}
      it{expect(subject.translators).to include translator}
    end
  end

  describe '.create_native_queue' do
    let(:city){create :city}
    let(:china){create :china}
    let(:language){create :language, senior: create(:profile_translator)}
    let(:profile_options){
      {services:      [build(:service, is_approved: true, language: language, level: 'guide')],
       city_approves: [build(:city_approve, is_approved: true, city: city)]}
    }
    let(:native_chinese_translator) do
      create :user, profile_translator: create(:profile_translator,
                                               profile_steps_language: build(:profile_steps_language, citizenship: china),
                                               services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                               city_approves: [build(:city_approve, is_approved: true, city: city)]
                  )
    end
    let(:not_native_chinese){create :user, profile_translator: build(:profile_translator, profile_options)}

    subject{Order::Verbal::TranslatorsQueue.create_native_queue order}

    before(:each){native_chinese_translator; not_native_chinese}

    context 'order on native chinese' do
      let(:order){create :wait_offers_order, location: city, language: language, want_native_chinese: true}

      it{is_expected.to be_a Order::Verbal::TranslatorsQueue}
      it{expect(subject.translators).to include native_chinese_translator.profile_translator}
      it{expect(subject.translators).not_to include not_native_chinese.profile_translator}

      it_behaves_like 'queue builder'
    end

    context 'order on not native chinese' do
      let(:order){create :wait_offers_order, location: city, language: language}

      it{is_expected.to be_nil}
    end
  end

  describe '.create_senior_queue' do
    let(:city){create :city}
    let(:language){create :language, senior: senior}
    let(:senior){create(:profile_translator)}
    let(:private_translator) do
      create :user, profile_translator: create(:profile_translator,
                                               services: [build(:service, is_approved: true, language: language, level: 'guide')],
                                               city_approves: [build(:city_approve, is_approved: true, city: city)]
                  )
    end
    let(:order){create :wait_offers_order, location: city, language: language}

    subject{Order::Verbal::TranslatorsQueue.create_senior_queue order}

    before(:each){private_translator}

    it_behaves_like 'queue builder'

    it{expect(subject.translators).to include senior}
    it{expect(subject.translators).not_to include private_translator.profile_translator}
  end

  describe '.create_last_queue' do
    let(:city){create :city}
    let(:language){create :language}
    let(:translator_1){create(:profile_translator,
                              services: [build(:service, is_approved: true, language: language, level: 'guide')],
                              city_approves: [build(:city_approve, is_approved: true, city: city)] )}

    let(:translator_2){create(:profile_translator,
                              services: [build(:service, is_approved: true, language: language, level: 'guide')],
                              city_approves: [build(:city_approve, is_approved: true, city: city)] )}
    let(:order){create :wait_offers_order, location: city, language: language}

    subject{Order::Verbal::TranslatorsQueue.create_last_queue order}

    before(:each) do
      Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: [translator_1]
      translator_2
    end

    it_behaves_like 'queue builder'

    it{expect(subject.translators).to include translator_2}
    it{expect(subject.translators).not_to include translator_1}
  end
end