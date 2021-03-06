package bytemap

import "core:testing"
import "core:fmt"

@test
test_map_basic :: proc(t: ^testing.T) {
	m := make_map(int, 16)
	_map_setup(&m)

	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&m, fmt.tprintf("Key_Number_%d", i), i)
	}

	val: int
	ret: bool
	val, ret = get(&m, "one")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 1)
	val, ret = get(&m, "two")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 2)
	val, ret = get(&m, "ten")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 10)
	val, ret = get(&m, "twelve")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 12)
	val, ret = get(&m, "test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 100)
	val, ret = get(&m, "Test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 101)
	val, ret = get(&m, "test ")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "no")
	testing.expect_value(t, ret, false)
	testing.expect_value(t, val, 0)

	destroy(&m)
}

@test
test_map_nocase :: proc(t: ^testing.T) {
	m := make_map(int, 16, {.No_Case})
	_map_setup(&m)

	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&m, fmt.tprintf("Key_Number_%d", i), i)
	}

	val: int
	ret: bool
	val, ret = get(&m, "one")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 1)
	val, ret = get(&m, "two")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 2)
	val, ret = get(&m, "ten")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 10)
	val, ret = get(&m, "twelve")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 12)
	val, ret = get(&m, "test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 101)
	val, ret = get(&m, "Test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 101)
	val, ret = get(&m, "test ")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "no")
	testing.expect_value(t, ret, false)
	testing.expect_value(t, val, 0)

	destroy(&m)
}

@test
test_map_rtrim :: proc(t: ^testing.T) {
	m := make_map(int, 16, {.Rtrim})
	_map_setup(&m)

	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&m, fmt.tprintf("Key_Number_%d", i), i)
	}

	val: int
	ret: bool
	val, ret = get(&m, "one")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 1)
	val, ret = get(&m, "two")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 2)
	val, ret = get(&m, "ten")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 10)
	val, ret = get(&m, "twelve")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 12)
	val, ret = get(&m, "test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "Test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 101)
	val, ret = get(&m, "test ")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "no")
	testing.expect_value(t, ret, false)
	testing.expect_value(t, val, 0)

	destroy(&m)
}

@test
test_map_nocase_rtrim :: proc(t: ^testing.T) {
	m := make_map(int, 16, {.No_Case, .Rtrim})
	_map_setup(&m)

	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&m, fmt.tprintf("Key_Number_%d", i), i)
	}

	val: int
	ret: bool
	val, ret = get(&m, "one")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 1)
	val, ret = get(&m, "two")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 2)
	val, ret = get(&m, "ten")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 10)
	val, ret = get(&m, "twelve")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 12)
	val, ret = get(&m, "test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "Test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "test ")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "no")
	testing.expect_value(t, ret, false)
	testing.expect_value(t, val, 0)

	destroy(&m)
}

@test
test_multi_basic :: proc(t: ^testing.T) {
	m := make_multi(int, 32)
	testing.expect_value(t, len(m.entries), 32)

	_map_setup(&m)
	
	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&m, fmt.tprintf("Key_Number_%d", i), i)
	}

	vals: []int
	ret: bool
	vals, ret = get(&m, "one")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 2)
	testing.expect_value(t, vals[0], 10)
	testing.expect_value(t, vals[1], 1)

	vals, ret = get(&m, "two")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 2)

	vals, ret = get(&m, "ten")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 10)

	vals, ret = get(&m, "twelve")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 12)

	vals, ret = get(&m, "test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 100)

	vals, ret = get(&m, "Test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 101)

	vals, ret = get(&m, "test ")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 102)

	vals, ret = get(&m, "no")
	testing.expect_value(t, ret, false)
	testing.expect_value(t, len(vals), 0)

}

