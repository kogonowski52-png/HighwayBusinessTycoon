class_name HbtAmount
extends RefCounted
## Exact, non-negative amounts. Each operation returns a new value.
## A six-digit limb times the largest supported factor still fits in int64.

const BASE := 1_000_000
const CHUNK := 6
const MAX_SAVE_DIGITS := 384
const MAX_FACTOR := 1_000_000_000
const SUFFIX := ["", "k", "M", "B", "T", "Qa", "Qi"]
var _limbs: PackedInt64Array

func _init(limbs := PackedInt64Array([0])) -> void:
	_limbs = limbs
	while _limbs.size() > 1 and _limbs[-1] == 0:
		_limbs.resize(_limbs.size() - 1)

static func from(value: Variant) -> HbtAmount:
	if value is HbtAmount:
		return value
	var source: String
	match typeof(value):
		TYPE_INT:
			source = str(maxi(0, value))
		TYPE_STRING:
			source = value
		_:
			return HbtAmount.new()
	if not valid_decimal(source):
		return HbtAmount.new()
	var limbs := PackedInt64Array()
	for end in range(source.length(), 0, -CHUNK):
		var start := maxi(0, end - CHUNK)
		limbs.append(source.substr(start, end - start).to_int())
	return HbtAmount.new(limbs)

static func valid_decimal(source: String) -> bool:
	if source.is_empty() or source.length() > MAX_SAVE_DIGITS:
		return false
	for i in range(source.length()):
		var rune := source.unicode_at(i)
		if rune < 48 or rune > 57:
			return false
	return true

func empty() -> bool:
	return _limbs.size() == 1 and _limbs[0] == 0

func compare(other: HbtAmount) -> int:
	if _limbs.size() != other._limbs.size():
		return 1 if _limbs.size() > other._limbs.size() else -1
	for i in range(_limbs.size() - 1, -1, -1):
		if _limbs[i] != other._limbs[i]:
			return 1 if _limbs[i] > other._limbs[i] else -1
	return 0

func plus(other: HbtAmount) -> HbtAmount:
	var result := PackedInt64Array()
	var carry := 0
	for i in range(maxi(_limbs.size(), other._limbs.size())):
		var total := limb(i) + other.limb(i) + carry
		result.append(total % BASE)
		carry = int(total >= BASE)
	if carry != 0:
		result.append(carry)
	return HbtAmount.new(result)

func minus(other: HbtAmount) -> HbtAmount:
	if compare(other) <= 0:
		return HbtAmount.new()
	var result := PackedInt64Array()
	var borrow := 0
	for i in range(_limbs.size()):
		var difference := limb(i) - other.limb(i) - borrow
		borrow = int(difference < 0)
		result.append(difference + borrow * BASE)
	return HbtAmount.new(result)

@warning_ignore("integer_division")
func times(factor: int) -> HbtAmount:
	assert(factor >= 0 and factor <= MAX_FACTOR)
	var result := PackedInt64Array()
	var carry := 0
	for value in _limbs:
		var scaled := value * factor + carry
		result.append(scaled % BASE)
		carry = scaled / BASE
	while carry > 0:
		result.append(carry % BASE)
		carry /= BASE
	return HbtAmount.new(result)

@warning_ignore("integer_division")
func divided(by: int) -> HbtAmount:
	assert(by > 0 and by <= MAX_FACTOR)
	var result := PackedInt64Array()
	result.resize(_limbs.size())
	var remainder := 0
	for i in range(_limbs.size() - 1, -1, -1):
		var value := remainder * BASE + _limbs[i]
		result[i] = value / by
		remainder = value % by
	return HbtAmount.new(result)

func limb(index: int) -> int:
	return _limbs[index] if index < _limbs.size() else 0

func decimal() -> String:
	var result := str(_limbs[-1])
	for i in range(_limbs.size() - 2, -1, -1):
		result += "%06d" % _limbs[i]
	return result

func grouped(language: String) -> String:
	var digits := decimal()
	var separator := " " if language == "pl" else ","
	var first := (digits.length() - 1) % 3 + 1
	var display := digits.left(first)
	for index in range(first, digits.length(), 3):
		display += separator + digits.substr(index, 3)
	return display

@warning_ignore("integer_division")
func compact(language := "en") -> String:
	var source := decimal()
	if source.length() <= 4:
		return source
	var group := (source.length() - 1) / 3
	var separator := "," if language == "pl" else "."
	if group >= SUFFIX.size():
		return "%s%s%se%d" % [source[0], separator, source.substr(1, 2), source.length() - 1]
	var whole := source.length() - group * 3
	var tail := source.substr(whole, 2).rstrip("0")
	return source.substr(0, whole) + (separator + tail if not tail.is_empty() else "") + SUFFIX[group]
