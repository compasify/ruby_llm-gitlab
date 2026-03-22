# ruby_llm-gitlab

GitLab Duo AI provider for [RubyLLM](https://rubyllm.com). Use Claude and GPT models through your GitLab subscription.

## Requirements

- Ruby >= 3.1
- ruby_llm >= 1.0
- GitLab Premium or Ultimate subscription with Duo AI enabled
- Personal Access Token with `api` scope

## Installation

Add to your Gemfile:

```ruby
gem 'ruby_llm'
gem 'ruby_llm-gitlab'
```

Then `bundle install`.

## Configuration

```ruby
RubyLLM.configure do |config|
  config.gitlab_api_key = ENV['GITLAB_TOKEN']
end
```

For self-managed GitLab instances:

```ruby
RubyLLM.configure do |config|
  config.gitlab_api_key = ENV['GITLAB_TOKEN']
  config.gitlab_instance_url = 'https://gitlab.example.com'
  config.gitlab_gateway_url = 'https://ai-gateway.example.com'
end
```

## Show me the code

```ruby
# Chat with Claude through GitLab
chat = RubyLLM.chat(model: 'duo-chat-sonnet-4-6', provider: :gitlab_anthropic)
chat.ask "What's the best way to learn Ruby?"
```

```ruby
# Or use GPT
chat = RubyLLM.chat(model: 'duo-chat-gpt-5-1', provider: :gitlab_openai)
chat.ask "Explain metaprogramming in Ruby"
```

```ruby
# Stream responses
chat.ask "Tell me a story about Ruby" do |chunk|
  print chunk.content
end
```

```ruby
# Analyze files
chat.ask "What's in this?", with: "image.png"
chat.ask "Summarize this document", with: "contract.pdf"
```

```ruby
# Let AI use your code
class Weather < RubyLLM::Tool
  description "Get current weather"
  param :latitude
  param :longitude

  def execute(latitude:, longitude:)
    url = "https://api.open-meteo.com/v1/forecast?latitude=#{latitude}&longitude=#{longitude}&current=temperature_2m"
    JSON.parse(Faraday.get(url).body)
  end
end

chat.with_tool(Weather).ask "What's the weather in Berlin?"
```

```ruby
# Define an agent with instructions + tools
class WeatherAssistant < RubyLLM::Agent
  model "duo-chat-sonnet-4-6"
  provider :gitlab_anthropic
  instructions "Be concise and always use tools for weather."
  tools Weather
end

WeatherAssistant.new.ask "What's the weather in Berlin?"
```

```ruby
# Get structured output
class ProductSchema < RubyLLM::Schema
  string :name
  number :price
  array :features do
    string
  end
end

chat.with_schema(ProductSchema).ask "Analyze this product", with: "product.txt"
```

```ruby
# Rails integration works the same way
class Chat < ApplicationRecord
  acts_as_chat
end

chat = Chat.create! model: "duo-chat-sonnet-4-6", provider: "gitlab_anthropic"
chat.ask "What's in this file?", with: "report.pdf"
```

## Available Models

| Model | Provider | Backend |
|---|---|---|
| `duo-chat-opus-4-6` | `:gitlab_anthropic` | Claude Opus 4.6 |
| `duo-chat-sonnet-4-6` | `:gitlab_anthropic` | Claude Sonnet 4.6 |
| `duo-chat-sonnet-4-5` | `:gitlab_anthropic` | Claude Sonnet 4.5 |
| `duo-chat-opus-4-5` | `:gitlab_anthropic` | Claude Opus 4.5 |
| `duo-chat-haiku-4-5` | `:gitlab_anthropic` | Claude Haiku 4.5 |
| `duo-chat-gpt-5-1` | `:gitlab_openai` | GPT-5.1 |
| `duo-chat-gpt-5-2` | `:gitlab_openai` | GPT-5.2 |
| `duo-chat-gpt-5-mini` | `:gitlab_openai` | GPT-5 Mini |

## How It Works

```
Your App                GitLab Instance              AI Gateway            AI Provider
   |                         |                           |                     |
   |-- PAT (api scope) ---->|                           |                     |
   |                         |-- validate + issue ------>|                     |
   |<-- direct_access token -|   (cached 25 min)        |                     |
   |                         |                           |                     |
   |-- request + token -------------------------------->|                     |
   |                         |                           |-- native API ----->|
   |                         |                           |<-- response -------|
   |<-- streamed response --------------------------------|                     |
```

Two-step auth flow:

1. Your PAT authenticates against the GitLab instance, which returns a short-lived `direct_access` token (cached for 25 minutes).
2. That token authenticates requests to the AI Gateway, which proxies them to Anthropic or OpenAI using native protocol.

No API keys for Anthropic or OpenAI needed. Your GitLab subscription covers it.

## Limitations

- **Codex models not supported.** They require OpenAI's Responses API, which the gateway doesn't proxy.
- **PAT only.** OAuth token support isn't implemented yet.
- **Provider must be explicit.** Always pass `provider: :gitlab_anthropic` or `provider: :gitlab_openai`.
- **No model listing.** `RubyLLM.models` won't include GitLab models. Use the table above.
- **Embeddings, images, transcription** are untested through the gateway proxy.

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `ConfigurationError: Missing gitlab_api_key` | PAT not set | Set `GITLAB_TOKEN` env var |
| `ConfigurationError: ... (403)` | Duo AI not enabled | Verify GitLab Premium/Ultimate license with Duo enabled |
| `ConfigurationError: ... (401)` | Invalid PAT | Regenerate PAT with `api` scope |

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

Released under the MIT License.
