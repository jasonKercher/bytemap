package bytemap

/* What the fuck is a composite map!?
 * A composite map allows you to use a very flexible key. Keys are variable
 * length and can be composed of different types! This is the main advantage
 * of a "bytemap".  It removes type safety (YAY). However, there are a couple
 * caveats (oh shit).
 *
 * First, the map will expect the same types used in the same position of the
 * key. For example, you cannot send a key of i32, f32 followed by a key of
 * f32, string. The user is responsible for this. The problem here is that
 * comparisons occur on a byte level.  You wouldn't want to have 2 values that
 * are not equal appear equal becasue they have equivalent memory footprint.
 * The opposite is also an issue.  Sending i32(1) and i64(1) will not match.
 *
 * Second, bytemap properties allow for "right trimming" and "caseless
 * matching." These properties should NOT be performed on non-string types.
 * But what if you want caseless string matching coupled with an int? In order
 * to accomplish this, one must add the position of the int type to the
 * exclusion bit_set or use the helper function add_exclusion.
 */

import "core:mem"

_Key_Location :: struct {
	idx: int,
	len: int,
}

Composite :: struct($T: typeid) {
	entries: []_Entry,
	key_buf: [dynamic]u8,
	key_locs: [dynamic]_Key_Location,
	values: [dynamic]T,
	hash__: Hash_Call,
	exclusion: bit_set[0..63],
}


make_composite :: proc($T: typeid, start_size: u64, props: bit_set[Map_Props] = {}) -> Composite(T) {
	start_size := _MIN_SIZE if start_size == 0 else start_size
	start_size = _next_power_of_2(start_size - 1)

	m: Composite(T) = {
		hash__  = _hash,
		key_buf = make([dynamic]u8),
		key_locs = make([dynamic]_Key_Location),
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

add_exclusion :: proc(m: ^Composite($T), n: int) {
	m.exclusion += {n}
}

_destroy_composite :: proc(m: ^Composite($T)) {
	delete(m.key_buf)
	delete(m.key_locs)
	delete(m.entries)
	delete(m.values)
}

_composite_reset :: proc(m: ^Composite($T)) {
	clear(&m.key_buf)
	clear(&m.key_locs)
	clear(&m.values)
	mem.set(mem.raw_data(m.entries), u8(255), size_of(_Entry) * len(m.entries))
}

//_composite_get_any :: proc(m: ^Composite($T), key: string) -> (T, bool) {
//	return _composite_get(m, transmute([]u8)key)
//}

_composite_get :: proc(m: ^Composite($T), key: [][]u8) -> (T, bool) {
	hash: u64 = 0

	org_key_buf_len := len(m.key_buf)
	org_key_loc_len = len(m.key_locs)

	e := _comp_get_entry(m, key, &hash)

	resize(&m.key_buf, org_key_buf_len)
	resize(&m.key_locs, org_key_loc_len)

	if e.val_idx == _NONE {
		return T{}, false
	}
	return m.values[e.val_idx], true
}


//_composite_set_any :: proc(m: ^Composite($T), key: string, val: T) -> bool {
//	return _composite_set(m, transmute([]u8)key, val)
//}

_composite_set :: proc(m: ^Composite($T), key: [][]u8, val: T) -> bool {
	hash: u64 = 0

	org_key_buf_len := len(m.key_buf)
	org_key_loc_len = len(m.key_locs)

	e := _comp_get_entry(m, key, &hash)

	if e.val_idx == _NONE {
		e.key_idx = org_key_loc_len
		e.key_len = len(key)
		e.val_idx = u32(len(m.values))
		e.hash = hash
		append(&m.values, val)
		if f32(len(m.values)) > _FULL_PERCENT * f32(len(m.entries)) {
			_grow_entries(&m.entries)
		}
		return false
	}

	m.values[e.val_idx] = val

	resize(&m.key_buf, org_key_buf_len)
	resize(&m.key_locs, org_key_loc_len)
	return true
}

@private
_comp_get_entry :: proc(m: ^Composite($T), key: [][]u8, key_len, hash: ^u64) -> ^_Entry {
	hash^ = 1
	key_len^ = 0

	key_buf_head := len(m.key_buf)

	for k, i in key {
		l := u32(len(k))
		/* Anything on the exclusion list should ignore properties
		 * that are set during construction (i.e. you would not want
		 * to apply .No_Case to an integer).
		 */
		if i in m.exclusion {
			hash^ *= (i+1) * _hash(&m.key_buf, k, &l)
		} else {
			hash^ *= (i+1) * m.hash__(&m.key_buf, k, &l)
		}
		key_len^ += u64(l)

		append(&m.key_locs, _Key_Location { idx = key_buf_head, len = int(l) })

		key_buf_head = len(m.key_buf)
	}

	key_size := len(key)
	new_keys := m.key_locs[len(m.key_locs) - key_size - 1:]

	idx := hash^ & u64(len(m.entries) - int(1))
	e := &m.entries[idx]

	for e.val_idx != _NONE && (e.hash != hash^ || !_comp_eq(m, e, new_keys)) {
		idx = (idx + 1) % u64(len(m.entries))
		e = &m.entries[idx]
	}

	return e
}

@private
_comp_eq :: proc(m: ^Composite($T), e: ^_Entry, new_keys: []_Key_Location) -> bool {
	old_keys := m.key_locs[e.key_idx:e.key_idx+e.key_len]

	if len(old_keys) != len(new_keys) {
		return false
	}

	for i := 0; i < len(old_keys); i += 1 {
		k0 := &old_keys[i]
		k1 := &new_keys[i]
		if k0.len != k1.len || mem.compare(m.key_buf[k0.idx:k0.idx + u64(k0.len)], m.key_buf[k1.idx:k1.idx + u64(k1.len)], k1.len) != 0 {
			return false
		}
	}
	return true
}
