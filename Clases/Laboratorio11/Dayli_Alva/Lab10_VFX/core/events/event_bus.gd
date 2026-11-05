extends Node

# API pública: estas señales se emiten y conectan desde otros scripts.
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal checkpoint_activated(checkpoint_id: StringName)
@warning_ignore("unused_signal")
signal score_changed(new_score: int)
@warning_ignore("unused_signal")
signal level_completed(level_id: StringName)
