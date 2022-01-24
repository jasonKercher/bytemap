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

@private
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
	_destroy_composite,
}

reset :: proc {
	_set_reset,
	_map_reset,
	_multi_reset,
	_composite_reset,
}

get :: proc {
	_set_get,
	_set_get_str,
	_map_get,
	_map_get_str,
	_multi_get,
	_multi_get_str,
	_composite_get,
}

set :: proc {
	_set_set,
	_set_set_str,
	_map_set,
	_map_set_str,
	_multi_set,
	_multi_set_str,
	_composite_set,
}

@private
_get_entry :: proc(m: $M, key: []u8, hash: ^u64) -> (^_Entry, u32) {
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

	return e, n
}

@private
_hash :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash: u64 = _FNV1_INIT
	for i: u32 = 0; i < n^; i += 1 {
		append(dest, key[i])
		hash *= _PRIME
		hash ~= u64(key[i])
	}
	return hash
}

@private
_hash_nocase :: proc(dest: ^[dynamic]u8, key: []u8, n: ^u32) -> u64 {
	hash: u64 = _FNV1_INIT
	for i: u32 = 0; i < n^; i += 1 {
		append(dest, _to_lower_ascii(key[i]))
		hash *= _PRIME
		hash ~= u64(dest[len(dest) - 1])
	}
	return hash
}

@private
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

@private
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

@private
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

@private
_make_new_entries :: proc(n: u64) -> []_Entry {
	buf := make([]_Entry, n)
	mem.set(mem.raw_data(buf), u8(255), size_of(_Entry) * int(n))
	return buf
}

/* What did you expect? It's a "byte" map. */
@private
_to_lower_ascii :: proc(b: u8) -> u8 {
	if b >= 'A' && b <= 'Z' {
		return 'a' + (b - 'A')
	}
	return b
}

@private
_next_power_of_2 :: proc(n: u64) -> u64 {
	value: u64 = 1
	for value < n {
		value <<= 1
	}
	return value
}

