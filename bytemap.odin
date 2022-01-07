package bytemap

import "core:math/bits"
import "core:bytes"
import "core:mem"

_FNV1_INIT :: 14695981039346656037
_PRIME :: 1099511628211
_NONE :: bits.U32_MAX
_FULL_PERCENT :: f32(0.8)

/* Why []byte keys??
 * Because fuck type safety.
 */

Result :: enum {
	Not_Found,
	Found,
}

Hash_Call :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64

Map_Props :: enum u8 {
	No_Case,
	Rtrim,
}

Map :: struct($T: typeid) {
	entries: [dynamic]_Entry,
	key_buf: [dynamic]u8,
	values: [dynamic]T,
	hash__: Hash_Call,
}

@(private = "file")
_Entry :: struct {
	hash: u64,
	key_idx: u64,
	val_idx: u32,
	key_len: u32,
}

make_map :: proc($T: typeid, start_size: u32, props: bit_set[Map_Props] = {}) -> Map(T) {
	m: Map(T) = {
		hash__ = _hash,
		key_buf = make([dynamic]u8),
		entries = make([dynamic]_Entry, start_size),
		values = make([dynamic]T),
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

destroy_map :: proc(m: ^Map($T)) {
	delete(m.key_buf)
	delete(m.entries)
	delete(m.values)
}

get :: proc { _map_get, _map_get_string }
set :: proc { _map_set, _map_set_string }

_map_set_string :: proc(m: ^Map($T), key: string, val: T) -> Result {
	return _map_set(m, transmute([]u8)key, val)
}

_map_set :: proc(m: ^Map($T), key: []u8, val: T) -> Result {
	hash : u64 = 0
	org_len := u64(len(m.key_buf))

	e := _get_entry(m, key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_len
		e.key_len = u32(len(key))
		e.val_idx = u32(len(m.values))
		e.hash = hash
		append(&m.values, val)
		if f32(len(m.values)) > _FULL_PERCENT * f32(len(m.entries)) {
			_grow_map(m)
		}
		return .Not_Found
	}

	m.values[e.val_idx] = val
	resize(&m.key_buf, int(org_len))
	return .Found
}

_map_get_string :: proc(m: ^Map($T), key: string) -> (T, Result) {
	return _map_get(m, transmute([]u8)key)
}

_map_get :: proc(m: ^Map($T), key: []u8) -> (T, Result) {
	hash : u64 = 0
	org_len := len(m.key_buf)
	e := _get_entry(m, key, &hash)
	resize(&m.key_buf, org_len)

	if e.val_idx == _NONE {
		return T{}, .Not_Found
	}
	return m.values[e.val_idx], .Found
}

_get_entry :: proc(m: ^Map($T), key: []u8, hash: ^u64) -> ^_Entry {
	n := u32(len(key))
	org_len := u32(len(m.key_buf))
	hash^ = m.hash__(&m.key_buf, key, &n)

	idx := hash^ & u64(len(m.entries) - int(1))

	e := &m.entries[idx]
	for e.val_idx != _NONE && 
	    (e.hash != hash^ || e.key_len != n ||
	     mem.compare(m.key_buf[e.key_idx:e.key_idx + u64(e.key_len)],
	                 m.key_buf[org_len:org_len + n]) != 0) {
		idx = (idx + 1) % u64(len(m.entries))
		e = &m.entries[idx]
	}

	return e
}

_hash :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash : u64 = _FNV1_INIT
	for i : u32 = 0; i < n^; i += 1 {
		append(dest, key[i])
		hash *= _PRIME
		hash ~= u64(key[i])
	}
	return hash
}
_hash_nocase :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash : u64 = _FNV1_INIT
	for i : u32 = 0; i < n^; i += 1 {
		append(dest, _to_lower(key[i]))
		hash *= _PRIME
		hash ~= u64(dest[len(dest) - 1])
	}
	return hash
}
_hash_rtrim :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash : u64 = _FNV1_INIT
	last_not_space_hash := hash
	last_not_space_n := n^

	for i : u32 = 0; i < n^; i += 1 {
		append(dest, key[i])
		hash *= _PRIME
		hash ~= u64(key[i])
		if bytes.is_ascii_space(rune(key[i])) {
			last_not_space_hash = hash
			last_not_space_n = n^
		}
	}

	if last_not_space_n < n^ {
		resize(dest, len(dest) - int(n^ - last_not_space_n))
		n^ = last_not_space_n
	}
	return hash
}
_hash_nocase_rtrim :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash : u64 = _FNV1_INIT
	last_not_space_hash := hash
	last_not_space_n := n^

	for i : u32 = 0; i < n^; i += 1 {
		append(dest, _to_lower(key[i]))
		hash *= _PRIME
		hash ~= u64(dest[len(dest) - 1])
		if bytes.is_ascii_space(rune(key[i])) {
			last_not_space_hash = hash
			last_not_space_n = n^
		}
	}

	if last_not_space_n < n^ {
		resize(dest, len(dest) - int(n^ - last_not_space_n))
		n^ = last_not_space_n
	}
	return hash
}

@(private = "file")
_grow_map :: proc(m: ^Map($T)) {
	/* TODO */
}

@(private = "file")
_next_power_of_2 :: proc(n: u64) -> u64 {
	value : u64 = 1
	for value < n {
		value <<= 1
	}
	return value
}

/* What did you expect? It's a "byte" map. */
@(private = "file")
_to_lower :: proc(b: u8) -> u8 {
	if b >= 'A' && b <= 'Z' {
		return 'a' + (b - 'A')
	}
	return b
}
