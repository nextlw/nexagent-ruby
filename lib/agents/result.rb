# frozen_string_literal: true

module Agents
  RunResult = Struct.new(:output, :messages, :usage, :error, :context, :validation_retries, keyword_init: true) do
    def success?
      error.nil? && !output.nil?
    end

    def failed?
      !success?
    end

    def was_rewritten?
      (validation_retries || 0) > 0
    end
  end
end
