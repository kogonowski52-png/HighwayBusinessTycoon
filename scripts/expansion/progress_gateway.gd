@abstract
extends RefCounted
## Future online adapters receive transport-independent progress and expose real remote results.
## The offline campaign owns the authoritative file until an adapter completes an explicit sync.

const PROTOCOL_VERSION := 1

signal identity_resolved(account_id: String)
signal progress_received(account_id: String, revision: String, envelope: Dictionary)
signal progress_published(revision: String)
signal schedule_received(events: Array[Dictionary])
signal leaderboard_received(board: String, entries: Array[Dictionary])
signal request_failed(operation: String, error: int)

@abstract func sign_in() -> void
@abstract func fetch_progress(account_id: String) -> void
@abstract func push_progress(account_id: String, base_revision: String, envelope: Dictionary) -> void
@abstract func fetch_schedule(since: int) -> void
@abstract func fetch_leaderboard(board: String, event_period: String, page: int) -> void
