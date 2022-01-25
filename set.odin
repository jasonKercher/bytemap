package bytemap

import "core:mem"

Set :: struct {
	entries:  []_Entry,
	key_buf:  [dynamic]u8,
	hash__:   Hash_Call,
	map_size: u64,
}


make_set :: proc(start_size: u64, props: bit_set[Map_Props] = {}) -> Set {
	start_size := start_size  // -vet
	start_size = _MIN_SIZE if start_size == 0 else start_size
	start_size = _next_power_of_2(start_size - 1)

	m: Set = {
		hash__  = _hash,
		key_buf = make([dynamic]u8),
		entries = _make_new_entries(start_size),
	}

	if .No_Case in props && .Rtrim in props {
		m.hash__ = _hash_nocase_rtrim
	} else if .No_Case in props {
		m.hash__ = _hash_nocase
	} else if .Rtrim in props {
		m.hash__ = _hash_rtrim
	}

	return m
}
_destroy_set :: proc(m: ^Set) {
	delete(m.key_buf)
	delete(m.entries)
}

_set_reset :: proc(m: ^Set) {
	clear(&m.key_buf)
	mem.set(mem.raw_data(m.entries), u8(255), size_of(_Entry) * len(m.entries))
}

_set_get_str :: proc(m: ^Set, key: string) -> bool {
	return _set_get(m, transmute([]u8)key)
}

_set_get :: proc(m: ^Set, key: []u8) -> bool {
	hash: u64 = 0
	org_len := len(m.key_buf)
	e, _ := _get_entry(m, key, &hash)
	resize(&m.key_buf, org_len)
	return e.val_idx != _NONE
}

_set_set_str :: proc(m: ^Set, key: string) -> bool {
	return _set_set(m, transmute([]u8)key)
}

_set_set :: proc(m: ^Set, key: []u8) -> bool {
	hash: u64 = 0
	org_len := u64(len(m.key_buf))
	e, key_len := _get_entry(m, key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_len
		e.key_len = key_len
		e.val_idx = 1 /* lol */
		m.map_size += 1
		e.hash = hash
		if f32(m.map_size) > _FULL_PERCENT * f32(len(m.entries)) {
			_grow_entries(&m.entries)
		}
		return false
	}

	resize(&m.key_buf, int(org_len))
	return true
}
