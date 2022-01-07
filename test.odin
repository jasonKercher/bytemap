package bytemap

import "core:testing"

@(private = "file")
_map_setup :: proc(m: ^Map(int)) {
	set(m, "one", 10)
	set(m, "two", 2)
	set(m, "one", 1)
	set(m, "ten", 10)
	set(m, "twelve", 12)
	set(m, "test", 100)
	set(m, "Test", 101)
	set(m, "test ", 102)
}

@test
test_map_basic :: proc(t: ^testing.T) {
	m := make_map(int, 16)
	_map_setup(&m)

	val: int
	ret: Result
	val, ret = get(&m, "one")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 1)
	val, ret = get(&m, "two")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 2)
	val, ret = get(&m, "ten")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 10)
	val, ret = get(&m, "twelve")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 12)
	val, ret = get(&m, "test")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 100)
	val, ret = get(&m, "Test")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 101)
	val, ret = get(&m, "test ")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "no")
	testing.expect_value(t, ret, Result.Not_Found)
	testing.expect_value(t, val, 0)

	destroy_map(&m)
}

@test
test_map_nocase :: proc(t: ^testing.T) {
	m := make_map(int, 16, {.No_Case})
	_map_setup(&m)

	val: int
	ret: Result
	val, ret = get(&m, "one")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 1)
	val, ret = get(&m, "two")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 2)
	val, ret = get(&m, "ten")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 10)
	val, ret = get(&m, "twelve")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 12)
	val, ret = get(&m, "test")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 101)
	val, ret = get(&m, "Test")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 101)
	val, ret = get(&m, "test ")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "no")
	testing.expect_value(t, ret, Result.Not_Found)
	testing.expect_value(t, val, 0)

	destroy_map(&m)
}

@test
test_map_rtrim :: proc(t: ^testing.T) {
	m := make_map(int, 16, {.Rtrim})
	_map_setup(&m)

	val: int
	ret: Result
	val, ret = get(&m, "one")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 1)
	val, ret = get(&m, "two")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 2)
	val, ret = get(&m, "ten")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 10)
	val, ret = get(&m, "twelve")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 12)
	val, ret = get(&m, "test")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "Test")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 101)
	val, ret = get(&m, "test ")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "no")
	testing.expect_value(t, ret, Result.Not_Found)
	testing.expect_value(t, val, 0)

	destroy_map(&m)
}

@test
test_map_nocase_rtrim :: proc(t: ^testing.T) {
	m := make_map(int, 16, {.No_Case, .Rtrim})
	_map_setup(&m)

	val: int
	ret: Result
	val, ret = get(&m, "one")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 1)
	val, ret = get(&m, "two")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 2)
	val, ret = get(&m, "ten")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 10)
	val, ret = get(&m, "twelve")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 12)
	val, ret = get(&m, "test")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "Test")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "test ")
	testing.expect_value(t, ret, Result.Found)
	testing.expect_value(t, val, 102)
	val, ret = get(&m, "no")
	testing.expect_value(t, ret, Result.Not_Found)
	testing.expect_value(t, val, 0)

	destroy_map(&m)
}
