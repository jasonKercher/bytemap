package bytemap

import "core:math/bits"
import "core:bytes"
import "core:mem"

_FNV1_INIT :: 14695981039346656037
_PRIME :: 1099511628211
_FULL_PERCENT :: f32(0.8)
_NONE :: bits.U32_MAX
_MIN_SIZE :: 16

/* Why []byte keys??
 * Because fuck type safety.
 */

Hash_Call :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64

Map_Props :: enum u8 {
	No_Case,
	Rtrim,
}

Set :: struct {
	entries:  []_Entry,
	key_buf:  [dynamic]u8,
	hash__:   Hash_Call,
	map_size: u64,
}

Map :: struct($T: typeid) {
	entries: []_Entry,
	key_buf: [dynamic]u8,
	values:  [dynamic]T,
	hash__:  Hash_Call,
}

Multi :: struct($T: typeid) {
	entries: []_Entry,
	key_buf: [dynamic]u8,
	values:  [dynamic][dynamic]T,
	hash__:  Hash_Call,
}

@(private = "file")
_Entry :: struct {
	hash:    u64,
	key_idx: u64,
	val_idx: u32,
	key_len: u32,
}

destroy :: proc {
	_destroy_set,
	_destroy_map,
	_destroy_multi,
}

reset :: proc {
	_set_reset,
	_map_reset,
	_multi_reset,
}

get :: proc {
	_set_get,
	_set_get_str,
	_map_get,
	_map_get_str,
	_multi_get,
	_multi_get_str,
}

set :: proc {
	_set_set,
	_set_set_str,
	_map_set,
	_map_set_str,
	_multi_set,
	_multi_set_str,
}

/* Set stuff */