@test
test_multi_nocase :: proc(t: ^testing.T) {
	m := make_multi(int, 33, {.No_Case})
	testing.expect_value(t, len(m.entries), 64)

	_map_setup(&m)
	
	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&m, fmt.tprintf("Key_Number_%d", i), i)
	}

	vals: []int
	ret: bool
	vals, ret = get(&m, "one")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 2)
	testing.expect_value(t, vals[0], 10)
	testing.expect_value(t, vals[1], 1)

	vals, ret = get(&m, "two")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 2)

	vals, ret = get(&m, "ten")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 10)

	vals, ret = get(&m, "twelve")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 12)

	vals, ret = get(&m, "test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 2)
	testing.expect_value(t, vals[0], 100)
	testing.expect_value(t, vals[1], 101)

	vals, ret = get(&m, "Test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 2)
	testing.expect_value(t, vals[0], 100)
	testing.expect_value(t, vals[1], 101)

	vals, ret = get(&m, "test ")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 102)

	vals, ret = get(&m, "no")
	testing.expect_value(t, ret, false)
	testing.expect_value(t, len(vals), 0)
}

@test
test_multi_rtrim :: proc(t: ^testing.T) {
	m := make_multi(int, 32, {.Rtrim})
	testing.expect_value(t, len(m.entries), 32)

	_map_setup(&m)
	
	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&m, fmt.tprintf("Key_Number_%d", i), i)
	}

	vals: []int
	ret: bool
	vals, ret = get(&m, "one")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 2)
	testing.expect_value(t, vals[0], 10)
	testing.expect_value(t, vals[1], 1)

	vals, ret = get(&m, "two")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 2)

	vals, ret = get(&m, "ten")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 10)

	vals, ret = get(&m, "twelve")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 12)

	vals, ret = get(&m, "test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 2)
	testing.expect_value(t, vals[0], 100)
	testing.expect_value(t, vals[1], 102)

	vals, ret = get(&m, "Test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 101)

	vals, ret = get(&m, "test ")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 2)
	testing.expect_value(t, vals[0], 100)
	testing.expect_value(t, vals[1], 102)

	vals, ret = get(&m, "no")
	testing.expect_value(t, ret, false)
	testing.expect_value(t, len(vals), 0)

}

@test
test_multi_nocase_rtrim :: proc(t: ^testing.T) {
	m := make_multi(int, 32, {.No_Case, .Rtrim})
	testing.expect_value(t, len(m.entries), 32)

	_map_setup(&m)
	
	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&m, fmt.tprintf("Key_Number_%d", i), i)
	}

	vals: []int
	ret: bool
	vals, ret = get(&m, "one")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 2)
	testing.expect_value(t, vals[0], 10)
	testing.expect_value(t, vals[1], 1)

	vals, ret = get(&m, "two")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 2)

	vals, ret = get(&m, "ten")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 10)

	vals, ret = get(&m, "twelve")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 1)
	testing.expect_value(t, vals[0], 12)

	vals, ret = get(&m, "test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 3)
	testing.expect_value(t, vals[0], 100)
	testing.expect_value(t, vals[1], 101)
	testing.expect_value(t, vals[2], 102)

	vals, ret = get(&m, "Test")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 3)
	testing.expect_value(t, vals[0], 100)
	testing.expect_value(t, vals[1], 101)
	testing.expect_value(t, vals[2], 102)

	vals, ret = get(&m, "test ")
	testing.expect_value(t, ret, true)
	testing.expect_value(t, len(vals), 3)
	testing.expect_value(t, vals[0], 100)
	testing.expect_value(t, vals[1], 101)
	testing.expect_value(t, vals[2], 102)

	vals, ret = get(&m, "no")
	testing.expect_value(t, ret, false)
	testing.expect_value(t, len(vals), 0)
}

