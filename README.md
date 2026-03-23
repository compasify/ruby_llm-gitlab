# RubyLLM::GitLab

Access Claude and GPT models through **GitLab Duo** via the [RubyLLM](https://rubyllm.com) interface. One provider, automatic routing.

## Requirements

- Ruby >= 3.1
- [RubyLLM](https://github.com/crmne/ruby_llm) >= 1.0
- GitLab Premium/Ultimate with Duo Enterprise
- Personal Access Token with `ai_features` scope

## Installation

```ruby
gem 'ruby_llm-gitlab'
```

## Configuration

### gitlab.com

```ruby
RubyLLM.configure do |config|
  config.gitlab_api_key = ENV['GITLAB_TOKEN']
end
```

### Self-managed

```ruby
RubyLLM.configure do |config|
  config.gitlab_api_key = ENV['GITLAB_TOKEN']
  config.gitlab_instance_url = 'https://gitlab.example.com'
  config.gitlab_gateway_url = 'https://cloud.gitlab.com'  # default
end
```

## Usage

### Chat

```ruby
chat = RubyLLM.chat(model: 'duo-chat-opus-4-6', provider: :gitlab)
chat.ask "What's the best way to learn Ruby?"
```

### Streaming

```ruby
chat = RubyLLM.chat(model: 'duo-chat-sonnet-4-6', provider: :gitlab)
chat.ask "Tell me a story" do |chunk|
  print chunk.content
end
```

### Tools

```ruby
class Weather < RubyLLM::Tool
  description "Get current weather"
  param :city, type: :string

  def execute(city:)
    { temperature: 22, condition: "sunny" }
  end
end

chat = RubyLLM.chat(model: 'duo-chat-opus-4-6', provider: :gitlab)
chat.with_tool(Weather).ask "What's the weather in Berlin?"
```

### Agents

```ruby
class CodeReviewer < RubyLLM::Agent
  model 'duo-chat-opus-4-6'
  provider :gitlab
  instructions "You are a senior Ruby developer. Review code for bugs and style."
end

CodeReviewer.new.ask "Review this: def foo(x) x+1 end"
```

### Rails

```ruby
class Chat < ApplicationRecord
  acts_as_chat model: 'duo-chat-sonnet-4-6', provider: :gitlab
end

chat = Chat.create!
chat.ask "Explain Active Record callbacks"
```

## Models

| GitLab Model ID | Routes To | Backend |
|---|---|---|
| `duo-chat-opus-4-6` | `claude-opus-4-6` | Anthropic |
| `duo-chat-sonnet-4-6` | `claude-sonnet-4-6` | Anthropic |
| `duo-chat-opus-4-5` | `claude-opus-4-5-20251101` | Anthropic |
| `duo-chat-sonnet-4-5` | `claude-sonnet-4-5-20250929` | Anthropic |
| `duo-chat-haiku-4-5` | `claude-haiku-4-5-20251001` | Anthropic |
| `duo-chat-gpt-5-1` | `gpt-5.1-2025-11-13` | OpenAI |
| `duo-chat-gpt-5-2` | `gpt-5.2-2025-12-11` | OpenAI |
| `duo-chat-gpt-5-mini` | `gpt-5-mini-2025-08-07` | OpenAI |

## How It Works

```
User → RubyLLM.chat(provider: :gitlab)
         ↓
       GitLab Provider (router)
         ├── Claude model? → AnthropicDelegate → GitLab AI Gateway → Anthropic API
         └── GPT model?    → OpenAIDelegate   → GitLab AI Gateway → OpenAI API
```

1. **Token exchange** — Your PAT is exchanged for a short-lived gateway token via GitLab's Direct Access API
2. **Routing** — The provider inspects the model ID and delegates to the correct sub-provider
3. **Proxy** — Requests go through GitLab's AI Gateway (`cloud.gitlab.com`) which proxies to the upstream API
4. **Model mapping** — GitLab model IDs (e.g. `duo-chat-opus-4-6`) are transparently mapped to upstream IDs (e.g. `claude-opus-4-6`)

## Limitations

- Chat completions only (no embeddings, images, audio, moderation)
- No Codex/Responses API models
- Token cached for 25 minutes; auto-refreshes on expiry
- Requires GitLab Duo Enterprise license

## Troubleshooting

### `ConfigurationError: Missing configuration for GitLab: gitlab_api_key`

Set your token:

```ruby
RubyLLM.configure { |c| c.gitlab_api_key = ENV['GITLAB_TOKEN'] }
```

### `ConfigurationError: Failed to obtain GitLab direct access token`

- Verify your PAT has `ai_features` scope
- Check your GitLab instance URL is correct
- Ensure Duo Enterprise is enabled for your group/project

### 401 errors during chat

The gem automatically retries once with a fresh token. If it persists:
- Your PAT may have expired
- The Duo license may have been revoked

## License

MIT
