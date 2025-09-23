# converter.py
from decimal import Decimal, getcontext, ROUND_FLOOR
import math
from typing import Tuple, List

# Increase precision to handle fractional conversions reliably
getcontext().prec = 80

DIGITS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"  # supports up to base 36

class ConversionError(ValueError):
    pass

def _char_to_value(ch: str) -> int:
    ch = ch.upper()
    if ch not in DIGITS:
        raise ConversionError(f"Invalid digit character: {ch}")
    return DIGITS.index(ch)

def _value_to_char(v: int) -> str:
    if v < 0 or v >= len(DIGITS):
        raise ConversionError(f"Digit value out of range: {v}")
    return DIGITS[v]

def validate_input(s: str, base: int) -> None:
    if base < 2 or base > len(DIGITS):
        raise ConversionError(f"Base must be between 2 and {len(DIGITS)}")
    s = s.strip().upper()
    if s == '':
        raise ConversionError("Empty input")
    # allow leading negative sign
    if s[0] == '-':
        s = s[1:]
    parts = s.split('.')
    if len(parts) > 2:
        raise ConversionError("Invalid number format (more than one decimal point)")
    for ch in parts[0] + (parts[1] if len(parts) == 2 else ''):
        if ch == '':
            continue
        if ch not in DIGITS[:base]:
            raise ConversionError(f"Digit '{ch}' not valid in base {base}")

def to_decimal(input_str: str, from_base: int, steps: List[str]=None) -> Decimal:
    """
    Convert a string `input_str` in base `from_base` to a Decimal (base-10).
    steps (optional) will be appended with step descriptions.
    """
    validate_input(input_str, from_base)
    s = input_str.strip().upper()
    sign = 1
    if s.startswith('-'):
        sign = -1
        s = s[1:]
    if '.' in s:
        int_part_s, frac_part_s = s.split('.')
    else:
        int_part_s, frac_part_s = s, ''

    # Integer part (digit-by-digit, right-to-left)
    int_value = Decimal(0)
    for i, ch in enumerate(reversed(int_part_s or '0')):
        val = Decimal(_char_to_value(ch))
        term = val * (Decimal(from_base) ** i)
        int_value += term
        if steps is not None:
            steps.append(f"Int digit {ch} * {from_base}^{i} = {term}")

    # Fractional part (left-to-right)
    frac_value = Decimal(0)
    for i, ch in enumerate(frac_part_s, start=1):
        val = Decimal(_char_to_value(ch))
        term = val / (Decimal(from_base) ** i)
        frac_value += term
        if steps is not None:
            steps.append(f"Frac digit {ch} / {from_base}^{i} = {term}")

    result = (int_value + frac_value) * sign
    if steps is not None:
        steps.append(f"Decimal result = {result}")
    return result

def from_decimal(value: Decimal, to_base: int, precision: int = 12, steps: List[str]=None) -> str:
    """
    Convert a Decimal `value` into a string in base `to_base`.
    `precision` controls number of fractional digits produced.
    steps (optional) will receive step traces.
    """
    if to_base < 2 or to_base > len(DIGITS):
        raise ConversionError(f"Target base must be between 2 and {len(DIGITS)}")

    if value == 0:
        return "0"

    sign = '-' if value < 0 else ''
    value = abs(value)

    # Integer part
    int_part = int(value.to_integral_value(rounding=ROUND_FLOOR))
    frac_part = value - Decimal(int_part)

    int_digits = []
    if int_part == 0:
        int_digits = ['0']
    else:
        n = int_part
        idx = 0
        while n > 0:
            rem = n % to_base
            int_digits.append(_value_to_char(rem))
            if steps is not None:
                steps.append(f"Integer division: n={n}, rem={rem} -> '{_value_to_char(rem)}'")
            n = n // to_base
            idx += 1
        int_digits.reverse()

    # Fractional part
    frac_digits = []
    count = 0
    while frac_part != 0 and count < precision:
        frac_part *= to_base
        digit = int(frac_part.to_integral_value(rounding=ROUND_FLOOR))
        frac_digits.append(_value_to_char(digit))
        if steps is not None:
            steps.append(f"Frac * {to_base} = {frac_part} -> digit {digit} ('{_value_to_char(digit)}')")
        frac_part -= Decimal(digit)
        count += 1

    if frac_digits:
        return sign + ''.join(int_digits) + '.' + ''.join(frac_digits)
    else:
        return sign + ''.join(int_digits)

def convert(input_str: str, from_base: int, to_base: int, precision: int = 12, show_steps: bool = False) -> Tuple[str, List[str]]:
    """
    Convenience wrapper: converts input_str from `from_base` to `to_base`.
    Returns (result_str, steps_list).
    """
    steps = [] if show_steps else None
    dec = to_decimal(input_str, from_base, steps=steps)
    out = from_decimal(dec, to_base, precision=precision, steps=steps)
    if steps is not None:
        steps.insert(0, f"{input_str} (base {from_base}) -> decimal approximation: {dec}")
        steps.append(f"Output: {out} (base {to_base})")
    return out, steps or []

# Example usage if run as main
if __name__ == "__main__":
    examples = ["101.101", "FF.A", "10.5", "-2A.E"]
    for ex in examples:
        try:
            res, s = convert(ex, 2 if ex.startswith('101') else 16 if 'F' in ex or 'A' in ex else 10,
                              10, precision=8, show_steps=True)
            print(f"{ex} -> {res}")
            for line in s:
                print("  ", line)
            print("-" * 40)
        except ConversionError as ce:
            print("Error:", ce)
