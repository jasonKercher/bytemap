package bytemap

import "core:mem"

Multi :: struct($T: typeid) {
	entries: []_Entry,
	key_buf: [dynamic]u8,
	values:  [dynamic][dynamic]T,
	hash__:  Hash_Call,
}

make_multi :: proc($T: typeid, start_size: u64, props: bit_set[Map_Props] = {}) -> Multi(T) {
	start_size := start_size
	start_size = _MIN_SIZE if start_size == 0 else start_size
	start_size = _next_power_of_2(start_size)

	m: Multi(T) = {
		hash__  = _hash,
		key_buf = make([dynamic]u8),
		entries = _make_new_entries(start_size),
		values  = make([dynamic][dynamic]T),
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

_destroy_multi :: proc(m: ^Multi($T)) {
	if m == nil {
		return
	}
	delete(m.key_buf)
	delete(m.entries)
	for v in &m.values {
		delete(v)
	}
	delete(m.values)
}

_multi_reset :: proc(m: ^Multi($T)) {
	for v in &m.values {
		delete(v)
	}
	clear(&m.values)
	clear(&m.key_buf)
	mem.set(mem.raw_data(m.entries), u8(255), size_of(_Entry) * len(m.entries))
}

_multi_get_str :: proc(m: ^Multi($T), key: string) -> ([]T, bool) {
	return _multi_get(m, transmute([]u8)key)
}

_multi_get :: proc(m: ^Multi($T), key: []u8) -> ([]T, bool) {
	hash: u64 = 0
	org_len := len(m.key_buf)
	e, _ := _get_entry(m, key, &hash)
	resize(&m.key_buf, org_len)

	if e.val_idx == _NONE {
		return nil, false
	}

	dyn: [dynamic]T = m.values[e.val_idx]
	return dyn[:], true
}

_multi_set_str :: proc(m: ^Multi($T), key: string, val: T) -> bool {
	return _multi_set(m, transmute([]u8)key, val)
}

_multi_set :: proc(m: ^Multi($T), key: []u8, val: T) -> bool {
	hash: u64 = 0
	org_len := u64(len(m.key_buf))
	e, key_len := _get_entry(m, key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_len
		e.key_len = key_len
		e.val_idx = u32(len(m.values))
		e.hash = hash

		new_dyn := make([dynamic]T, 0, 1)
		append(&new_dyn, val)
		append(&m.values, new_dyn)
		if f32(len(m.values)) > _FULL_PERCENT * f32(len(m.entries)) {
			_grow_entries(&m.entries)
		}
		return false
	}

	dyn := &m.values[e.val_idx]
	append(dyn, val)
	resize(&m.key_buf, int(org_len))
	return true
}
