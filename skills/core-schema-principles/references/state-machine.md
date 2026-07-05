# State Machine Modeling

Use a transition table when state changes need history or metadata.

Recommended columns:

- `id`
- parent foreign key
- `event_name`
- `from_state` and `to_state` only when the states are part of the domain language
- `occurred_at`
- `actor_id`
- `reason` or structured metadata when required

Validate transitions in domain code and keep database constraints for invariants that must never be violated.
