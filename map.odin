package bytemap

import "core:mem"

Map :: struct($T: typeid) {
	entries: []_Entry,
	key_buf: [dynamic]u8,
	values:  [dynamic]T,
	hash__:  Hash_Call,
}

make_map :: proc($T: typeid, start_size: u64, props: bit_set[Map_Props] = {}) -> Map(T) {
	start_size := _MIN_SIZE if start_size == 0 else start_size
	start_size = _next_power_of_2(start_size - 1)

	m: Map(T) = {
		hash__  = _hash,
		key_buf = make([dynamic]u8),
		entries = _make_new_entries(start_size),
		values  = make([dynamic]T),
	}

	mem.set(mem.raw_data(m.entries), u8(255), size_of(_Entry) * int(start_size))

	if .No_Case in props && .Rtrim in props {
		m.hash__ = _hash_nocase_rtrim
	} else if .No_Case in props {
		m.hash__ = _hash_nocase
	} else if .Rtrim in props {
		m.hash__ = _hash_rtrim
	}

	return m
}

_destroy_map :: proc(m: ^Map($T)) {
	delete(m.key_buf)
	delete(m.entries)
	delete(m.values)
}

_map_reset :: proc(m: ^Map($T)) {
	clear(&m.key_buf)
	clear(&m.values)
	mem.set(mem.raw_data(m.entries), u8(255), size_of(_Entry) * len(m.entries))
}

//_map_get_str :: proc(m: ^Map($T), key: string) -> (T, bool) {
//	return _map_get(m, transmute([]u8)key)
//}

_map_get_str :: proc(m: ^Map($T), key: string) -> (T, bool) {
	hash: u64 = 0
	org_len := len(m.key_buf)
	e, _ := _get_entry(m, transmute([]u8)key, &hash)
	resize(&m.key_buf, org_len)

	if e.val_idx == _NONE {
		return T{}, false
	}
	return m.values[e.val_idx], true
}

_map_get :: proc(m: ^Map($T), key: []u8) -> (T, bool) {
	hash: u64 = 0
	org_len := len(m.key_buf)
	e, _ := _get_entry(m, key, &hash)
	resize(&m.key_buf, org_len)

	if e.val_idx == _NONE {
		return T{}, false
	}
	return m.values[e.val_idx], true
}

_map_set_str :: proc(m: ^Map($T), key: string, val: T) -> bool {
	hash: u64 = 0
	org_len := u64(len(m.key_buf))
	e, key_len := _get_entry(m, transmute([]u8)key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_len
		e.key_len = key_len
		e.val_idx = u32(len(m.values))
		e.hash = hash
		append(&m.values, val)
		if f32(len(m.values)) > _FULL_PERCENT * f32(len(m.entries)) {
			_grow_entries(&m.entries)
		}
		return false
	}

	m.values[e.val_idx] = val
	resize(&m.key_buf, int(org_len))
	return true
}

_map_set :: proc(m: ^Map($T), key: []u8, val: T) -> bool {
	hash: u64 = 0
	org_len := u64(len(m.key_buf))
	e, key_len := _get_entry(m, key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_len
		e.key_len = key_len
		e.val_idx = u32(len(m.values))
		e.hash = hash
		append(&m.values, val)
		if f32(len(m.values)) > _FULL_PERCENT * f32(len(m.entries)) {
			_grow_entries(&m.entries)
		}
		return false
	}

	m.values[e.val_idx] = val
	resize(&m.key_buf, int(org_len))
	return true
}
