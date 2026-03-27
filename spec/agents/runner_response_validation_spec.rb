# frozen_string_literal: true

require "bundler/setup"
require "agents"

RSpec.describe "Runner Response Validation" do
  let(:agent) do
    Agents::Agent.new(
      name: "TestAgent",
      instructions: "You are a helpful assistant.",
      model: "gpt-4.1-mini"
    )
  end

  let(:runner) { Agents::Runner.with_agents(agent) }

  describe "on_response_validate callback registration" do
    it "registers validator via on_response_validate" do
      runner.on_response_validate { |output, _agent, _ctx| nil }
      expect(runner.instance_variable_get(:@callbacks)[:response_validate].size).to eq(1)
    end

    it "supports method chaining" do
      result = runner.on_response_validate { nil }
      expect(result).to eq(runner)
    end

    it "initializes response_validate in callbacks hash" do
      expect(runner.instance_variable_get(:@callbacks)).to have_key(:response_validate)
      expect(runner.instance_variable_get(:@callbacks)[:response_validate]).to eq([])
    end
  end

  describe "Runner constants" do
    it "defines DEFAULT_MAX_VALIDATION_RETRIES as 2" do
      expect(Agents::Runner::DEFAULT_MAX_VALIDATION_RETRIES).to eq(2)
    end
  end

  describe "RunResult#validation_retries" do
    it "defaults to nil" do
      result = Agents::RunResult.new(output: "hello")
      expect(result.validation_retries).to be_nil
    end

    it "stores validation_retries count" do
      result = Agents::RunResult.new(output: "hello", validation_retries: 2)
      expect(result.validation_retries).to eq(2)
    end

    it "reports was_rewritten? as false when no retries" do
      result = Agents::RunResult.new(output: "hello", validation_retries: 0)
      expect(result.was_rewritten?).to be false
    end

    it "reports was_rewritten? as true when retries > 0" do
      result = Agents::RunResult.new(output: "hello", validation_retries: 1)
      expect(result.was_rewritten?).to be true
    end

    it "reports was_rewritten? as false when validation_retries is nil" do
      result = Agents::RunResult.new(output: "hello")
      expect(result.was_rewritten?).to be false
    end
  end

  describe "AgentRunner#run passes max_validation_retries" do
    it "accepts max_validation_retries parameter" do
      expect(runner).to respond_to(:run)
      method_params = runner.method(:run).parameters.map(&:last)
      expect(method_params).to include(:max_validation_retries)
    end
  end
end
