Title: Telegram Web “This message is currently not supported” caused by bot draft/rich streaming

I debugged a Telegram Web rendering issue in a local Hermes/OpenClaw-style Telegram gateway.

Symptom:
Telegram Web showed repeated bubbles saying:

“This message is currently not supported on Telegram Web. Try getdesktop.telegram.org”

The final bot reply sometimes rendered normally, e.g. `plain test ok`, but one or more unsupported bubbles appeared before it.

What I initially suspected:

* Rich Markdown/HTML formatting
* Reply previews / `reply_to_message_id`
* Streaming via `editMessageText`
* Interim/status messages

What actually fixed it:
Hard-disabling Telegram Bot API draft/rich paths in the Telegram adapter:

* `sendMessageDraft`
* `sendRichMessageDraft`
* `sendRichMessage`

The working local patch was to force these methods/gates to return false:

* `_should_attempt_rich(...) -> False`
* `_should_attempt_rich_draft(...) -> False`
* `supports_draft_streaming(...) -> False`

After reloading the gateway, Telegram Web stopped showing the unsupported-message bubbles and displayed only the normal final `sendMessage` reply.

Important config notes:
These settings alone were not sufficient in my setup:

```yaml
display:
  platforms:
    telegram:
      streaming: false

streaming:
  enabled: false
  transport: edit

telegram:
  extra:
    rich_messages: false
    reply_to_mode: off
```

They helped reduce noise, but the actual decisive fix was disabling the adapter’s draft/rich Bot API paths directly.

Likely root cause:
Telegram Web currently treats bot draft/rich preview message types as unsupported, especially `sendMessageDraft` / `sendRichMessageDraft`. The final normal message renders fine, but the preview/draft/rich message becomes a generic unsupported Telegram Web bubble.

Side findings:

* `reply_to_mode: false` can be misleading because the code expects the string `off`.
* Accidentally setting `reply_to_mode: '"off"'` creates a literal quoted string and may not behave as intended.
* Gateway reload warnings are unrelated and expected during service restart.
* The visible unsupported bubble was not caused by the final assistant message itself.

Workaround:
For Telegram Web compatibility, disable native draft/rich Telegram delivery and use plain final `sendMessage`, or edit-based streaming only if confirmed clean in your implementation.
