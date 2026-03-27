# frozen_string_literal: true

require "bundler/setup"
require "agents"

RSpec.describe Agents::CallbackManager do
  describe "EVENT_TYPES" do
    it "includes response_validate" do
      expect(described_class::EVENT_TYPES).to include(:response_validate)
    end
  end

  describe "#evaluate_response_validators" do
    it "returns nil when no validators are registered" do
      manager = described_class.new(response_validate: [])
      expect(manager.evaluate_response_validators("hello", "Agent", nil)).to be_nil
    end

    it "returns nil when validators list is missing" do
      manager = described_class.new({})
      expect(manager.evaluate_response_validators("hello", "Agent", nil)).to be_nil
    end

    it "returns nil when all validators approve (return nil)" do
      manager = described_class.new(response_validate: [proc { nil }, proc { nil }])
      expect(manager.evaluate_response_validators("hello", "Agent", nil)).to be_nil
    end

    it "returns feedback string when a validator rejects" do
      manager = described_class.new(response_validate: [proc { "Rewrite with greeting" }])
      expect(manager.evaluate_response_validators("hello", "Agent", nil)).to eq("Rewrite with greeting")
    end

    it "returns first feedback (first-feedback-wins)" do
      validators = [
        proc { "First feedback" },
        proc { "Second feedback" }
      ]
      manager = described_class.new(response_validate: validators)
      expect(manager.evaluate_response_validators("hello", "Agent", nil)).to eq("First feedback")
    end

    it "does not call remaining validators after first rejection" do
      second_called = false
      validators = [
        proc { "Rejected" },
        proc { second_called = true; nil }
      ]
      manager = described_class.new(response_validate: validators)
      manager.evaluate_response_validators("hello", "Agent", nil)
      expect(second_called).to be false
    end

    it "fail-opens when validator raises exception" do
      manager = described_class.new(response_validate: [proc { raise StandardError, "crash" }])
      expect(manager.evaluate_response_validators("hello", "Agent", nil)).to be_nil
    end

    it "continues to next validator after exception" do
      validators = [
        proc { raise StandardError, "crash" },
        proc { "Feedback from second" }
      ]
      manager = described_class.new(response_validate: validators)
      expect(manager.evaluate_response_validators("hello", "Agent", nil)).to eq("Feedback from second")
    end

    it "handles arity-safe dispatch for lambdas" do
      validator = ->(output) { output.include?("bad") ? "Fix it" : nil }
      manager = described_class.new(response_validate: [validator])

      expect(manager.evaluate_response_validators("good response", "Agent", nil)).to be_nil
      expect(manager.evaluate_response_validators("bad response", "Agent", nil)).to eq("Fix it")
    end
  end

  describe "#emit vs #evaluate_response_validators" do
    it "emit is fire-and-forget (ignores return values)" do
      callback = proc { "this return is ignored" }
      manager = described_class.new(run_start: [callback])
      result = manager.emit(:run_start, "agent", "input")
      expect(result).to be_nil
    end

    it "evaluate_response_validators returns semantic values" do
      callback = proc { "feedback" }
      manager = described_class.new(response_validate: [callback])
      result = manager.evaluate_response_validators("output", "agent", nil)
      expect(result).to eq("feedback")
    end
  end
end