make_set :: proc(start_size: u64, props: bit_set[Map_Props] = {}) -> Set {
	start_size := _MIN_SIZE if start_size == 0 else start_size
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

_set_set_str :: proc(m: ^Set, key: string) -> bool {
	return _set_set(m, transmute([]u8)key)
}

_set_set :: proc(m: ^Set, key: []u8) -> bool {
	hash: u64 = 0
	org_len := u64(len(m.key_buf))

	e := _get_entry(m, key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_len
		e.key_len = u32(len(key))
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

_set_get_str :: proc(m: ^Set, key: string) -> bool {
	return _set_get(m, transmute([]u8)key)
}

_set_get :: proc(m: ^Set, key: []u8) -> bool {
	hash: u64 = 0
	org_len := len(m.key_buf)
	e := _get_entry(m, key, &hash)
	resize(&m.key_buf, org_len)
	return e.val_idx != _NONE
}

/** Map stuff **/

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

_map_set_str :: proc(m: ^Map($T), key: string, val: T) -> bool {
	return _map_set(m, transmute([]u8)key, val)
}

_map_set :: proc(m: ^Map($T), key: []u8, val: T) -> bool {
	hash: u64 = 0
	org_len := u64(len(m.key_buf))

	e := _get_entry(m, key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_len
		e.key_len = u32(len(key))
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

_map_get_str :: proc(m: ^Map($T), key: string) -> (T, bool) {
	return _map_get(m, transmute([]u8)key)
}

_map_get :: proc(m: ^Map($T), key: []u8) -> (T, bool) {
	hash: u64 = 0
	org_len := len(m.key_buf)
	e := _get_entry(m, key, &hash)
	resize(&m.key_buf, org_len)

	if e.val_idx == _NONE {
		return T{}, false
	}
	return m.values[e.val_idx], true
}


/** Multi stuff **/

make_multi :: proc($T: typeid, start_size: u64, props: bit_set[Map_Props] = {}) -> Multi(T) {
	start_size := _MIN_SIZE if start_size == 0 else start_size
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

_multi_set_str :: proc(m: ^Multi($T), key: string, val: T) -> bool {
	return _multi_set(m, transmute([]u8)key, val)
}

_multi_set :: proc(m: ^Multi($T), key: []u8, val: T) -> bool {
	hash: u64 = 0
	org_len := u64(len(m.key_buf))

	e := _get_entry(m, key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_len
		e.key_len = u32(len(key))
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

_multi_get_str :: proc(m: ^Multi($T), key: string) -> ([]T, bool) {
	return _multi_get(m, transmute([]u8)key)
}

_multi_get :: proc(m: ^Multi($T), key: []u8) -> ([]T, bool) {
	hash: u64 = 0
	org_len := len(m.key_buf)
	e := _get_entry(m, key, &hash)
	resize(&m.key_buf, org_len)

	if e.val_idx == _NONE {
		return nil, false
	}

	dyn: [dynamic]T = m.values[e.val_idx]
	return dyn[:], true
}


/** internals **/


@(private = "file")
_get_entry :: proc(m: $M, key: []u8, hash: ^u64) -> ^_Entry {
	n := u32(len(key))
	org_len := u32(len(m.key_buf))
	hash^ = m.hash__(&m.key_buf, key, &n)

	idx := hash^ & u64(len(m.entries) - int(1))

	e := &m.entries[idx]
	for
	    e.val_idx != _NONE && (e.hash != hash^ || e.key_len != n || mem.compare(
		    m.key_buf[e.key_idx:e.key_idx + u64(e.key_len)],
		    m.key_buf[org_len:org_len + n],
	    ) != 0) {
		idx = (idx + 1) % u64(len(m.entries))
		e = &m.entries[idx]
	}

	return e
}

@(private = "file")
_hash :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash: u64 = _FNV1_INIT
	for i: u32 = 0; i < n^; i += 1 {
		append(dest, key[i])
		hash *= _PRIME
		hash ~= u64(key[i])
	}
	return hash
}

@(private = "file")
_hash_nocase :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash: u64 = _FNV1_INIT
	for i: u32 = 0; i < n^; i += 1 {
		append(dest, _to_lower_ascii(key[i]))
		hash *= _PRIME
		hash ~= u64(dest[len(dest) - 1])
	}
	return hash
}

@(private = "file")
_hash_rtrim :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash: u64 = _FNV1_INIT
	last_not_space_hash := hash
	last_not_space_n: u32

	for i: u32 = 0; i < n^; i += 1 {
		append(dest, key[i])
		hash *= _PRIME
		hash ~= u64(key[i])
		if !bytes.is_ascii_space(rune(key[i])) {
			last_not_space_hash = hash
			last_not_space_n = i + 1
		}
	}

	if last_not_space_n < n^ {
		resize(dest, len(dest) - int(n^ - last_not_space_n))
		hash = last_not_space_hash
		n^ = last_not_space_n
	}
	return hash
}

@(private = "file")
_hash_nocase_rtrim :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash: u64 = _FNV1_INIT
	last_not_space_hash := hash
	last_not_space_n: u32

	for i: u32 = 0; i < n^; i += 1 {
		append(dest, _to_lower_ascii(key[i]))
		hash *= _PRIME
		hash ~= u64(dest[len(dest) - 1])
		if !bytes.is_ascii_space(rune(key[i])) {
			last_not_space_hash = hash
			last_not_space_n = i + 1
		}
	}

	if last_not_space_n < n^ {
		resize(dest, len(dest) - int(n^ - last_not_space_n))
		hash = last_not_space_hash
		n^ = last_not_space_n
	}
	return hash
}

@(private = "file")
_grow_entries :: proc(old_entries: ^[]_Entry) {
	old_size := u64(len(old_entries))
	new_size := _next_power_of_2(old_size + 1)

	new_entries := _make_new_entries(new_size)
	for e, i in old_entries {
		if e.val_idx == _NONE {
			continue
		}

		idx := e.hash & (new_size - 1)
		dest_entry := &new_entries[idx]

		for dest_entry.val_idx != _NONE {
			idx = (idx + 1) % new_size
			dest_entry = &new_entries[idx]
		}
		dest_entry^ = e
	}

	delete(old_entries^)
	old_entries^ = new_entries
}

@(private = "file")
_make_new_entries :: proc(n: u64) -> []_Entry {
	buf := make([]_Entry, n)
	mem.set(mem.raw_data(buf), u8(255), size_of(_Entry) * int(n))
	return buf
}

/* What did you expect? It's a "byte" map. */
@(private = "file")
_to_lower_ascii :: proc(b: u8) -> u8 {
	if b >= 'A' && b <= 'Z' {
		return 'a' + (b - 'A')
	}
	return b
}

@(private = "file")
_next_power_of_2 :: proc(n: u64) -> u64 {
	value: u64 = 1
	for value < n {
		value <<= 1
	}
	return value
}

