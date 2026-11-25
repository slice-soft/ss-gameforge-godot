extends EventBus
class_name ShowcaseEvents

## The showcase's own event bus: states emit, listeners react, nobody holds references.

static var i: ShowcaseEvents:
	get:
		return SingletonNode.get_instance_for(ShowcaseEvents) as ShowcaseEvents

signal pokemon_loaded(pokemon_name: String)
signal pokemon_load_failed(reason: String)
