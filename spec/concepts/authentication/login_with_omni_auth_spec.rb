require "rails_helper"

RSpec.describe Authentication::LoginWithOmniAuth do
  let(:user)     { User.first }
  let(:warden)   { spy }
  let(:listener) { spy }
  let(:invalid_info) { Authentication::OmniAuthInfo.new }
  let(:valid_info) do
    Authentication::OmniAuthInfo.new(
      :provider => "github",
      :uid      => "12345",
      :info     => {
        :nickname => "andy",
        :name     => "Andy",
        :image    => "http://image.com/12345.png"
      }
    )
  end

  before  { subject.subscribe(listener) }

  context "with valid info" do
    subject { Authentication::LoginWithOmniAuth.new(valid_info, warden) }

    context "when the user doesn't have an account" do
      it "creates a new user" do
        expect { subject.call }.to change(User, :count).by(1)
      end

      describe "it also" do
        before { subject.call }

        it "sets the user as a viewer" do
          expect(user).to be_viewer
        end

        it "sets the user's attributes" do
          expect(user).to have_attributes(
            :provider  => "github",
            :uid       => "12345",
            :nickname  => "andy",
            :name      => "Andy",
            :image_url => "http://image.com/12345.png"
          )
        end

        it "publishes the :ok event" do
          expect(listener).to have_received(:ok).with(user)
        end

        it "logs in the user" do
          expect(warden).to have_received(:login).with(user)
        end
      end
    end

    context "when the user already has an account" do
      it "doesn't create a new user" do
        create(:user, :uid => "12345", :provider => "github")

        expect { subject.call }.not_to change(User, :count)
      end

      it "publishes the :ok event" do
        subject.call

        expect(listener).to have_received(:ok).with(user)
      end

      it "logs in the user" do
        subject.call

        expect(warden).to have_received(:login).with(user)
      end
    end
  end

  context "with invalid info" do
    subject { Authentication::LoginWithOmniAuth.new(invalid_info, warden) }

    it "doesn't create a new user" do
      expect { subject.call }.not_to change(User, :count)
    end

    it "publishes the :fail event" do
      subject.call

      expect(listener).to have_received(:fail)
    end

    it "doesn't log in the user" do
      subject.call

      expect(warden).not_to have_received(:login)
    end
  end
end
