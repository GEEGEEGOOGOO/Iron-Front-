extends Node
var pools: Dictionary = {}
var factories: Dictionary = {}
var borrowed: Dictionary = {}
func register_pool(key: String, factory: Callable, count: int) -> void:
	if pools.has(key):
		return
	pools[key] = []
	factories[key] = factory
	for i in count:
		var item: Node = factory.call()
		add_child(item)
		item.process_mode = Node.PROCESS_MODE_DISABLED
		if item is Node3D:
			item.hide()
		pools[key].append(item)
func acquire(key: String) -> Node:
	if not pools.has(key) or pools[key].is_empty():
		return null
	var item: Node = pools[key].pop_back()
	borrowed[item] = key
	item.process_mode = Node.PROCESS_MODE_PAUSABLE
	if item is Node3D:
		item.show()
	return item
func release(item: Node) -> void:
	if not borrowed.has(item):
		return
	var key: String = borrowed[item]
	borrowed.erase(item)
	item.process_mode = Node.PROCESS_MODE_DISABLED
	if item is Node3D:
		item.hide()
	if item.has_method("on_recycle"):
		item.on_recycle()
	pools[key].append(item)
func release_all() -> void:
	for item in borrowed.keys():
		release(item)
