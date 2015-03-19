require 'rails_helper'

RSpec.describe BacklogApi, type: :model do
  let(:ba) { BacklogApi.new }

  describe "#space" do
    subject{ ba.space }
    it "get space data" do
      expect(subject.key?("spaceKey")).to be_truthy
    end

  end

  describe "#projects" do
    subject{ ba.projects }
    it "get projects data" do
      expect(subject[0].key?("id")).to be_truthy
      expect(subject[0].key?("projectKey")).to be_truthy
    end
  end

  describe "#issues" do
    let(:params) do
      id = ba.projects[0]["id"]
      { "projectId[]" => id, "count" => 2 }
    end
    subject{ ba.issues(params) }
    it "get projects data" do
      p subject
      expect(subject[0].key?("projectKey")).to be_truthy
    end
  end
end
