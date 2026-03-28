extends RefCounted
class_name ToastQueueManager

# Emits whenever the queue size changes.
signal queue_changed(size: int)

# FIFO queue of toast payloads with a max capacity.
var _queue: Array[ToastData] = []
var _max_size: int = 50

# Updates the maximum queue size and trims extra items.
func set_max_size(size: int) -> void:
	_max_size = max(1, size)
	_enforce_max_size()

# Returns the configured maximum queue size.
func get_max_size() -> int:
	return _max_size

# Adds a toast to the queue, trimming old entries if needed.
func enqueue(toast_data: ToastData) -> void:
	_enforce_max_size()
	_queue.push_back(toast_data)
	queue_changed.emit(_queue.size())

# Removes and returns the next toast payload.
func dequeue() -> ToastData:
	if _queue.is_empty():
		return null
	
	var data := _queue.pop_front()
	queue_changed.emit(_queue.size())
	return data

# Returns true when there are no queued toasts.
func is_empty() -> bool:
	return _queue.is_empty()

# Returns the current queue size.
func size() -> int:
	return _queue.size()

# Clears all queued toasts.
func clear() -> void:
	_queue.clear()
	queue_changed.emit(0)

# Returns a copy of the queue for inspection.
func get_queue_snapshot() -> Array[ToastData]:
	return _queue.duplicate()

# Drops oldest entries until the queue is under the max size.
func _enforce_max_size() -> void:
	while _queue.size() >= _max_size:
		_queue.pop_front()