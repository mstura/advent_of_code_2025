package utils

import "base:runtime"
import "core:text/regex"

@(require_results)
slice_splice :: proc(s: $S/[]$U, idx: int, allocator := context.allocator) -> (res: S, err: runtime.Allocator_Error) #optional_allocator_error {
	r := make([dynamic]U, 0, len(s), allocator) or_return
	for v, i in s {
		if i != idx {
			append(&r, v)
		}
	}
	return r[:], nil
}

regex_iterator :: proc(r: regex.Regular_Expression, str: ^string, capture: ^regex.Capture) -> (ok: bool) {
  _, ok = regex.match(r, str^, capture)
  s := capture.pos[0].y

  if len(str) < s {
    str^ = str[len(str):]
  } else {
    str^ = str[capture.pos[0].y:]
  }

  return 
}