@test
test_set_basic :: proc(t: ^testing.T) {
	s := make_set(16)
	_set_setup(&s)

	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&s, fmt.tprintf("Key_Number_%d", i))
	}

	ret: bool
	ret = get(&s, "one")
	testing.expect_value(t, ret, true)
	ret = get(&s, "two")
	testing.expect_value(t, ret, true)
	ret = get(&s, "ten")
	testing.expect_value(t, ret, true)
	ret = get(&s, "twelve")
	testing.expect_value(t, ret, true)
	ret = get(&s, "test")
	testing.expect_value(t, ret, true)
	ret = get(&s, "Test")
	testing.expect_value(t, ret, false)
	ret = get(&s, "test ")
	testing.expect_value(t, ret, false)
	ret = get(&s, "no")
	testing.expect_value(t, ret, false)
}

@test
test_set_nocase :: proc(t: ^testing.T) {
	s := make_set(16, {.No_Case})
	_set_setup(&s)

	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&s, fmt.tprintf("Key_Number_%d", i))
	}

	ret: bool
	ret = get(&s, "one")
	testing.expect_value(t, ret, true)
	ret = get(&s, "two")
	testing.expect_value(t, ret, true)
	ret = get(&s, "ten")
	testing.expect_value(t, ret, true)
	ret = get(&s, "twelve")
	testing.expect_value(t, ret, true)
	ret = get(&s, "test")
	testing.expect_value(t, ret, true)
	ret = get(&s, "Test")
	testing.expect_value(t, ret, true)
	ret = get(&s, "test ")
	testing.expect_value(t, ret, false)
	ret = get(&s, "no")
	testing.expect_value(t, ret, false)
}

@test
test_set_rtrim :: proc(t: ^testing.T) {
	s := make_set(16, {.Rtrim})
	_set_setup(&s)

	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&s, fmt.tprintf("Key_Number_%d", i))
	}

	ret: bool
	ret = get(&s, "one")
	testing.expect_value(t, ret, true)
	ret = get(&s, "two")
	testing.expect_value(t, ret, true)
	ret = get(&s, "ten")
	testing.expect_value(t, ret, true)
	ret = get(&s, "twelve")
	testing.expect_value(t, ret, true)
	ret = get(&s, "test")
	testing.expect_value(t, ret, true)
	ret = get(&s, "Test")
	testing.expect_value(t, ret, false)
	ret = get(&s, "test ")
	testing.expect_value(t, ret, true)
	ret = get(&s, "no")
	testing.expect_value(t, ret, false)
}

@test
test_set_nocase_rtrim :: proc(t: ^testing.T) {
	s := make_set(16, {.Rtrim, .No_Case})
	_set_setup(&s)

	/* Now insert so much crap, we must resize */
	for i := 0; i < 128; i += 1 {
		set(&s, fmt.tprintf("Key_Number_%d", i))
	}

	ret: bool
	ret = get(&s, "one")
	testing.expect_value(t, ret, true)
	ret = get(&s, "two")
	testing.expect_value(t, ret, true)
	ret = get(&s, "ten")
	testing.expect_value(t, ret, true)
	ret = get(&s, "twelve")
	testing.expect_value(t, ret, true)
	ret = get(&s, "test")
	testing.expect_value(t, ret, true)
	ret = get(&s, "Test")
	testing.expect_value(t, ret, true)
	ret = get(&s, "test ")
	testing.expect_value(t, ret, true)
	ret = get(&s, "no")
	testing.expect_value(t, ret, false)
}

@(private = "file")
_map_setup :: proc(m: $T) {
	set(m, "one", 10)
	set(m, "two", 2)
	set(m, "one", 1)
	set(m, "ten", 10)
	set(m, "twelve", 12)
	set(m, "test", 100)
	set(m, "Test", 101)
	set(m, "test ", 102)
}

@(private = "file")
_set_setup :: proc(s: ^Set) {
	set(s, "one")
	set(s, "two")
	set(s, "one")
	set(s, "ten")
	set(s, "twelve")
	set(s, "test")
	//set(m, "Test")
	//set(m, "test ")
}
