extends GdUnitTestSuite

# Simple example test to verify gdUnit4 is working

func test_basic_assertion():
	assert_that(2 + 2).is_equal(4)

func test_string_assertion():
	assert_that("hello").is_equal("hello")

func test_boolean_assertion():
	assert_that(true).is_true()
	assert_that(false).is_false()

func test_array_assertion():
	var arr = [1, 2, 3]
	assert_that(arr).has_size(3)
	assert_that(arr).contains([1, 2, 3])

func test_vector_assertion():
	var vec = Vector2(10, 20)
	assert_that(vec.x).is_equal(10.0)
	assert_that(vec.y).is_equal(20.0)