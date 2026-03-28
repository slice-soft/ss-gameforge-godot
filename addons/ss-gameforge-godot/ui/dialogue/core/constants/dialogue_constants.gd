class_name DialogueConstants

## Controls how the dialogue advances between lines.
enum AdvanceMode {
	AUTO,   ## Advances automatically after hold_after_line. Input is ignored.
	MANUAL, ## Waits for player input before advancing. No auto-timer.
	HYBRID, ## Either player input OR the auto-timer advances the dialogue.
}
