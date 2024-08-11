// build/dev/javascript/prelude.mjs
var CustomType = class {
  withFields(fields) {
    let properties = Object.keys(this).map(
      (label) => label in fields ? fields[label] : this[label]
    );
    return new this.constructor(...properties);
  }
};
var List = class {
  static fromArray(array3, tail) {
    let t = tail || new Empty();
    for (let i = array3.length - 1; i >= 0; --i) {
      t = new NonEmpty(array3[i], t);
    }
    return t;
  }
  [Symbol.iterator]() {
    return new ListIterator(this);
  }
  toArray() {
    return [...this];
  }
  // @internal
  atLeastLength(desired) {
    for (let _ of this) {
      if (desired <= 0)
        return true;
      desired--;
    }
    return desired <= 0;
  }
  // @internal
  hasLength(desired) {
    for (let _ of this) {
      if (desired <= 0)
        return false;
      desired--;
    }
    return desired === 0;
  }
  countLength() {
    let length3 = 0;
    for (let _ of this)
      length3++;
    return length3;
  }
};
function prepend(element2, tail) {
  return new NonEmpty(element2, tail);
}
function toList(elements, tail) {
  return List.fromArray(elements, tail);
}
var ListIterator = class {
  #current;
  constructor(current) {
    this.#current = current;
  }
  next() {
    if (this.#current instanceof Empty) {
      return { done: true };
    } else {
      let { head: head2, tail } = this.#current;
      this.#current = tail;
      return { value: head2, done: false };
    }
  }
};
var Empty = class extends List {
};
var NonEmpty = class extends List {
  constructor(head2, tail) {
    super();
    this.head = head2;
    this.tail = tail;
  }
};
var Result = class _Result extends CustomType {
  // @internal
  static isResult(data) {
    return data instanceof _Result;
  }
};
var Ok = class extends Result {
  constructor(value) {
    super();
    this[0] = value;
  }
  // @internal
  isOk() {
    return true;
  }
};
var Error = class extends Result {
  constructor(detail) {
    super();
    this[0] = detail;
  }
  // @internal
  isOk() {
    return false;
  }
};
function isEqual(x, y) {
  let values = [x, y];
  while (values.length) {
    let a = values.pop();
    let b = values.pop();
    if (a === b)
      continue;
    if (!isObject(a) || !isObject(b))
      return false;
    let unequal = !structurallyCompatibleObjects(a, b) || unequalDates(a, b) || unequalBuffers(a, b) || unequalArrays(a, b) || unequalMaps(a, b) || unequalSets(a, b) || unequalRegExps(a, b);
    if (unequal)
      return false;
    const proto = Object.getPrototypeOf(a);
    if (proto !== null && typeof proto.equals === "function") {
      try {
        if (a.equals(b))
          continue;
        else
          return false;
      } catch {
      }
    }
    let [keys2, get3] = getters(a);
    for (let k of keys2(a)) {
      values.push(get3(a, k), get3(b, k));
    }
  }
  return true;
}
function getters(object3) {
  if (object3 instanceof Map) {
    return [(x) => x.keys(), (x, y) => x.get(y)];
  } else {
    let extra = object3 instanceof globalThis.Error ? ["message"] : [];
    return [(x) => [...extra, ...Object.keys(x)], (x, y) => x[y]];
  }
}
function unequalDates(a, b) {
  return a instanceof Date && (a > b || a < b);
}
function unequalBuffers(a, b) {
  return a.buffer instanceof ArrayBuffer && a.BYTES_PER_ELEMENT && !(a.byteLength === b.byteLength && a.every((n, i) => n === b[i]));
}
function unequalArrays(a, b) {
  return Array.isArray(a) && a.length !== b.length;
}
function unequalMaps(a, b) {
  return a instanceof Map && a.size !== b.size;
}
function unequalSets(a, b) {
  return a instanceof Set && (a.size != b.size || [...a].some((e) => !b.has(e)));
}
function unequalRegExps(a, b) {
  return a instanceof RegExp && (a.source !== b.source || a.flags !== b.flags);
}
function isObject(a) {
  return typeof a === "object" && a !== null;
}
function structurallyCompatibleObjects(a, b) {
  if (typeof a !== "object" && typeof b !== "object" && (!a || !b))
    return false;
  let nonstructural = [Promise, WeakSet, WeakMap, Function];
  if (nonstructural.some((c) => a instanceof c))
    return false;
  return a.constructor === b.constructor;
}
function divideInt(a, b) {
  return Math.trunc(divideFloat(a, b));
}
function divideFloat(a, b) {
  if (b === 0) {
    return 0;
  } else {
    return a / b;
  }
}
function makeError(variant, module, line3, fn, message, extra) {
  let error = new globalThis.Error(message);
  error.gleam_error = variant;
  error.module = module;
  error.line = line3;
  error.fn = fn;
  for (let k in extra)
    error[k] = extra[k];
  return error;
}

// build/dev/javascript/gleam_stdlib/gleam/order.mjs
var Lt = class extends CustomType {
};
var Eq = class extends CustomType {
};
var Gt = class extends CustomType {
};

// build/dev/javascript/gleam_stdlib/gleam/option.mjs
var Some = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var None = class extends CustomType {
};
function from_result(result) {
  if (result.isOk()) {
    let a = result[0];
    return new Some(a);
  } else {
    return new None();
  }
}

// build/dev/javascript/gleam_stdlib/gleam/dict.mjs
function new$() {
  return new_map();
}
function get(from3, get3) {
  return map_get(from3, get3);
}
function insert(dict, key, value) {
  return map_insert(key, value, dict);
}
function fold_list_of_pair(loop$list, loop$initial) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    if (list.hasLength(0)) {
      return initial;
    } else {
      let x = list.head;
      let rest = list.tail;
      loop$list = rest;
      loop$initial = insert(initial, x[0], x[1]);
    }
  }
}
function from_list(list) {
  return fold_list_of_pair(list, new$());
}
function update(dict, key, fun) {
  let _pipe = dict;
  let _pipe$1 = get(_pipe, key);
  let _pipe$2 = from_result(_pipe$1);
  let _pipe$3 = fun(_pipe$2);
  return ((_capture) => {
    return insert(dict, key, _capture);
  })(_pipe$3);
}
function do_fold(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list.hasLength(0)) {
      return initial;
    } else {
      let k = list.head[0];
      let v = list.head[1];
      let rest = list.tail;
      loop$list = rest;
      loop$initial = fun(initial, k, v);
      loop$fun = fun;
    }
  }
}
function fold(dict, initial, fun) {
  let _pipe = dict;
  let _pipe$1 = map_to_list(_pipe);
  return do_fold(_pipe$1, initial, fun);
}
function do_map_values(f, dict) {
  let f$1 = (dict2, k, v) => {
    return insert(dict2, k, f(k, v));
  };
  let _pipe = dict;
  return fold(_pipe, new$(), f$1);
}
function map_values(dict, fun) {
  return do_map_values(fun, dict);
}
function combine(dict, other, fun) {
  return fold(
    dict,
    other,
    (acc, key, value) => {
      let $ = get(acc, key);
      if ($.isOk()) {
        let other_value = $[0];
        return insert(acc, key, fun(value, other_value));
      } else {
        return insert(acc, key, value);
      }
    }
  );
}

// build/dev/javascript/gleam_stdlib/gleam/int.mjs
function to_string2(x) {
  return to_string(x);
}
function to_float(x) {
  return identity(x);
}
function compare(a, b) {
  let $ = a === b;
  if ($) {
    return new Eq();
  } else {
    let $1 = a < b;
    if ($1) {
      return new Lt();
    } else {
      return new Gt();
    }
  }
}
function min(a, b) {
  let $ = a < b;
  if ($) {
    return a;
  } else {
    return b;
  }
}
function max(a, b) {
  let $ = a > b;
  if ($) {
    return a;
  } else {
    return b;
  }
}
function clamp(x, min_bound, max_bound) {
  let _pipe = x;
  let _pipe$1 = min(_pipe, max_bound);
  return max(_pipe$1, min_bound);
}
function random(max2) {
  let _pipe = random_uniform() * to_float(max2);
  let _pipe$1 = floor(_pipe);
  return round(_pipe$1);
}

// build/dev/javascript/gleam_stdlib/gleam/list.mjs
var Ascending = class extends CustomType {
};
var Descending = class extends CustomType {
};
function count_length(loop$list, loop$count) {
  while (true) {
    let list = loop$list;
    let count = loop$count;
    if (list.atLeastLength(1)) {
      let list$1 = list.tail;
      loop$list = list$1;
      loop$count = count + 1;
    } else {
      return count;
    }
  }
}
function length(list) {
  return count_length(list, 0);
}
function do_reverse(loop$remaining, loop$accumulator) {
  while (true) {
    let remaining = loop$remaining;
    let accumulator = loop$accumulator;
    if (remaining.hasLength(0)) {
      return accumulator;
    } else {
      let item = remaining.head;
      let rest$1 = remaining.tail;
      loop$remaining = rest$1;
      loop$accumulator = prepend(item, accumulator);
    }
  }
}
function reverse(xs) {
  return do_reverse(xs, toList([]));
}
function contains(loop$list, loop$elem) {
  while (true) {
    let list = loop$list;
    let elem = loop$elem;
    if (list.hasLength(0)) {
      return false;
    } else if (list.atLeastLength(1) && isEqual(list.head, elem)) {
      let first$1 = list.head;
      return true;
    } else {
      let rest$1 = list.tail;
      loop$list = rest$1;
      loop$elem = elem;
    }
  }
}
function do_filter(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return reverse(acc);
    } else {
      let x = list.head;
      let xs = list.tail;
      let new_acc = (() => {
        let $ = fun(x);
        if ($) {
          return prepend(x, acc);
        } else {
          return acc;
        }
      })();
      loop$list = xs;
      loop$fun = fun;
      loop$acc = new_acc;
    }
  }
}
function filter(list, predicate) {
  return do_filter(list, predicate, toList([]));
}
function do_map(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return reverse(acc);
    } else {
      let x = list.head;
      let xs = list.tail;
      loop$list = xs;
      loop$fun = fun;
      loop$acc = prepend(fun(x), acc);
    }
  }
}
function map(list, fun) {
  return do_map(list, fun, toList([]));
}
function do_map2(loop$list1, loop$list2, loop$fun, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list1.hasLength(0)) {
      return reverse(acc);
    } else if (list2.hasLength(0)) {
      return reverse(acc);
    } else {
      let a = list1.head;
      let as_ = list1.tail;
      let b = list2.head;
      let bs = list2.tail;
      loop$list1 = as_;
      loop$list2 = bs;
      loop$fun = fun;
      loop$acc = prepend(fun(a, b), acc);
    }
  }
}
function map2(list1, list2, fun) {
  return do_map2(list1, list2, fun, toList([]));
}
function do_append(loop$first, loop$second) {
  while (true) {
    let first = loop$first;
    let second = loop$second;
    if (first.hasLength(0)) {
      return second;
    } else {
      let item = first.head;
      let rest$1 = first.tail;
      loop$first = rest$1;
      loop$second = prepend(item, second);
    }
  }
}
function append(first, second) {
  return do_append(reverse(first), second);
}
function reverse_and_prepend(loop$prefix, loop$suffix) {
  while (true) {
    let prefix = loop$prefix;
    let suffix = loop$suffix;
    if (prefix.hasLength(0)) {
      return suffix;
    } else {
      let first$1 = prefix.head;
      let rest$1 = prefix.tail;
      loop$prefix = rest$1;
      loop$suffix = prepend(first$1, suffix);
    }
  }
}
function do_concat(loop$lists, loop$acc) {
  while (true) {
    let lists = loop$lists;
    let acc = loop$acc;
    if (lists.hasLength(0)) {
      return reverse(acc);
    } else {
      let list = lists.head;
      let further_lists = lists.tail;
      loop$lists = further_lists;
      loop$acc = reverse_and_prepend(list, acc);
    }
  }
}
function flatten(lists) {
  return do_concat(lists, toList([]));
}
function fold2(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list.hasLength(0)) {
      return initial;
    } else {
      let x = list.head;
      let rest$1 = list.tail;
      loop$list = rest$1;
      loop$initial = fun(initial, x);
      loop$fun = fun;
    }
  }
}
function sequences(loop$list, loop$compare, loop$growing, loop$direction, loop$prev, loop$acc) {
  while (true) {
    let list = loop$list;
    let compare3 = loop$compare;
    let growing = loop$growing;
    let direction = loop$direction;
    let prev = loop$prev;
    let acc = loop$acc;
    let growing$1 = prepend(prev, growing);
    if (list.hasLength(0)) {
      if (direction instanceof Ascending) {
        return prepend(do_reverse(growing$1, toList([])), acc);
      } else {
        return prepend(growing$1, acc);
      }
    } else {
      let new$1 = list.head;
      let rest$1 = list.tail;
      let $ = compare3(prev, new$1);
      if ($ instanceof Gt && direction instanceof Descending) {
        loop$list = rest$1;
        loop$compare = compare3;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      } else if ($ instanceof Lt && direction instanceof Ascending) {
        loop$list = rest$1;
        loop$compare = compare3;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      } else if ($ instanceof Eq && direction instanceof Ascending) {
        loop$list = rest$1;
        loop$compare = compare3;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      } else if ($ instanceof Gt && direction instanceof Ascending) {
        let acc$1 = (() => {
          if (direction instanceof Ascending) {
            return prepend(do_reverse(growing$1, toList([])), acc);
          } else {
            return prepend(growing$1, acc);
          }
        })();
        if (rest$1.hasLength(0)) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let direction$1 = (() => {
            let $1 = compare3(new$1, next);
            if ($1 instanceof Lt) {
              return new Ascending();
            } else if ($1 instanceof Eq) {
              return new Ascending();
            } else {
              return new Descending();
            }
          })();
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      } else if ($ instanceof Lt && direction instanceof Descending) {
        let acc$1 = (() => {
          if (direction instanceof Ascending) {
            return prepend(do_reverse(growing$1, toList([])), acc);
          } else {
            return prepend(growing$1, acc);
          }
        })();
        if (rest$1.hasLength(0)) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let direction$1 = (() => {
            let $1 = compare3(new$1, next);
            if ($1 instanceof Lt) {
              return new Ascending();
            } else if ($1 instanceof Eq) {
              return new Ascending();
            } else {
              return new Descending();
            }
          })();
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      } else {
        let acc$1 = (() => {
          if (direction instanceof Ascending) {
            return prepend(do_reverse(growing$1, toList([])), acc);
          } else {
            return prepend(growing$1, acc);
          }
        })();
        if (rest$1.hasLength(0)) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let direction$1 = (() => {
            let $1 = compare3(new$1, next);
            if ($1 instanceof Lt) {
              return new Ascending();
            } else if ($1 instanceof Eq) {
              return new Ascending();
            } else {
              return new Descending();
            }
          })();
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      }
    }
  }
}
function merge_ascendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (list1.hasLength(0)) {
      let list = list2;
      return do_reverse(list, acc);
    } else if (list2.hasLength(0)) {
      let list = list1;
      return do_reverse(list, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first2 = list2.head;
      let rest2 = list2.tail;
      let $ = compare3(first1, first2);
      if ($ instanceof Lt) {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      } else if ($ instanceof Gt) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      } else {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      }
    }
  }
}
function merge_ascending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (sequences2.hasLength(0)) {
      return do_reverse(acc, toList([]));
    } else if (sequences2.hasLength(1)) {
      let sequence = sequences2.head;
      return do_reverse(
        prepend(do_reverse(sequence, toList([])), acc),
        toList([])
      );
    } else {
      let ascending1 = sequences2.head;
      let ascending2 = sequences2.tail.head;
      let rest$1 = sequences2.tail.tail;
      let descending = merge_ascendings(
        ascending1,
        ascending2,
        compare3,
        toList([])
      );
      loop$sequences = rest$1;
      loop$compare = compare3;
      loop$acc = prepend(descending, acc);
    }
  }
}
function merge_descendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (list1.hasLength(0)) {
      let list = list2;
      return do_reverse(list, acc);
    } else if (list2.hasLength(0)) {
      let list = list1;
      return do_reverse(list, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first2 = list2.head;
      let rest2 = list2.tail;
      let $ = compare3(first1, first2);
      if ($ instanceof Lt) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      } else if ($ instanceof Gt) {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      } else {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      }
    }
  }
}
function merge_descending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (sequences2.hasLength(0)) {
      return do_reverse(acc, toList([]));
    } else if (sequences2.hasLength(1)) {
      let sequence = sequences2.head;
      return do_reverse(
        prepend(do_reverse(sequence, toList([])), acc),
        toList([])
      );
    } else {
      let descending1 = sequences2.head;
      let descending2 = sequences2.tail.head;
      let rest$1 = sequences2.tail.tail;
      let ascending = merge_descendings(
        descending1,
        descending2,
        compare3,
        toList([])
      );
      loop$sequences = rest$1;
      loop$compare = compare3;
      loop$acc = prepend(ascending, acc);
    }
  }
}
function merge_all(loop$sequences, loop$direction, loop$compare) {
  while (true) {
    let sequences2 = loop$sequences;
    let direction = loop$direction;
    let compare3 = loop$compare;
    if (sequences2.hasLength(0)) {
      return toList([]);
    } else if (sequences2.hasLength(1) && direction instanceof Ascending) {
      let sequence = sequences2.head;
      return sequence;
    } else if (sequences2.hasLength(1) && direction instanceof Descending) {
      let sequence = sequences2.head;
      return do_reverse(sequence, toList([]));
    } else if (direction instanceof Ascending) {
      let sequences$1 = merge_ascending_pairs(sequences2, compare3, toList([]));
      loop$sequences = sequences$1;
      loop$direction = new Descending();
      loop$compare = compare3;
    } else {
      let sequences$1 = merge_descending_pairs(sequences2, compare3, toList([]));
      loop$sequences = sequences$1;
      loop$direction = new Ascending();
      loop$compare = compare3;
    }
  }
}
function sort(list, compare3) {
  if (list.hasLength(0)) {
    return toList([]);
  } else if (list.hasLength(1)) {
    let x = list.head;
    return toList([x]);
  } else {
    let x = list.head;
    let y = list.tail.head;
    let rest$1 = list.tail.tail;
    let direction = (() => {
      let $ = compare3(x, y);
      if ($ instanceof Lt) {
        return new Ascending();
      } else if ($ instanceof Eq) {
        return new Ascending();
      } else {
        return new Descending();
      }
    })();
    let sequences$1 = sequences(
      rest$1,
      compare3,
      toList([x]),
      direction,
      y,
      toList([])
    );
    return merge_all(sequences$1, new Ascending(), compare3);
  }
}
function tail_recursive_range(loop$start, loop$stop, loop$acc) {
  while (true) {
    let start4 = loop$start;
    let stop = loop$stop;
    let acc = loop$acc;
    let $ = compare(start4, stop);
    if ($ instanceof Eq) {
      return prepend(stop, acc);
    } else if ($ instanceof Gt) {
      loop$start = start4;
      loop$stop = stop + 1;
      loop$acc = prepend(stop, acc);
    } else {
      loop$start = start4;
      loop$stop = stop - 1;
      loop$acc = prepend(stop, acc);
    }
  }
}
function range(start4, stop) {
  return tail_recursive_range(start4, stop, toList([]));
}
function do_shuffle_pair_unwrap(loop$list, loop$acc) {
  while (true) {
    let list = loop$list;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return acc;
    } else {
      let elem_pair = list.head;
      let enumerable = list.tail;
      loop$list = enumerable;
      loop$acc = prepend(elem_pair[1], acc);
    }
  }
}
function do_shuffle_by_pair_indexes(list_of_pairs) {
  return sort(
    list_of_pairs,
    (a_pair, b_pair) => {
      return compare2(a_pair[0], b_pair[0]);
    }
  );
}
function shuffle(list) {
  let _pipe = list;
  let _pipe$1 = fold2(
    _pipe,
    toList([]),
    (acc, a) => {
      return prepend([random_uniform(), a], acc);
    }
  );
  let _pipe$2 = do_shuffle_by_pair_indexes(_pipe$1);
  return do_shuffle_pair_unwrap(_pipe$2, toList([]));
}

// build/dev/javascript/gleam_stdlib/gleam/result.mjs
function is_ok(result) {
  if (!result.isOk()) {
    return false;
  } else {
    return true;
  }
}

// build/dev/javascript/gleam_stdlib/gleam/string_builder.mjs
function from_string(string2) {
  return identity(string2);
}
function to_string3(builder) {
  return identity(builder);
}
function split2(iodata, pattern2) {
  return split(iodata, pattern2);
}

// build/dev/javascript/gleam_stdlib/gleam/dynamic.mjs
function from(a) {
  return identity(a);
}

// build/dev/javascript/gleam_stdlib/dict.mjs
var referenceMap = /* @__PURE__ */ new WeakMap();
var tempDataView = new DataView(new ArrayBuffer(8));
var referenceUID = 0;
function hashByReference(o) {
  const known = referenceMap.get(o);
  if (known !== void 0) {
    return known;
  }
  const hash = referenceUID++;
  if (referenceUID === 2147483647) {
    referenceUID = 0;
  }
  referenceMap.set(o, hash);
  return hash;
}
function hashMerge(a, b) {
  return a ^ b + 2654435769 + (a << 6) + (a >> 2) | 0;
}
function hashString(s) {
  let hash = 0;
  const len = s.length;
  for (let i = 0; i < len; i++) {
    hash = Math.imul(31, hash) + s.charCodeAt(i) | 0;
  }
  return hash;
}
function hashNumber(n) {
  tempDataView.setFloat64(0, n);
  const i = tempDataView.getInt32(0);
  const j = tempDataView.getInt32(4);
  return Math.imul(73244475, i >> 16 ^ i) ^ j;
}
function hashBigInt(n) {
  return hashString(n.toString());
}
function hashObject(o) {
  const proto = Object.getPrototypeOf(o);
  if (proto !== null && typeof proto.hashCode === "function") {
    try {
      const code = o.hashCode(o);
      if (typeof code === "number") {
        return code;
      }
    } catch {
    }
  }
  if (o instanceof Promise || o instanceof WeakSet || o instanceof WeakMap) {
    return hashByReference(o);
  }
  if (o instanceof Date) {
    return hashNumber(o.getTime());
  }
  let h = 0;
  if (o instanceof ArrayBuffer) {
    o = new Uint8Array(o);
  }
  if (Array.isArray(o) || o instanceof Uint8Array) {
    for (let i = 0; i < o.length; i++) {
      h = Math.imul(31, h) + getHash(o[i]) | 0;
    }
  } else if (o instanceof Set) {
    o.forEach((v) => {
      h = h + getHash(v) | 0;
    });
  } else if (o instanceof Map) {
    o.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
  } else {
    const keys2 = Object.keys(o);
    for (let i = 0; i < keys2.length; i++) {
      const k = keys2[i];
      const v = o[k];
      h = h + hashMerge(getHash(v), hashString(k)) | 0;
    }
  }
  return h;
}
function getHash(u) {
  if (u === null)
    return 1108378658;
  if (u === void 0)
    return 1108378659;
  if (u === true)
    return 1108378657;
  if (u === false)
    return 1108378656;
  switch (typeof u) {
    case "number":
      return hashNumber(u);
    case "string":
      return hashString(u);
    case "bigint":
      return hashBigInt(u);
    case "object":
      return hashObject(u);
    case "symbol":
      return hashByReference(u);
    case "function":
      return hashByReference(u);
    default:
      return 0;
  }
}
var SHIFT = 5;
var BUCKET_SIZE = Math.pow(2, SHIFT);
var MASK = BUCKET_SIZE - 1;
var MAX_INDEX_NODE = BUCKET_SIZE / 2;
var MIN_ARRAY_NODE = BUCKET_SIZE / 4;
var ENTRY = 0;
var ARRAY_NODE = 1;
var INDEX_NODE = 2;
var COLLISION_NODE = 3;
var EMPTY = {
  type: INDEX_NODE,
  bitmap: 0,
  array: []
};
function mask(hash, shift) {
  return hash >>> shift & MASK;
}
function bitpos(hash, shift) {
  return 1 << mask(hash, shift);
}
function bitcount(x) {
  x -= x >> 1 & 1431655765;
  x = (x & 858993459) + (x >> 2 & 858993459);
  x = x + (x >> 4) & 252645135;
  x += x >> 8;
  x += x >> 16;
  return x & 127;
}
function index(bitmap, bit) {
  return bitcount(bitmap & bit - 1);
}
function cloneAndSet(arr, at, val) {
  const len = arr.length;
  const out = new Array(len);
  for (let i = 0; i < len; ++i) {
    out[i] = arr[i];
  }
  out[at] = val;
  return out;
}
function spliceIn(arr, at, val) {
  const len = arr.length;
  const out = new Array(len + 1);
  let i = 0;
  let g2 = 0;
  while (i < at) {
    out[g2++] = arr[i++];
  }
  out[g2++] = val;
  while (i < len) {
    out[g2++] = arr[i++];
  }
  return out;
}
function spliceOut(arr, at) {
  const len = arr.length;
  const out = new Array(len - 1);
  let i = 0;
  let g2 = 0;
  while (i < at) {
    out[g2++] = arr[i++];
  }
  ++i;
  while (i < len) {
    out[g2++] = arr[i++];
  }
  return out;
}
function createNode(shift, key1, val1, key2hash, key2, val2) {
  const key1hash = getHash(key1);
  if (key1hash === key2hash) {
    return {
      type: COLLISION_NODE,
      hash: key1hash,
      array: [
        { type: ENTRY, k: key1, v: val1 },
        { type: ENTRY, k: key2, v: val2 }
      ]
    };
  }
  const addedLeaf = { val: false };
  return assoc(
    assocIndex(EMPTY, shift, key1hash, key1, val1, addedLeaf),
    shift,
    key2hash,
    key2,
    val2,
    addedLeaf
  );
}
function assoc(root2, shift, hash, key, val, addedLeaf) {
  switch (root2.type) {
    case ARRAY_NODE:
      return assocArray(root2, shift, hash, key, val, addedLeaf);
    case INDEX_NODE:
      return assocIndex(root2, shift, hash, key, val, addedLeaf);
    case COLLISION_NODE:
      return assocCollision(root2, shift, hash, key, val, addedLeaf);
  }
}
function assocArray(root2, shift, hash, key, val, addedLeaf) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === void 0) {
    addedLeaf.val = true;
    return {
      type: ARRAY_NODE,
      size: root2.size + 1,
      array: cloneAndSet(root2.array, idx, { type: ENTRY, k: key, v: val })
    };
  }
  if (node.type === ENTRY) {
    if (isEqual(key, node.k)) {
      if (val === node.v) {
        return root2;
      }
      return {
        type: ARRAY_NODE,
        size: root2.size,
        array: cloneAndSet(root2.array, idx, {
          type: ENTRY,
          k: key,
          v: val
        })
      };
    }
    addedLeaf.val = true;
    return {
      type: ARRAY_NODE,
      size: root2.size,
      array: cloneAndSet(
        root2.array,
        idx,
        createNode(shift + SHIFT, node.k, node.v, hash, key, val)
      )
    };
  }
  const n = assoc(node, shift + SHIFT, hash, key, val, addedLeaf);
  if (n === node) {
    return root2;
  }
  return {
    type: ARRAY_NODE,
    size: root2.size,
    array: cloneAndSet(root2.array, idx, n)
  };
}
function assocIndex(root2, shift, hash, key, val, addedLeaf) {
  const bit = bitpos(hash, shift);
  const idx = index(root2.bitmap, bit);
  if ((root2.bitmap & bit) !== 0) {
    const node = root2.array[idx];
    if (node.type !== ENTRY) {
      const n = assoc(node, shift + SHIFT, hash, key, val, addedLeaf);
      if (n === node) {
        return root2;
      }
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, n)
      };
    }
    const nodeKey = node.k;
    if (isEqual(key, nodeKey)) {
      if (val === node.v) {
        return root2;
      }
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, {
          type: ENTRY,
          k: key,
          v: val
        })
      };
    }
    addedLeaf.val = true;
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap,
      array: cloneAndSet(
        root2.array,
        idx,
        createNode(shift + SHIFT, nodeKey, node.v, hash, key, val)
      )
    };
  } else {
    const n = root2.array.length;
    if (n >= MAX_INDEX_NODE) {
      const nodes = new Array(32);
      const jdx = mask(hash, shift);
      nodes[jdx] = assocIndex(EMPTY, shift + SHIFT, hash, key, val, addedLeaf);
      let j = 0;
      let bitmap = root2.bitmap;
      for (let i = 0; i < 32; i++) {
        if ((bitmap & 1) !== 0) {
          const node = root2.array[j++];
          nodes[i] = node;
        }
        bitmap = bitmap >>> 1;
      }
      return {
        type: ARRAY_NODE,
        size: n + 1,
        array: nodes
      };
    } else {
      const newArray = spliceIn(root2.array, idx, {
        type: ENTRY,
        k: key,
        v: val
      });
      addedLeaf.val = true;
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap | bit,
        array: newArray
      };
    }
  }
}
function assocCollision(root2, shift, hash, key, val, addedLeaf) {
  if (hash === root2.hash) {
    const idx = collisionIndexOf(root2, key);
    if (idx !== -1) {
      const entry = root2.array[idx];
      if (entry.v === val) {
        return root2;
      }
      return {
        type: COLLISION_NODE,
        hash,
        array: cloneAndSet(root2.array, idx, { type: ENTRY, k: key, v: val })
      };
    }
    const size = root2.array.length;
    addedLeaf.val = true;
    return {
      type: COLLISION_NODE,
      hash,
      array: cloneAndSet(root2.array, size, { type: ENTRY, k: key, v: val })
    };
  }
  return assoc(
    {
      type: INDEX_NODE,
      bitmap: bitpos(root2.hash, shift),
      array: [root2]
    },
    shift,
    hash,
    key,
    val,
    addedLeaf
  );
}
function collisionIndexOf(root2, key) {
  const size = root2.array.length;
  for (let i = 0; i < size; i++) {
    if (isEqual(key, root2.array[i].k)) {
      return i;
    }
  }
  return -1;
}
function find(root2, shift, hash, key) {
  switch (root2.type) {
    case ARRAY_NODE:
      return findArray(root2, shift, hash, key);
    case INDEX_NODE:
      return findIndex(root2, shift, hash, key);
    case COLLISION_NODE:
      return findCollision(root2, key);
  }
}
function findArray(root2, shift, hash, key) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === void 0) {
    return void 0;
  }
  if (node.type !== ENTRY) {
    return find(node, shift + SHIFT, hash, key);
  }
  if (isEqual(key, node.k)) {
    return node;
  }
  return void 0;
}
function findIndex(root2, shift, hash, key) {
  const bit = bitpos(hash, shift);
  if ((root2.bitmap & bit) === 0) {
    return void 0;
  }
  const idx = index(root2.bitmap, bit);
  const node = root2.array[idx];
  if (node.type !== ENTRY) {
    return find(node, shift + SHIFT, hash, key);
  }
  if (isEqual(key, node.k)) {
    return node;
  }
  return void 0;
}
function findCollision(root2, key) {
  const idx = collisionIndexOf(root2, key);
  if (idx < 0) {
    return void 0;
  }
  return root2.array[idx];
}
function without(root2, shift, hash, key) {
  switch (root2.type) {
    case ARRAY_NODE:
      return withoutArray(root2, shift, hash, key);
    case INDEX_NODE:
      return withoutIndex(root2, shift, hash, key);
    case COLLISION_NODE:
      return withoutCollision(root2, key);
  }
}
function withoutArray(root2, shift, hash, key) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === void 0) {
    return root2;
  }
  let n = void 0;
  if (node.type === ENTRY) {
    if (!isEqual(node.k, key)) {
      return root2;
    }
  } else {
    n = without(node, shift + SHIFT, hash, key);
    if (n === node) {
      return root2;
    }
  }
  if (n === void 0) {
    if (root2.size <= MIN_ARRAY_NODE) {
      const arr = root2.array;
      const out = new Array(root2.size - 1);
      let i = 0;
      let j = 0;
      let bitmap = 0;
      while (i < idx) {
        const nv = arr[i];
        if (nv !== void 0) {
          out[j] = nv;
          bitmap |= 1 << i;
          ++j;
        }
        ++i;
      }
      ++i;
      while (i < arr.length) {
        const nv = arr[i];
        if (nv !== void 0) {
          out[j] = nv;
          bitmap |= 1 << i;
          ++j;
        }
        ++i;
      }
      return {
        type: INDEX_NODE,
        bitmap,
        array: out
      };
    }
    return {
      type: ARRAY_NODE,
      size: root2.size - 1,
      array: cloneAndSet(root2.array, idx, n)
    };
  }
  return {
    type: ARRAY_NODE,
    size: root2.size,
    array: cloneAndSet(root2.array, idx, n)
  };
}
function withoutIndex(root2, shift, hash, key) {
  const bit = bitpos(hash, shift);
  if ((root2.bitmap & bit) === 0) {
    return root2;
  }
  const idx = index(root2.bitmap, bit);
  const node = root2.array[idx];
  if (node.type !== ENTRY) {
    const n = without(node, shift + SHIFT, hash, key);
    if (n === node) {
      return root2;
    }
    if (n !== void 0) {
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, n)
      };
    }
    if (root2.bitmap === bit) {
      return void 0;
    }
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap ^ bit,
      array: spliceOut(root2.array, idx)
    };
  }
  if (isEqual(key, node.k)) {
    if (root2.bitmap === bit) {
      return void 0;
    }
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap ^ bit,
      array: spliceOut(root2.array, idx)
    };
  }
  return root2;
}
function withoutCollision(root2, key) {
  const idx = collisionIndexOf(root2, key);
  if (idx < 0) {
    return root2;
  }
  if (root2.array.length === 1) {
    return void 0;
  }
  return {
    type: COLLISION_NODE,
    hash: root2.hash,
    array: spliceOut(root2.array, idx)
  };
}
function forEach(root2, fn) {
  if (root2 === void 0) {
    return;
  }
  const items = root2.array;
  const size = items.length;
  for (let i = 0; i < size; i++) {
    const item = items[i];
    if (item === void 0) {
      continue;
    }
    if (item.type === ENTRY) {
      fn(item.v, item.k);
      continue;
    }
    forEach(item, fn);
  }
}
var Dict = class _Dict {
  /**
   * @template V
   * @param {Record<string,V>} o
   * @returns {Dict<string,V>}
   */
  static fromObject(o) {
    const keys2 = Object.keys(o);
    let m = _Dict.new();
    for (let i = 0; i < keys2.length; i++) {
      const k = keys2[i];
      m = m.set(k, o[k]);
    }
    return m;
  }
  /**
   * @template K,V
   * @param {Map<K,V>} o
   * @returns {Dict<K,V>}
   */
  static fromMap(o) {
    let m = _Dict.new();
    o.forEach((v, k) => {
      m = m.set(k, v);
    });
    return m;
  }
  static new() {
    return new _Dict(void 0, 0);
  }
  /**
   * @param {undefined | Node<K,V>} root
   * @param {number} size
   */
  constructor(root2, size) {
    this.root = root2;
    this.size = size;
  }
  /**
   * @template NotFound
   * @param {K} key
   * @param {NotFound} notFound
   * @returns {NotFound | V}
   */
  get(key, notFound) {
    if (this.root === void 0) {
      return notFound;
    }
    const found = find(this.root, 0, getHash(key), key);
    if (found === void 0) {
      return notFound;
    }
    return found.v;
  }
  /**
   * @param {K} key
   * @param {V} val
   * @returns {Dict<K,V>}
   */
  set(key, val) {
    const addedLeaf = { val: false };
    const root2 = this.root === void 0 ? EMPTY : this.root;
    const newRoot = assoc(root2, 0, getHash(key), key, val, addedLeaf);
    if (newRoot === this.root) {
      return this;
    }
    return new _Dict(newRoot, addedLeaf.val ? this.size + 1 : this.size);
  }
  /**
   * @param {K} key
   * @returns {Dict<K,V>}
   */
  delete(key) {
    if (this.root === void 0) {
      return this;
    }
    const newRoot = without(this.root, 0, getHash(key), key);
    if (newRoot === this.root) {
      return this;
    }
    if (newRoot === void 0) {
      return _Dict.new();
    }
    return new _Dict(newRoot, this.size - 1);
  }
  /**
   * @param {K} key
   * @returns {boolean}
   */
  has(key) {
    if (this.root === void 0) {
      return false;
    }
    return find(this.root, 0, getHash(key), key) !== void 0;
  }
  /**
   * @returns {[K,V][]}
   */
  entries() {
    if (this.root === void 0) {
      return [];
    }
    const result = [];
    this.forEach((v, k) => result.push([k, v]));
    return result;
  }
  /**
   *
   * @param {(val:V,key:K)=>void} fn
   */
  forEach(fn) {
    forEach(this.root, fn);
  }
  hashCode() {
    let h = 0;
    this.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
    return h;
  }
  /**
   * @param {unknown} o
   * @returns {boolean}
   */
  equals(o) {
    if (!(o instanceof _Dict) || this.size !== o.size) {
      return false;
    }
    let equal = true;
    this.forEach((v, k) => {
      equal = equal && isEqual(o.get(k, !v), v);
    });
    return equal;
  }
};

// build/dev/javascript/gleam_stdlib/gleam_stdlib.mjs
var Nil = void 0;
var NOT_FOUND = {};
function identity(x) {
  return x;
}
function to_string(term) {
  return term.toString();
}
function float_to_string(float2) {
  const string2 = float2.toString();
  if (string2.indexOf(".") >= 0) {
    return string2;
  } else {
    return string2 + ".0";
  }
}
function graphemes(string2) {
  const iterator = graphemes_iterator(string2);
  if (iterator) {
    return List.fromArray(Array.from(iterator).map((item) => item.segment));
  } else {
    return List.fromArray(string2.match(/./gsu));
  }
}
function graphemes_iterator(string2) {
  if (Intl && Intl.Segmenter) {
    return new Intl.Segmenter().segment(string2)[Symbol.iterator]();
  }
}
function split(xs, pattern2) {
  return List.fromArray(xs.split(pattern2));
}
function floor2(float2) {
  return Math.floor(float2);
}
function round2(float2) {
  return Math.round(float2);
}
function random_uniform() {
  const random_uniform_result = Math.random();
  if (random_uniform_result === 1) {
    return random_uniform();
  }
  return random_uniform_result;
}
function new_map() {
  return Dict.new();
}
function map_to_list(map5) {
  return List.fromArray(map5.entries());
}
function map_get(map5, key) {
  const value = map5.get(key, NOT_FOUND);
  if (value === NOT_FOUND) {
    return new Error(Nil);
  }
  return new Ok(value);
}
function map_insert(key, value, map5) {
  return map5.set(key, value);
}

// build/dev/javascript/gleam_stdlib/gleam/float.mjs
function to_string4(x) {
  return float_to_string(x);
}
function compare2(a, b) {
  let $ = a === b;
  if ($) {
    return new Eq();
  } else {
    let $1 = a < b;
    if ($1) {
      return new Lt();
    } else {
      return new Gt();
    }
  }
}
function floor(x) {
  return floor2(x);
}
function negate(x) {
  return -1 * x;
}
function do_round(x) {
  let $ = x >= 0;
  if ($) {
    return round2(x);
  } else {
    return 0 - round2(negate(x));
  }
}
function round(x) {
  return do_round(x);
}

// build/dev/javascript/gleam_stdlib/gleam/string.mjs
function split3(x, substring) {
  if (substring === "") {
    return graphemes(x);
  } else {
    let _pipe = x;
    let _pipe$1 = from_string(_pipe);
    let _pipe$2 = split2(_pipe$1, substring);
    return map(_pipe$2, to_string3);
  }
}

// build/dev/javascript/gleam_stdlib/gleam/bool.mjs
function guard(requirement, consequence, alternative) {
  if (requirement) {
    return consequence;
  } else {
    return alternative();
  }
}

// build/dev/javascript/lustre/lustre/effect.mjs
var Effect = class extends CustomType {
  constructor(all) {
    super();
    this.all = all;
  }
};
function from2(effect) {
  return new Effect(toList([(dispatch2, _) => {
    return effect(dispatch2);
  }]));
}
function none() {
  return new Effect(toList([]));
}
function batch(effects) {
  return new Effect(
    fold2(
      effects,
      toList([]),
      (b, _use1) => {
        let a = _use1.all;
        return append(b, a);
      }
    )
  );
}

// build/dev/javascript/lustre/lustre/internals/vdom.mjs
var Text = class extends CustomType {
  constructor(content) {
    super();
    this.content = content;
  }
};
var Element = class extends CustomType {
  constructor(key, namespace2, tag, attrs, children, self_closing, void$) {
    super();
    this.key = key;
    this.namespace = namespace2;
    this.tag = tag;
    this.attrs = attrs;
    this.children = children;
    this.self_closing = self_closing;
    this.void = void$;
  }
};
var Attribute = class extends CustomType {
  constructor(x0, x1, as_property) {
    super();
    this[0] = x0;
    this[1] = x1;
    this.as_property = as_property;
  }
};

// build/dev/javascript/lustre/lustre/attribute.mjs
function attribute(name, value) {
  return new Attribute(name, from(value), false);
}
function class$(name) {
  return attribute("class", name);
}

// build/dev/javascript/lustre/lustre/element.mjs
function element(tag, attrs, children) {
  if (tag === "area") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "base") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "br") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "col") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "embed") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "hr") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "img") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "input") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "link") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "meta") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "param") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "source") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "track") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "wbr") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else {
    return new Element("", "", tag, attrs, children, false, false);
  }
}
function namespaced(namespace2, tag, attrs, children) {
  return new Element("", namespace2, tag, attrs, children, false, false);
}
function text(content) {
  return new Text(content);
}

// build/dev/javascript/gleam_stdlib/gleam/set.mjs
var Set2 = class extends CustomType {
  constructor(dict) {
    super();
    this.dict = dict;
  }
};
function contains2(set, member) {
  let _pipe = set.dict;
  let _pipe$1 = get(_pipe, member);
  return is_ok(_pipe$1);
}
var token = void 0;
function from_list2(members) {
  let dict = fold2(
    members,
    new$(),
    (m, k) => {
      return insert(m, k, token);
    }
  );
  return new Set2(dict);
}

// build/dev/javascript/lustre/lustre/internals/runtime.mjs
var Debug = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var Dispatch = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var Shutdown = class extends CustomType {
};
var ForceModel = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};

// build/dev/javascript/lustre/vdom.ffi.mjs
function morph(prev, next, dispatch2, isComponent = false) {
  let out;
  let stack = [{ prev, next, parent: prev.parentNode }];
  while (stack.length) {
    let { prev: prev2, next: next2, parent } = stack.pop();
    if (next2.subtree !== void 0)
      next2 = next2.subtree();
    if (next2.content !== void 0) {
      if (!prev2) {
        const created = document.createTextNode(next2.content);
        parent.appendChild(created);
        out ??= created;
      } else if (prev2.nodeType === Node.TEXT_NODE) {
        if (prev2.textContent !== next2.content)
          prev2.textContent = next2.content;
        out ??= prev2;
      } else {
        const created = document.createTextNode(next2.content);
        parent.replaceChild(created, prev2);
        out ??= created;
      }
    } else if (next2.tag !== void 0) {
      const created = createElementNode({
        prev: prev2,
        next: next2,
        dispatch: dispatch2,
        stack,
        isComponent
      });
      if (!prev2) {
        parent.appendChild(created);
      } else if (prev2 !== created) {
        parent.replaceChild(created, prev2);
      }
      out ??= created;
    } else if (next2.elements !== void 0) {
      iterateElement(next2, (fragmentElement) => {
        stack.unshift({ prev: prev2, next: fragmentElement, parent });
        prev2 = prev2?.nextSibling;
      });
    } else if (next2.subtree !== void 0) {
      stack.push({ prev: prev2, next: next2, parent });
    }
  }
  return out;
}
function createElementNode({ prev, next, dispatch: dispatch2, stack }) {
  const namespace2 = next.namespace || "http://www.w3.org/1999/xhtml";
  const canMorph = prev && prev.nodeType === Node.ELEMENT_NODE && prev.localName === next.tag && prev.namespaceURI === (next.namespace || "http://www.w3.org/1999/xhtml");
  const el2 = canMorph ? prev : namespace2 ? document.createElementNS(namespace2, next.tag) : document.createElement(next.tag);
  let handlersForEl;
  if (!registeredHandlers.has(el2)) {
    const emptyHandlers = /* @__PURE__ */ new Map();
    registeredHandlers.set(el2, emptyHandlers);
    handlersForEl = emptyHandlers;
  } else {
    handlersForEl = registeredHandlers.get(el2);
  }
  const prevHandlers = canMorph ? new Set(handlersForEl.keys()) : null;
  const prevAttributes = canMorph ? new Set(Array.from(prev.attributes, (a) => a.name)) : null;
  let className = null;
  let style = null;
  let innerHTML = null;
  for (const attr2 of next.attrs) {
    const name = attr2[0];
    const value = attr2[1];
    if (attr2.as_property) {
      if (el2[name] !== value)
        el2[name] = value;
      if (canMorph)
        prevAttributes.delete(name);
    } else if (name.startsWith("on")) {
      const eventName = name.slice(2);
      const callback = dispatch2(value);
      if (!handlersForEl.has(eventName)) {
        el2.addEventListener(eventName, lustreGenericEventHandler);
      }
      handlersForEl.set(eventName, callback);
      if (canMorph)
        prevHandlers.delete(eventName);
    } else if (name.startsWith("data-lustre-on-")) {
      const eventName = name.slice(15);
      const callback = dispatch2(lustreServerEventHandler);
      if (!handlersForEl.has(eventName)) {
        el2.addEventListener(eventName, lustreGenericEventHandler);
      }
      handlersForEl.set(eventName, callback);
      el2.setAttribute(name, value);
    } else if (name === "class") {
      className = className === null ? value : className + " " + value;
    } else if (name === "style") {
      style = style === null ? value : style + value;
    } else if (name === "dangerous-unescaped-html") {
      innerHTML = value;
    } else {
      if (typeof value === "string")
        el2.setAttribute(name, value);
      if (name === "value" || name === "selected")
        el2[name] = value;
      if (canMorph)
        prevAttributes.delete(name);
    }
  }
  if (className !== null) {
    el2.setAttribute("class", className);
    if (canMorph)
      prevAttributes.delete("class");
  }
  if (style !== null) {
    el2.setAttribute("style", style);
    if (canMorph)
      prevAttributes.delete("style");
  }
  if (canMorph) {
    for (const attr2 of prevAttributes) {
      el2.removeAttribute(attr2);
    }
    for (const eventName of prevHandlers) {
      handlersForEl.delete(eventName);
      el2.removeEventListener(eventName, lustreGenericEventHandler);
    }
  }
  if (next.key !== void 0 && next.key !== "") {
    el2.setAttribute("data-lustre-key", next.key);
  } else if (innerHTML !== null) {
    el2.innerHTML = innerHTML;
    return el2;
  }
  let prevChild = el2.firstChild;
  let seenKeys = null;
  let keyedChildren = null;
  let incomingKeyedChildren = null;
  let firstChild = next.children[Symbol.iterator]().next().value;
  if (canMorph && firstChild !== void 0 && // Explicit checks are more verbose but truthy checks force a bunch of comparisons
  // we don't care about: it's never gonna be a number etc.
  firstChild.key !== void 0 && firstChild.key !== "") {
    seenKeys = /* @__PURE__ */ new Set();
    keyedChildren = getKeyedChildren(prev);
    incomingKeyedChildren = getKeyedChildren(next);
  }
  for (const child of next.children) {
    iterateElement(child, (currElement) => {
      if (currElement.key !== void 0 && seenKeys !== null) {
        prevChild = diffKeyedChild(
          prevChild,
          currElement,
          el2,
          stack,
          incomingKeyedChildren,
          keyedChildren,
          seenKeys
        );
      } else {
        stack.unshift({ prev: prevChild, next: currElement, parent: el2 });
        prevChild = prevChild?.nextSibling;
      }
    });
  }
  while (prevChild) {
    const next2 = prevChild.nextSibling;
    el2.removeChild(prevChild);
    prevChild = next2;
  }
  return el2;
}
var registeredHandlers = /* @__PURE__ */ new WeakMap();
function lustreGenericEventHandler(event) {
  const target = event.currentTarget;
  if (!registeredHandlers.has(target)) {
    target.removeEventListener(event.type, lustreGenericEventHandler);
    return;
  }
  const handlersForEventTarget = registeredHandlers.get(target);
  if (!handlersForEventTarget.has(event.type)) {
    target.removeEventListener(event.type, lustreGenericEventHandler);
    return;
  }
  handlersForEventTarget.get(event.type)(event);
}
function lustreServerEventHandler(event) {
  const el2 = event.target;
  const tag = el2.getAttribute(`data-lustre-on-${event.type}`);
  const data = JSON.parse(el2.getAttribute("data-lustre-data") || "{}");
  const include = JSON.parse(el2.getAttribute("data-lustre-include") || "[]");
  switch (event.type) {
    case "input":
    case "change":
      include.push("target.value");
      break;
  }
  return {
    tag,
    data: include.reduce(
      (data2, property) => {
        const path2 = property.split(".");
        for (let i = 0, o = data2, e = event; i < path2.length; i++) {
          if (i === path2.length - 1) {
            o[path2[i]] = e[path2[i]];
          } else {
            o[path2[i]] ??= {};
            e = e[path2[i]];
            o = o[path2[i]];
          }
        }
        return data2;
      },
      { data }
    )
  };
}
function getKeyedChildren(el2) {
  const keyedChildren = /* @__PURE__ */ new Map();
  if (el2) {
    for (const child of el2.children) {
      iterateElement(child, (currElement) => {
        const key = currElement?.key || currElement?.getAttribute?.("data-lustre-key");
        if (key)
          keyedChildren.set(key, currElement);
      });
    }
  }
  return keyedChildren;
}
function diffKeyedChild(prevChild, child, el2, stack, incomingKeyedChildren, keyedChildren, seenKeys) {
  while (prevChild && !incomingKeyedChildren.has(prevChild.getAttribute("data-lustre-key"))) {
    const nextChild = prevChild.nextSibling;
    el2.removeChild(prevChild);
    prevChild = nextChild;
  }
  if (keyedChildren.size === 0) {
    iterateElement(child, (currChild) => {
      stack.unshift({ prev: prevChild, next: currChild, parent: el2 });
      prevChild = prevChild?.nextSibling;
    });
    return prevChild;
  }
  if (seenKeys.has(child.key)) {
    console.warn(`Duplicate key found in Lustre vnode: ${child.key}`);
    stack.unshift({ prev: null, next: child, parent: el2 });
    return prevChild;
  }
  seenKeys.add(child.key);
  const keyedChild = keyedChildren.get(child.key);
  if (!keyedChild && !prevChild) {
    stack.unshift({ prev: null, next: child, parent: el2 });
    return prevChild;
  }
  if (!keyedChild && prevChild !== null) {
    const placeholder = document.createTextNode("");
    el2.insertBefore(placeholder, prevChild);
    stack.unshift({ prev: placeholder, next: child, parent: el2 });
    return prevChild;
  }
  if (!keyedChild || keyedChild === prevChild) {
    stack.unshift({ prev: prevChild, next: child, parent: el2 });
    prevChild = prevChild?.nextSibling;
    return prevChild;
  }
  el2.insertBefore(keyedChild, prevChild);
  stack.unshift({ prev: keyedChild, next: child, parent: el2 });
  return prevChild;
}
function iterateElement(element2, processElement) {
  if (element2.elements !== void 0) {
    for (const currElement of element2.elements) {
      processElement(currElement);
    }
  } else {
    processElement(element2);
  }
}

// build/dev/javascript/lustre/client-runtime.ffi.mjs
var LustreClientApplication2 = class _LustreClientApplication {
  #root = null;
  #queue = [];
  #effects = [];
  #didUpdate = false;
  #isComponent = false;
  #model = null;
  #update = null;
  #view = null;
  static start(flags, selector, init5, update5, view2) {
    if (!is_browser())
      return new Error(new NotABrowser());
    const root2 = selector instanceof HTMLElement ? selector : document.querySelector(selector);
    if (!root2)
      return new Error(new ElementNotFound(selector));
    const app = new _LustreClientApplication(init5(flags), update5, view2, root2);
    return new Ok((msg) => app.send(msg));
  }
  constructor([model, effects], update5, view2, root2 = document.body, isComponent = false) {
    this.#model = model;
    this.#update = update5;
    this.#view = view2;
    this.#root = root2;
    this.#effects = effects.all.toArray();
    this.#didUpdate = true;
    this.#isComponent = isComponent;
    window.requestAnimationFrame(() => this.#tick());
  }
  send(action) {
    switch (true) {
      case action instanceof Dispatch: {
        this.#queue.push(action[0]);
        this.#tick();
        return;
      }
      case action instanceof Shutdown: {
        this.#shutdown();
        return;
      }
      case action instanceof Debug: {
        this.#debug(action[0]);
        return;
      }
      default:
        return;
    }
  }
  emit(event, data) {
    this.#root.dispatchEvent(
      new CustomEvent(event, {
        bubbles: true,
        detail: data,
        composed: true
      })
    );
  }
  #tick() {
    this.#flush_queue();
    const vdom = this.#view(this.#model);
    const dispatch2 = (handler) => (e) => {
      const result = handler(e);
      if (result instanceof Ok) {
        this.send(new Dispatch(result[0]));
      }
    };
    this.#didUpdate = false;
    this.#root = morph(this.#root, vdom, dispatch2, this.#isComponent);
  }
  #flush_queue(iterations = 0) {
    while (this.#queue.length) {
      const [next, effects] = this.#update(this.#model, this.#queue.shift());
      this.#didUpdate ||= !isEqual(this.#model, next);
      this.#model = next;
      this.#effects = this.#effects.concat(effects.all.toArray());
    }
    while (this.#effects.length) {
      this.#effects.shift()(
        (msg) => this.send(new Dispatch(msg)),
        (event, data) => this.emit(event, data)
      );
    }
    if (this.#queue.length) {
      if (iterations < 5) {
        this.#flush_queue(++iterations);
      } else {
        window.requestAnimationFrame(() => this.#tick());
      }
    }
  }
  #debug(action) {
    switch (true) {
      case action instanceof ForceModel: {
        const vdom = this.#view(action[0]);
        const dispatch2 = (handler) => (e) => {
          const result = handler(e);
          if (result instanceof Ok) {
            this.send(new Dispatch(result[0]));
          }
        };
        this.#queue = [];
        this.#effects = [];
        this.#didUpdate = false;
        this.#root = morph(this.#root, vdom, dispatch2, this.#isComponent);
      }
    }
  }
  #shutdown() {
    this.#root.remove();
    this.#root = null;
    this.#model = null;
    this.#queue = [];
    this.#effects = [];
    this.#didUpdate = false;
    this.#update = () => {
    };
    this.#view = () => {
    };
  }
};
var start = (app, selector, flags) => LustreClientApplication2.start(
  flags,
  selector,
  app.init,
  app.update,
  app.view
);
var is_browser = () => window && window.document;

// build/dev/javascript/lustre/lustre.mjs
var App = class extends CustomType {
  constructor(init5, update5, view2, on_attribute_change) {
    super();
    this.init = init5;
    this.update = update5;
    this.view = view2;
    this.on_attribute_change = on_attribute_change;
  }
};
var ElementNotFound = class extends CustomType {
  constructor(selector) {
    super();
    this.selector = selector;
  }
};
var NotABrowser = class extends CustomType {
};
function application(init5, update5, view2) {
  return new App(init5, update5, view2, new None());
}
function dispatch(msg) {
  return new Dispatch(msg);
}
function start3(app, selector, flags) {
  return guard(
    !is_browser(),
    new Error(new NotABrowser()),
    () => {
      return start(app, selector, flags);
    }
  );
}

// build/dev/javascript/lustre/lustre/element/html.mjs
function h3(attrs, children) {
  return element("h3", attrs, children);
}
function div(attrs, children) {
  return element("div", attrs, children);
}
function p(attrs, children) {
  return element("p", attrs, children);
}

// build/dev/javascript/lustre/lustre/element/svg.mjs
var namespace = "http://www.w3.org/2000/svg";
function circle(attrs) {
  return namespaced(namespace, "circle", attrs, toList([]));
}
function line(attrs) {
  return namespaced(namespace, "line", attrs, toList([]));
}
function polyline(attrs) {
  return namespaced(namespace, "polyline", attrs, toList([]));
}
function rect(attrs) {
  return namespaced(namespace, "rect", attrs, toList([]));
}
function defs(attrs, children) {
  return namespaced(namespace, "defs", attrs, children);
}
function g(attrs, children) {
  return namespaced(namespace, "g", attrs, children);
}
function pattern(attrs, children) {
  return namespaced(namespace, "pattern", attrs, children);
}
function svg(attrs, children) {
  return namespaced(namespace, "svg", attrs, children);
}
function path(attrs) {
  return namespaced(namespace, "path", attrs, toList([]));
}
function text2(attrs, content) {
  return namespaced(namespace, "text", attrs, toList([text(content)]));
}

// build/dev/javascript/snek/position.mjs
var Pos = class extends CustomType {
  constructor(x, y) {
    super();
    this.x = x;
    this.y = y;
  }
};
var Left = class extends CustomType {
};
var Right = class extends CustomType {
};
var Down = class extends CustomType {
};
var Up = class extends CustomType {
};
var Bbox = class extends CustomType {
  constructor(x, y, w, h, dir) {
    super();
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.dir = dir;
  }
};
function add2(p1, p2) {
  return new Pos(p1.x + p2.x, p1.y + p2.y);
}
function move(p2, dir) {
  if (dir instanceof Left) {
    return new Pos(p2.x - 1, p2.y);
  } else if (dir instanceof Right) {
    return new Pos(p2.x + 1, p2.y);
  } else if (dir instanceof Down) {
    return new Pos(p2.x, p2.y + 1);
  } else {
    return new Pos(p2.x, p2.y - 1);
  }
}
function to_bbox(pos, w, h, size) {
  let dir = (() => {
    if (pos instanceof Pos && pos.x < 0) {
      let x2 = pos.x;
      return new Some(new Left());
    } else if (pos instanceof Pos && pos.x >= w) {
      let x2 = pos.x;
      return new Some(new Right());
    } else if (pos instanceof Pos && pos.y < 0) {
      let y2 = pos.y;
      return new Some(new Up());
    } else if (pos instanceof Pos && pos.y >= h) {
      let y2 = pos.y;
      return new Some(new Down());
    } else {
      return new None();
    }
  })();
  let x = pos.x * size;
  let y = pos.y * size;
  let w$1 = size;
  let h$1 = size;
  let half = divideInt(size, 2);
  if (dir instanceof Some) {
    let dir$1 = dir[0];
    if (dir$1 instanceof Left) {
      return new Bbox(x + half, y, half, h$1, new Some(new Left()));
    } else if (dir$1 instanceof Right) {
      return new Bbox(x, y, half, h$1, new Some(new Right()));
    } else if (dir$1 instanceof Up) {
      return new Bbox(x, y + half, w$1, half, new Some(new Up()));
    } else {
      return new Bbox(x, y, w$1, half, new Some(new Down()));
    }
  } else {
    return new Bbox(x, y, w$1, h$1, new None());
  }
}

// build/dev/javascript/snek/level.mjs
var Wall = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var SnekInit = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var Dir = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var ExitItem = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var SpawnItem = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var Empty2 = class extends CustomType {
};
var WallSpawn = class extends CustomType {
  constructor(pos, order) {
    super();
    this.pos = pos;
    this.order = order;
  }
};
var Parsed = class extends CustomType {
  constructor(number, walls2, snek_init, snek_dir, exit_pos, spawns) {
    super();
    this.number = number;
    this.walls = walls2;
    this.snek_init = snek_init;
    this.snek_dir = snek_dir;
    this.exit_pos = exit_pos;
    this.spawns = spawns;
  }
};
function collect_items(acc, item) {
  if (item instanceof Wall) {
    let pos = item[0];
    return [prepend(pos, acc[0]), acc[1], acc[2], acc[3], acc[4]];
  } else if (item instanceof SnekInit) {
    let pos = item[0];
    return [acc[0], new Some(pos), acc[2], acc[3], acc[4]];
  } else if (item instanceof Dir) {
    let move3 = item[0];
    return [acc[0], acc[1], new Some(move3), acc[3], acc[4]];
  } else if (item instanceof ExitItem) {
    let pos = item[0];
    return [acc[0], acc[1], acc[2], new Some(pos), acc[4]];
  } else if (item instanceof SpawnItem) {
    let wall_spawn = item[0];
    return [acc[0], acc[1], acc[2], acc[3], prepend(wall_spawn, acc[4])];
  } else {
    return acc;
  }
}
function clamp2(n) {
  return clamp(n, 1, 5);
}
var width = 20;
function read_row(row) {
  let line3 = row[0];
  let y = row[1];
  let _pipe = line3;
  let _pipe$1 = split3(_pipe, "");
  let _pipe$2 = map2(
    _pipe$1,
    range(0, width),
    (char, x) => {
      if (char === "W") {
        return new Wall(new Pos(x, y));
      } else if (char === "S") {
        return new SnekInit(new Pos(x, y));
      } else if (char === "^") {
        return new Dir(new Up());
      } else if (char === ">") {
        return new Dir(new Right());
      } else if (char === "<") {
        return new Dir(new Left());
      } else if (char === "v") {
        return new Dir(new Down());
      } else if (char === "V") {
        return new Dir(new Down());
      } else if (char === "E") {
        return new ExitItem(new Pos(x, y));
      } else if (char === "e") {
        return new ExitItem(new Pos(x, y));
      } else if (char === "1") {
        return new SpawnItem(new WallSpawn(new Pos(x, y), 1));
      } else if (char === "2") {
        return new SpawnItem(new WallSpawn(new Pos(x, y), 2));
      } else if (char === "3") {
        return new SpawnItem(new WallSpawn(new Pos(x, y), 3));
      } else if (char === "4") {
        return new SpawnItem(new WallSpawn(new Pos(x, y), 4));
      } else {
        return new Empty2();
      }
    }
  );
  return filter(_pipe$2, (x) => {
    return !isEqual(x, new Empty2());
  });
}
var height = 15;
function read(n, lvl) {
  let acc = (() => {
    let _pipe = lvl;
    let _pipe$1 = split3(_pipe, "\n");
    let _pipe$2 = filter(_pipe$1, (x) => {
      return x !== "";
    });
    let _pipe$3 = map2(
      _pipe$2,
      range(0, height),
      (line3, y) => {
        return [line3, y];
      }
    );
    let _pipe$4 = map(_pipe$3, (row) => {
      return read_row(row);
    });
    let _pipe$5 = flatten(_pipe$4);
    return fold2(
      _pipe$5,
      [
        toList([]),
        new Some(new Pos(0, 0)),
        new Some(new Right()),
        new Some(new Pos(0, 0)),
        toList([])
      ],
      collect_items
    );
  })();
  if (acc[1] instanceof Some && acc[2] instanceof Some && acc[3] instanceof Some) {
    let walls2 = acc[0];
    let init_pos = acc[1][0];
    let dir = acc[2][0];
    let exit = acc[3][0];
    let wall_spawn = acc[4];
    let spawn_positions = (() => {
      let _pipe = wall_spawn;
      let _pipe$1 = sort(
        _pipe,
        (ws1, ws2) => {
          return compare(ws1.order, ws2.order);
        }
      );
      return map(_pipe$1, (ws) => {
        return ws.pos;
      });
    })();
    return new Parsed(n, walls2, init_pos, dir, exit, spawn_positions);
  } else {
    throw makeError("panic", "level", 189, "read", "Bad level data", {});
  }
}
var lvl_1 = "\n.........E..........\n....................\n....................\n....................\n....................\n....................\n...................4\n.....S>.............\n....................\n....................\n....................\n2...................\n....................\n....................\n.........3.......1..\n";
var lvl_2 = "\n......2.............\n....................\n...................1\n....S>..............\n....................\n....................\n....................\n...WWWWWWWWWWWWWW...\n....................\n...................4\n....................\nE...................\n....................\n....................\n..................3.\n";
var lvl_3 = "\n4...................\n....................\n.....W........W.....\n.....W........W.....\n.....W........W....E\n.....W........W.....\n.....W........W.....\n.....W........W.....\n2....W........W.....\n.....W........W.....\n.....W....^...W.....\n.....W....S...W.....\n.....W........W.....\n....................\n1........3..........\n";
var lvl_4 = "\n.....2.............1\n..S>................\n....................\n..WWWWWWWWWWWW......\n....................\n3...................\n....................\n......WWWWWWWWWWWW..\n....................\n....................\n....................\n..WWWWWWWWWWWW......\n....................\n...................E\n......4.............\n";
var lvl_5 = "\n...2................\n..S>................\n....................\n3....WWWWWWWWWW.....\n....................\n...W............W...\n...W............W...\n...W............W..E\n...W............W...\n...W............W...\n....................\n.....WWWWWWWWWW.....\n....................\n...................4\n...1................\n";
function get2(loop$n) {
  while (true) {
    let n = loop$n;
    if (n === 1) {
      return read(1, lvl_1);
    } else if (n === 2) {
      return read(2, lvl_2);
    } else if (n === 3) {
      return read(3, lvl_3);
    } else if (n === 4) {
      return read(4, lvl_4);
    } else if (n === 5) {
      return read(5, lvl_5);
    } else {
      loop$n = 1;
    }
  }
}

// build/dev/javascript/snek/player.mjs
var Snek = class extends CustomType {
  constructor(body, input, dir, food3) {
    super();
    this.body = body;
    this.input = input;
    this.dir = dir;
    this.food = food3;
  }
};
var Result2 = class extends CustomType {
  constructor(snek2, died, exit, ate) {
    super();
    this.snek = snek2;
    this.died = died;
    this.exit = exit;
    this.ate = ate;
  }
};
var InputNone = class extends CustomType {
};
var Input = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var InputLate = class extends CustomType {
  constructor(x0, x1) {
    super();
    this[0] = x0;
    this[1] = x1;
  }
};
var MoveArgs = class extends CustomType {
  constructor(snek2, food3, walls2, exit_pos, w, h) {
    super();
    this.snek = snek2;
    this.food = food3;
    this.walls = walls2;
    this.exit_pos = exit_pos;
    this.w = w;
    this.h = h;
  }
};
var SimResult = class extends CustomType {
  constructor(is_dead) {
    super();
    this.is_dead = is_dead;
  }
};
function init2(p2, dir) {
  return new Snek(toList([p2, p2, p2]), new InputNone(), dir, 0);
}
function head(snek2) {
  let $ = snek2.body;
  if ($.atLeastLength(1)) {
    let head$1 = $.head;
    return head$1;
  } else {
    throw makeError("panic", "player", 19, "head", "Snek has no head", {});
  }
}
function get_head_safe(snek2) {
  let $ = snek2.body;
  if ($.atLeastLength(1)) {
    let head$1 = $.head;
    return new Some(head$1);
  } else {
    return new None();
  }
}
function neck(snek2) {
  let $ = snek2.body;
  if ($.atLeastLength(2)) {
    let neck$1 = $.tail.head;
    return neck$1;
  } else {
    throw makeError("panic", "player", 33, "neck", "Snek has no neck", {});
  }
}
function check_out_of_boards(head2, w, h) {
  if (head2 instanceof Pos && head2.x < 0) {
    let x = head2.x;
    return true;
  } else if (head2 instanceof Pos && head2.x >= w) {
    let x = head2.x;
    return true;
  } else if (head2 instanceof Pos && head2.y < 0) {
    let y = head2.y;
    return true;
  } else if (head2 instanceof Pos && head2.y >= h) {
    let y = head2.y;
    return true;
  } else {
    return false;
  }
}
function unsafe_moves_to_input(moves) {
  if (moves.hasLength(2)) {
    let mv1 = moves.head;
    let mv2 = moves.tail.head;
    return new InputLate(mv1, mv2);
  } else if (moves.hasLength(1)) {
    let mv = moves.head;
    return new Input(mv);
  } else {
    throw makeError(
      "panic",
      "player",
      185,
      "unsafe_moves_to_input",
      "Expected list of one or two moves",
      {}
    );
  }
}
function new_head(snek2) {
  let $ = (() => {
    let $1 = snek2.input;
    if ($1 instanceof InputNone) {
      return [snek2.dir, new InputNone()];
    } else if ($1 instanceof Input) {
      let mv = $1[0];
      return [mv, new InputNone()];
    } else {
      let mv1 = $1[0];
      let mv2 = $1[1];
      return [mv1, new Input(mv2)];
    }
  })();
  let dir = $[0];
  let new_input = $[1];
  return [move(head(snek2), dir), new_input, dir];
}
function body_contains(snek2, pos) {
  return contains(snek2.body, pos);
}
function drop_last_recursive(loop$xs, loop$acc) {
  while (true) {
    let xs = loop$xs;
    let acc = loop$acc;
    if (xs.hasLength(2)) {
      let x = xs.head;
      return prepend(x, acc);
    } else if (xs.atLeastLength(1)) {
      let x = xs.head;
      let rest = xs.tail;
      loop$xs = rest;
      loop$acc = prepend(x, acc);
    } else {
      return acc;
    }
  }
}
function drop_last(xs) {
  let _pipe = xs;
  let _pipe$1 = drop_last_recursive(_pipe, toList([]));
  return reverse(_pipe$1);
}
function move_exiting(snek2, exit_wall_pos) {
  let body1 = (() => {
    let $ = snek2.body;
    if ($.hasLength(1)) {
      return toList([]);
    } else {
      return drop_last(snek2.body);
    }
  })();
  let maybe_head = get_head_safe(snek2);
  let body2 = (() => {
    if (maybe_head instanceof Some) {
      let head$1 = maybe_head[0];
      let $ = isEqual(head$1, exit_wall_pos);
      if ($) {
        return body1;
      } else {
        let maybe_valid_new_head_list = (() => {
          let _pipe = toList([
            new Up(),
            new Down(),
            new Left(),
            new Right()
          ]);
          let _pipe$1 = map(
            _pipe,
            (d) => {
              return move(head$1, d);
            }
          );
          return filter(
            _pipe$1,
            (pos) => {
              return isEqual(pos, exit_wall_pos);
            }
          );
        })();
        if (maybe_valid_new_head_list.atLeastLength(1)) {
          let new_head_pos = maybe_valid_new_head_list.head;
          return prepend(new_head_pos, body1);
        } else {
          return body1;
        }
      }
    } else {
      return body1;
    }
  })();
  let new_snek = snek2.withFields({ body: body2 });
  let done = isEqual(body2, toList([]));
  return [new_snek, done];
}
function update2(snek2, new_head2, move3, ate) {
  let food3 = max(0, snek2.food - 1);
  let food$1 = (() => {
    if (ate) {
      return food3 + 2;
    } else {
      return food3;
    }
  })();
  let $ = snek2.food > 0;
  if ($) {
    let body = snek2.body;
    return new Snek(prepend(new_head2, body), snek2.input, move3, food$1);
  } else {
    let body = drop_last(snek2.body);
    return new Snek(prepend(new_head2, body), snek2.input, move3, food$1);
  }
}
function check_self_collide(head2, snek2) {
  let body = (() => {
    let $ = snek2.food > 0;
    if ($) {
      return snek2.body;
    } else {
      return drop_last(snek2.body);
    }
  })();
  return contains(body, head2);
}
function move2(args) {
  let snek2 = args.snek;
  let food3 = args.food;
  let walls2 = args.walls;
  let exit_pos = args.exit_pos;
  let w = args.w;
  let h = args.h;
  let $ = new_head(snek2);
  let head$1 = $[0];
  let new_input = $[1];
  let mv_taken = $[2];
  let ate = contains2(food3, head$1);
  let new_snek = update2(snek2, head$1, mv_taken, ate);
  let game_over = check_out_of_boards(head$1, w, h) || contains(
    walls2,
    head$1
  ) || check_self_collide(head$1, snek2);
  let exit = (() => {
    if (exit_pos instanceof Some) {
      let pos = exit_pos[0];
      return isEqual(pos, head$1);
    } else {
      return false;
    }
  })();
  return new Result2(
    new_snek.withFields({ input: new_input }),
    game_over,
    exit,
    ate
  );
}
function r_simulate_moves(loop$acc, loop$moves, loop$args) {
  while (true) {
    let acc = loop$acc;
    let moves = loop$moves;
    let args = loop$args;
    let $ = acc.is_dead;
    if ($) {
      return acc;
    } else {
      if (moves.hasLength(0)) {
        return acc;
      } else {
        let mv = moves.head;
        let rest = moves.tail;
        let result = move2(
          args.withFields({
            snek: args.snek.withFields({ input: new Input(mv) })
          })
        );
        let $1 = result.died;
        if ($1) {
          return new SimResult(true);
        } else {
          let $2 = result.exit;
          if ($2) {
            return new SimResult(false);
          } else {
            let new_args = args.withFields({ snek: result.snek });
            loop$acc = acc;
            loop$moves = rest;
            loop$args = new_args;
          }
        }
      }
    }
  }
}
function simulate_moves(moves, args) {
  return r_simulate_moves(new SimResult(false), moves, args);
}
function keypress(move3, late2, args) {
  let snek2 = args.snek;
  let $ = (() => {
    if (late2) {
      let two_moves = (() => {
        let $12 = snek2.input;
        if ($12 instanceof InputNone) {
          return toList([move3]);
        } else if ($12 instanceof Input) {
          let mv = $12[0];
          return toList([mv, move3]);
        } else {
          let mv = $12[0];
          return toList([mv, move3]);
        }
      })();
      let two_result = simulate_moves(two_moves, args);
      let one_result = simulate_moves(toList([move3]), args);
      let no_result = simulate_moves(toList([snek2.dir]), args);
      let $1 = (() => {
        let $2 = one_result.is_dead;
        let $3 = two_result.is_dead;
        let $4 = no_result.is_dead;
        if (!$2 && !$3) {
          return [two_moves, true];
        } else if ($2 && !$3) {
          return [two_moves, true];
        } else if (!$2 && $3) {
          return [toList([move3]), true];
        } else if ($2 && $3 && !$4) {
          return [toList([snek2.dir]), false];
        } else {
          return [toList([move3]), false];
        }
      })();
      let moves_to_use = $1[0];
      let skip2 = $1[1];
      return [unsafe_moves_to_input(moves_to_use), skip2];
    } else {
      let accepted = new Input(move3);
      let rejected = snek2.input;
      let neck_collide = isEqual(move(head(snek2), move3), neck(snek2));
      let new_input = (() => {
        if (neck_collide) {
          return rejected;
        } else {
          return accepted;
        }
      })();
      return [new_input, false];
    }
  })();
  let new$4 = $[0];
  let skip = $[1];
  return [snek2.withFields({ input: new$4 }), skip];
}

// build/dev/javascript/snek/sound_ffi.mjs
var ctxMap = /* @__PURE__ */ new Map();
async function loadFile(audioCtx, filePath) {
  const response = await fetch(filePath);
  const arrayBuffer = await response.arrayBuffer();
  const audioBuffer = await audioCtx.decodeAudioData(arrayBuffer);
  return audioBuffer;
}
function play(audioCtx, gainNode, audioBuffer, rate, gain) {
  const source = audioCtx.createBufferSource();
  source.buffer = audioBuffer;
  source.playbackRate.value = rate;
  gainNode.gain.value = gain;
  source.connect(gainNode);
  source.start(0);
}
function playSound(sound) {
  const file = "./priv/static/sounds/" + lookup(sound);
  let obj = ctxMap.get(file);
  let ctx;
  let gainNode;
  if (obj == void 0) {
    ctx = new AudioContext();
    gainNode = ctx.createGain();
    gainNode.connect(ctx.destination);
    obj = { ctx, gainNode };
    ctxMap.set(file, obj);
  }
  ctx = obj.ctx;
  gainNode = obj.gainNode;
  const rate = lookup_rate(sound);
  const gain = lookup_gain(sound);
  loadFile(ctx, file).then((track) => {
    play(ctx, gainNode, track, rate, gain);
  });
}

// build/dev/javascript/snek/sound.mjs
var Pause = class extends CustomType {
};
var Unpause = class extends CustomType {
};
var LevelFinished = class extends CustomType {
};
var Eat = class extends CustomType {
};
var HitWall = class extends CustomType {
};
var Move = class extends CustomType {
};
var DoorOpen = class extends CustomType {
};
var FoodSpawn = class extends CustomType {
};
var BaDum = class extends CustomType {
};
var WallSpawn2 = class extends CustomType {
};
var WallSpawnExiting = class extends CustomType {
};
function random2(lo, hi) {
  let v = random_uniform();
  return lo + v * (hi - lo);
}
function lookup_rate(sound) {
  if (sound instanceof Eat) {
    return random2(1.7, 1.9);
  } else if (sound instanceof LevelFinished) {
    return 1.7;
  } else if (sound instanceof DoorOpen) {
    return 2;
  } else if (sound instanceof FoodSpawn) {
    return random2(1.25, 1.55);
  } else if (sound instanceof BaDum) {
    return 1;
  } else if (sound instanceof WallSpawn2) {
    return random2(0.9, 1.1);
  } else if (sound instanceof WallSpawnExiting) {
    return random2(0.9, 1.1);
  } else {
    return random2(0.95, 1.05);
  }
}
function lookup_gain(sound) {
  if (sound instanceof Eat) {
    return random2(0.7, 0.8);
  } else if (sound instanceof Move) {
    return 0.2;
  } else if (sound instanceof HitWall) {
    return 0.4;
  } else if (sound instanceof FoodSpawn) {
    return random2(0.95, 1.05);
  } else if (sound instanceof BaDum) {
    return 0.5;
  } else if (sound instanceof WallSpawn2) {
    return random2(0.7, 0.8);
  } else if (sound instanceof WallSpawnExiting) {
    return random2(0.2, 0.4);
  } else {
    return random2(0.95, 1.05);
  }
}
function take_first(items) {
  if (items.atLeastLength(1)) {
    let first = items.head;
    return first;
  } else {
    throw makeError(
      "panic",
      "sound",
      82,
      "take_first",
      "needs at least 1 element in list",
      {}
    );
  }
}
function pick_random(items) {
  let _pipe = items;
  let _pipe$1 = shuffle(_pipe);
  return take_first(_pipe$1);
}
function lookup(sound) {
  if (sound instanceof Pause) {
    return "pause.mp3";
  } else if (sound instanceof Unpause) {
    return "unpause.mp3";
  } else if (sound instanceof LevelFinished) {
    return "level_finished.mp3";
  } else if (sound instanceof Eat) {
    let _pipe = toList([
      "eat4_num.mp3",
      "eat7_tasty.mp3",
      "eat8_num_num_num.mp3"
    ]);
    return pick_random(_pipe);
  } else if (sound instanceof HitWall) {
    return "hit_wall.mp3";
  } else if (sound instanceof Move) {
    return "move2.mp3";
  } else if (sound instanceof DoorOpen) {
    return "door_open.mp3";
  } else if (sound instanceof FoodSpawn) {
    return "food_spawn.mp3";
  } else if (sound instanceof BaDum) {
    return "ba_dum.mp3";
  } else if (sound instanceof WallSpawn2) {
    return "wall_spawn.mp3";
  } else {
    return "wall_spawn.mp3";
  }
}

// build/dev/javascript/snek/board.mjs
var Exit = class extends CustomType {
  constructor(pos, to_unlock) {
    super();
    this.pos = pos;
    this.to_unlock = to_unlock;
  }
};
var ExitTimer = class extends CustomType {
  constructor(pos, timer) {
    super();
    this.pos = pos;
    this.timer = timer;
  }
};
var Level = class extends CustomType {
  constructor(number, w, h) {
    super();
    this.number = number;
    this.w = w;
    this.h = h;
  }
};
var Board = class extends CustomType {
  constructor(level, grid, snek2, exit, size) {
    super();
    this.level = level;
    this.grid = grid;
    this.snek = snek2;
    this.exit = exit;
    this.size = size;
  }
};
var BgExit = class extends CustomType {
};
var BgWallSpawn = class extends CustomType {
  constructor(delay, orig) {
    super();
    this.delay = delay;
    this.orig = orig;
  }
};
var BgEmpty = class extends CustomType {
};
var FgFood = class extends CustomType {
};
var FgWall = class extends CustomType {
};
var FgEmpty = class extends CustomType {
};
var Square = class extends CustomType {
  constructor(bg, fg) {
    super();
    this.bg = bg;
    this.fg = fg;
  }
};
var FoodInfo = class extends CustomType {
  constructor(count, goal, free) {
    super();
    this.count = count;
    this.goal = goal;
    this.free = free;
  }
};
var Horizontal = class extends CustomType {
};
var Vertical = class extends CustomType {
};
var ExitInfo = class extends CustomType {
  constructor(pos, wall, orientation) {
    super();
    this.pos = pos;
    this.wall = wall;
    this.orientation = orientation;
  }
};
var WallSpawnInfo = class extends CustomType {
  constructor(pos, delay, has_food, has_wall) {
    super();
    this.pos = pos;
    this.delay = delay;
    this.has_food = has_food;
    this.has_wall = has_wall;
  }
};
function food(b) {
  let _pipe = map_to_list(b.grid);
  let _pipe$1 = filter(
    _pipe,
    (kv) => {
      let $ = kv[1];
      if ($ instanceof Square && $.fg instanceof FgFood) {
        return true;
      } else {
        return false;
      }
    }
  );
  return map(_pipe$1, (kv) => {
    return kv[0];
  });
}
function walls(b) {
  let _pipe = map_to_list(b.grid);
  let _pipe$1 = filter(
    _pipe,
    (kv) => {
      let $ = kv[1];
      if ($ instanceof Square && $.fg instanceof FgWall) {
        return true;
      } else {
        return false;
      }
    }
  );
  return map(_pipe$1, (kv) => {
    return kv[0];
  });
}
function all_pos(w, h) {
  let _pipe = range(0, h - 1);
  let _pipe$1 = map(
    _pipe,
    (y) => {
      let _pipe$12 = range(0, w - 1);
      return map(_pipe$12, (x) => {
        return new Pos(x, y);
      });
    }
  );
  return flatten(_pipe$1);
}
function move_args(b) {
  return new MoveArgs(
    b.snek,
    from_list2(food(b)),
    walls(b),
    (() => {
      let $ = b.exit;
      if ($ instanceof Exit) {
        return new None();
      } else {
        let pos = $.pos;
        return new Some(pos);
      }
    })(),
    b.level.w,
    b.level.h
  );
}
function wall_spawn_visible(delay) {
  return delay <= 9;
}
function wall_spawn_newly_visible(new_delay) {
  return new_delay === 9;
}
function init_exit(g2, pos) {
  return update(
    g2,
    pos,
    (o) => {
      if (o instanceof Some) {
        let square = o[0];
        return square.withFields({ bg: new BgExit() });
      } else {
        return new Square(new BgEmpty(), new FgEmpty());
      }
    }
  );
}
function init_food(loop$g, loop$w, loop$h) {
  while (true) {
    let g2 = loop$g;
    let w = loop$w;
    let h = loop$h;
    let f = new Pos(random(w), random(h));
    let $ = get(g2, f);
    if ($.isOk()) {
      let square = $[0];
      if (square instanceof Square && square.bg instanceof BgEmpty && square.fg instanceof FgEmpty) {
        return insert(g2, f, square.withFields({ fg: new FgFood() }));
      } else if (square instanceof Square && square.bg instanceof BgWallSpawn && square.fg instanceof FgEmpty) {
        return insert(g2, f, square.withFields({ fg: new FgFood() }));
      } else {
        loop$g = g2;
        loop$w = w;
        loop$h = h;
      }
    } else {
      throw makeError(
        "panic",
        "board",
        211,
        "init_food",
        "illegal grid does not contain " + to_string2(w) + "x" + to_string2(
          h
        ),
        {}
      );
    }
  }
}
function food_info(b) {
  let count = (() => {
    let _pipe = food(b);
    return length(_pipe);
  })();
  let goal = (() => {
    let $ = b.exit;
    if ($ instanceof Exit) {
      return 5;
    } else {
      return 10;
    }
  })();
  let free = b.level.h * b.level.w - (() => {
    let _pipe = b.snek.body;
    return length(_pipe);
  })() - (() => {
    let _pipe = walls(b);
    return length(_pipe);
  })() - count - 1;
  return new FoodInfo(count, goal, free);
}
function spawn_food(info) {
  let diff2 = (() => {
    let _pipe = min(info.free, info.goal - info.count);
    return clamp(_pipe, 0, 10);
  })();
  if (diff2 === 0) {
    return false;
  } else if (diff2 < 10) {
    let n = diff2;
    return random(10 - n) === 0;
  } else {
    return true;
  }
}
function random_pos(w, h) {
  return new Pos(random(w), random(h));
}
function r_add_food(loop$tries_remaining, loop$grid, loop$snek, loop$w, loop$h) {
  while (true) {
    let tries_remaining = loop$tries_remaining;
    let grid = loop$grid;
    let snek2 = loop$snek;
    let w = loop$w;
    let h = loop$h;
    let $ = tries_remaining <= 0;
    if ($) {
      return grid;
    } else {
      let p2 = random_pos(w, h);
      let $1 = get(grid, p2);
      if ($1.isOk()) {
        let square = $1[0];
        if (square instanceof Square && square.bg instanceof BgEmpty && square.fg instanceof FgEmpty) {
          let $2 = body_contains(snek2, p2);
          if ($2) {
            loop$tries_remaining = tries_remaining - 1;
            loop$grid = grid;
            loop$snek = snek2;
            loop$w = w;
            loop$h = h;
          } else {
            playSound(new FoodSpawn());
            return insert(
              grid,
              p2,
              square.withFields({ fg: new FgFood() })
            );
          }
        } else if (square instanceof Square && square.bg instanceof BgWallSpawn && square.fg instanceof FgEmpty) {
          let $2 = body_contains(snek2, p2);
          if ($2) {
            loop$tries_remaining = tries_remaining - 1;
            loop$grid = grid;
            loop$snek = snek2;
            loop$w = w;
            loop$h = h;
          } else {
            playSound(new FoodSpawn());
            return insert(
              grid,
              p2,
              square.withFields({ fg: new FgFood() })
            );
          }
        } else {
          loop$tries_remaining = tries_remaining - 1;
          loop$grid = grid;
          loop$snek = snek2;
          loop$w = w;
          loop$h = h;
        }
      } else {
        loop$tries_remaining = tries_remaining - 1;
        loop$grid = grid;
        loop$snek = snek2;
        loop$w = w;
        loop$h = h;
      }
    }
  }
}
function update_food(b, snek2, ate) {
  let w = b.level.w;
  let h = b.level.h;
  let grid = b.grid;
  let info = food_info(b);
  let tries = 5;
  let grid$1 = (() => {
    let $ = spawn_food(info);
    if ($) {
      return r_add_food(tries, grid, snek2, w, h);
    } else {
      return b.grid;
    }
  })();
  if (ate) {
    return update(
      grid$1,
      head(snek2),
      (o) => {
        if (o instanceof Some) {
          let square = o[0];
          if (square instanceof Square && square.fg instanceof FgFood) {
            return square.withFields({ fg: new FgEmpty() });
          } else {
            return square;
          }
        } else {
          return new Square(new BgEmpty(), new FgEmpty());
        }
      }
    );
  } else {
    return grid$1;
  }
}
function tick_down_wall_spawns(g2, snek2, exiting) {
  return map_values(
    g2,
    (pos, square) => {
      if (square instanceof Square && square.bg instanceof BgWallSpawn) {
        let delay = square.bg.delay;
        let orig = square.bg.orig;
        let $ = body_contains(snek2, pos);
        if ($) {
          return square;
        } else {
          let new_delay = max(0, delay - 1);
          let $1 = wall_spawn_newly_visible(new_delay) && orig && !exiting;
          if ($1) {
            playSound(new BaDum());
          } else {
          }
          return square.withFields({ bg: new BgWallSpawn(new_delay, orig) });
        }
      } else {
        return square;
      }
    }
  );
}
function spawn_walls(g2, snek2, exiting) {
  return map_values(
    g2,
    (pos, square) => {
      if (square instanceof Square && square.bg instanceof BgWallSpawn && square.fg instanceof FgEmpty) {
        let delay = square.bg.delay;
        let orig = square.bg.orig;
        let $ = delay <= 0 && !body_contains(snek2, pos);
        if ($) {
          if (exiting) {
            playSound(new WallSpawnExiting());
          } else {
            playSound(new WallSpawn2());
          }
          return new Square(new BgWallSpawn(0, orig), new FgWall());
        } else {
          return square;
        }
      } else if (square instanceof Square && square.bg instanceof BgWallSpawn && square.fg instanceof FgFood) {
        let delay = square.bg.delay;
        let orig = square.bg.orig;
        let $ = delay <= 0 && !body_contains(snek2, pos);
        if ($) {
          if (exiting) {
            playSound(new WallSpawnExiting());
          } else {
            playSound(new WallSpawn2());
          }
          return new Square(new BgWallSpawn(0, orig), new FgWall());
        } else {
          return square;
        }
      } else {
        return square;
      }
    }
  );
}
function time_to_escape(lvl) {
  return lvl.h;
}
function update_exit(exit, lvl, increase) {
  let increased = increase > 0;
  let to_unlock = (() => {
    if (exit instanceof Exit && increased) {
      let to_unlock2 = exit.to_unlock;
      return to_unlock2 - 1;
    } else {
      return 0;
    }
  })();
  let exit_revealed = to_unlock <= 0;
  if (increased) {
    if (exit instanceof Exit && exit_revealed) {
      let p2 = exit.pos;
      playSound(new DoorOpen());
      return new ExitTimer(p2, time_to_escape(lvl));
    } else if (exit instanceof Exit && !exit_revealed) {
      let p2 = exit.pos;
      return new Exit(p2, to_unlock);
    } else {
      let p2 = exit.pos;
      let t = exit.timer;
      return new ExitTimer(p2, t - 1);
    }
  } else {
    if (exit instanceof ExitTimer) {
      let p2 = exit.pos;
      let t = exit.timer;
      return new ExitTimer(p2, t - 1);
    } else {
      let e = exit;
      return e;
    }
  }
}
function get_exit_info(p2, w, h) {
  let w1 = w - 1;
  let h1 = h - 1;
  let dir = (() => {
    if (p2 instanceof Pos && p2.x === 0) {
      let x = p2.x;
      return new Left();
    } else if (p2 instanceof Pos && p2.x === w1) {
      let x = p2.x;
      return new Right();
    } else if (p2 instanceof Pos && p2.y === 0) {
      let y = p2.y;
      return new Up();
    } else if (p2 instanceof Pos && p2.y === h1) {
      let y = p2.y;
      return new Down();
    } else {
      throw makeError(
        "panic",
        "board",
        482,
        "get_exit_info",
        "Invalid exit",
        {}
      );
    }
  })();
  if (dir instanceof Left) {
    return new ExitInfo(p2, new Pos(p2.x - 1, p2.y), new Vertical());
  } else if (dir instanceof Right) {
    return new ExitInfo(p2, new Pos(p2.x + 1, p2.y), new Vertical());
  } else if (dir instanceof Up) {
    return new ExitInfo(p2, new Pos(p2.x, p2.y - 1), new Horizontal());
  } else {
    return new ExitInfo(p2, new Pos(p2.x, p2.y + 1), new Horizontal());
  }
}
function exit_info(b) {
  return get_exit_info(b.exit.pos, b.level.w, b.level.h);
}
function exit_countdown(e) {
  if (e instanceof Exit) {
    let to_unlock = e.to_unlock;
    return to_unlock;
  } else {
    return 0;
  }
}
function get_wall_spawns(b) {
  let _pipe = map_to_list(b.grid);
  let _pipe$1 = filter(
    _pipe,
    (kv) => {
      let $ = kv[1];
      if ($ instanceof Square && $.bg instanceof BgWallSpawn) {
        return true;
      } else {
        return false;
      }
    }
  );
  return map(
    _pipe$1,
    (kv) => {
      let $ = kv[1];
      if ($ instanceof Square && $.bg instanceof BgWallSpawn && $.fg instanceof FgFood) {
        let delay = $.bg.delay;
        return new WallSpawnInfo(kv[0], delay, true, false);
      } else if ($ instanceof Square && $.bg instanceof BgWallSpawn && $.fg instanceof FgWall) {
        let delay = $.bg.delay;
        return new WallSpawnInfo(kv[0], delay, false, true);
      } else if ($ instanceof Square && $.bg instanceof BgWallSpawn) {
        let delay = $.bg.delay;
        return new WallSpawnInfo(kv[0], delay, false, false);
      } else {
        return new WallSpawnInfo(kv[0], 0, false, false);
      }
    }
  );
}
var width2 = width;
var height2 = height;
function get_level(parsed) {
  return new Level(parsed.number, width2, height2);
}
var wall_spawn_min = 10;
function init_wall_spawns(g2, spawns) {
  let spawn_lookup = (() => {
    let _pipe2 = spawns;
    let _pipe$1 = map2(
      _pipe2,
      toList([
        wall_spawn_min + 0,
        wall_spawn_min + 10,
        wall_spawn_min + 20,
        wall_spawn_min + 30
      ]),
      (pos, delay) => {
        return [pos, delay];
      }
    );
    return from_list(_pipe$1);
  })();
  let _pipe = g2;
  return map_values(
    _pipe,
    (p2, square) => {
      let $ = get(spawn_lookup, p2);
      if ($.isOk()) {
        let delay = $[0];
        return square.withFields({ bg: new BgWallSpawn(delay, true) });
      } else {
        return square;
      }
    }
  );
}
function init3(level_number) {
  let tile_size = 40;
  let parsed = get2(level_number);
  let level = (() => {
    let _pipe = parsed;
    return get_level(_pipe);
  })();
  let snek2 = init2(parsed.snek_init, parsed.snek_dir);
  let w = level.w;
  let h = level.h;
  let grid = (() => {
    let _pipe = all_pos(w, h);
    let _pipe$1 = map(
      _pipe,
      (p2) => {
        let $ = contains(parsed.walls, p2);
        if ($) {
          return [p2, new Square(new BgEmpty(), new FgWall())];
        } else {
          return [p2, new Square(new BgEmpty(), new FgEmpty())];
        }
      }
    );
    let _pipe$2 = from_list(_pipe$1);
    let _pipe$3 = init_food(_pipe$2, w, h);
    let _pipe$4 = init_exit(_pipe$3, parsed.exit_pos);
    return init_wall_spawns(_pipe$4, parsed.spawns);
  })();
  return new Board(level, grid, snek2, new Exit(parsed.exit_pos, 10), tile_size);
}
function next_level(b) {
  return init3(b.level.number + 1);
}
var wall_spawn_max = 16;
function spawn_init_delay() {
  return random(wall_spawn_max - wall_spawn_min) + wall_spawn_min + 1;
}
function update_walls(b, exiting) {
  let $ = b.exit;
  if ($ instanceof ExitTimer && $.timer < 10) {
    let t = $.timer;
    let w = b.level.w;
    let h = b.level.h;
    let update_grid = (() => {
      let _pipe = b.grid;
      let _pipe$1 = map_to_list(_pipe);
      let _pipe$2 = filter(
        _pipe$1,
        (kv) => {
          let $1 = kv[1];
          if ($1 instanceof Square && $1.bg instanceof BgWallSpawn && $1.fg instanceof FgEmpty) {
            let delay = $1.bg.delay;
            return delay <= 0;
          } else if ($1 instanceof Square && $1.bg instanceof BgWallSpawn && $1.fg instanceof FgFood) {
            let delay = $1.bg.delay;
            return delay <= 0;
          } else {
            return false;
          }
        }
      );
      let _pipe$3 = map(
        _pipe$2,
        (kv) => {
          let pos = kv[0];
          let square = kv[1];
          let _pipe$32 = toList([
            new Pos(pos.x - 1, pos.y),
            new Pos(pos.x + 1, pos.y),
            new Pos(pos.x, pos.y - 1),
            new Pos(pos.x, pos.y + 1)
          ]);
          let _pipe$42 = filter(
            _pipe$32,
            (pos2) => {
              return pos2.x >= 0 && pos2.x < w && pos2.y >= 0 && pos2.y < h;
            }
          );
          let _pipe$5 = filter(
            _pipe$42,
            (pos2) => {
              return !body_contains(b.snek, pos2);
            }
          );
          return map(
            _pipe$5,
            (pos2) => {
              return [
                pos2,
                square.withFields({
                  bg: new BgWallSpawn(spawn_init_delay(), false)
                })
              ];
            }
          );
        }
      );
      let _pipe$4 = flatten(_pipe$3);
      return from_list(_pipe$4);
    })();
    let new_grid = (() => {
      let _pipe = combine(
        b.grid,
        update_grid,
        (a, b2) => {
          if (a instanceof Square && a.bg instanceof BgEmpty && a.fg instanceof FgEmpty) {
            return b2;
          } else if (a instanceof Square && a.bg instanceof BgEmpty && a.fg instanceof FgFood) {
            return new Square(b2.bg, a.fg);
          } else {
            return a;
          }
        }
      );
      let _pipe$1 = spawn_walls(_pipe, b.snek, exiting);
      return tick_down_wall_spawns(_pipe$1, b.snek, exiting);
    })();
    return b.withFields({ grid: new_grid });
  } else {
    return b;
  }
}
function update3(board) {
  let exiting = false;
  let result = move2(move_args(board));
  let score_increase = (() => {
    let $ = result.died;
    let $1 = result.ate;
    if (!$ && $1) {
      playSound(new Eat());
      return 1;
    } else {
      return 0;
    }
  })();
  let grid = update_food(board, result.snek, result.ate);
  return [
    (() => {
      let _pipe = board.withFields({
        grid,
        snek: result.snek,
        exit: update_exit(board.exit, board.level, score_increase),
        level: board.level
      });
      return update_walls(_pipe, exiting);
    })(),
    result
  ];
}
function update_exiting(board) {
  let exiting = true;
  let exit_info$1 = get_exit_info(board.exit.pos, width2, height2);
  let $ = move_exiting(board.snek, exit_info$1.wall);
  let new_snek = $[0];
  let done = $[1];
  let grid = update_food(board, new_snek, false);
  return [
    (() => {
      let _pipe = board.withFields({
        grid,
        snek: new_snek,
        level: board.level
      });
      return update_walls(_pipe, exiting);
    })(),
    done
  ];
}

// build/dev/javascript/snek/color.mjs
function hsl(h, s, l) {
  return "hsl(" + to_string2(h) + "," + to_string2(s) + "%," + to_string2(
    l
  ) + "%)";
}
function background() {
  return hsl(257, 39, 7);
}
function grid_border() {
  return hsl(257, 39, 60);
}
function game_outline() {
  return hsl(257, 39, 60);
}
function grid_background() {
  return hsl(257, 39, 7);
}
function food2() {
  return hsl(350, 89, 60);
}
function snek() {
  return hsl(190, 98, 50);
}
var grid_lines = grid_border;

// build/dev/javascript/snek/snek_ffi.mjs
function documentAddEventListener(type, listener) {
  return document.addEventListener(type, listener);
}
function eventCode(event) {
  return event.code;
}
var id = void 0;
function windowSetInterval(interval, cb) {
  windowClearInterval();
  id = window.setInterval(cb, interval);
}
function windowClearInterval() {
  if (id) {
    window.clearInterval(id);
    id = void 0;
  }
}

// build/dev/javascript/snek/time_ffi.mjs
function getTime() {
  return Date.now();
}

// build/dev/javascript/snek/time.mjs
var tick_speed = 250;
var late_fraction = 0.6;
function late(t) {
  let ms_since$1 = getTime() - t;
  let lower_bound = (() => {
    let _pipe = to_float(tick_speed) * late_fraction;
    return round(_pipe);
  })();
  return ms_since$1 > lower_bound;
}

// build/dev/javascript/snek/snek.mjs
var Menu = class extends CustomType {
};
var Play = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var Pause2 = class extends CustomType {
};
var Exiting = class extends CustomType {
};
var Died = class extends CustomType {
};
var GameOver = class extends CustomType {
};
var Run = class extends CustomType {
  constructor(score, level_score, lives) {
    super();
    this.score = score;
    this.level_score = level_score;
    this.lives = lives;
  }
};
var Model = class extends CustomType {
  constructor(board, run, state, keydown) {
    super();
    this.board = board;
    this.run = run;
    this.state = state;
    this.keydown = keydown;
  }
};
var Keydown = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var Tick = class extends CustomType {
};
var TickSkip = class extends CustomType {
};
var TickStart = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var ZElem = class extends CustomType {
  constructor(index2, elem) {
    super();
    this.index = index2;
    this.elem = elem;
  }
};
function f_every(interval, tick) {
  let _pipe = toList([
    from2((dispatch2) => {
      return dispatch2(tick);
    }),
    from2(
      (dispatch2) => {
        return windowSetInterval(interval, () => {
          return dispatch2(tick);
        });
      }
    )
  ]);
  return batch(_pipe);
}
function every(interval, tick) {
  return from2(
    (dispatch2) => {
      return windowSetInterval(interval, () => {
        return dispatch2(tick);
      });
    }
  );
}
function tick_skip() {
  return from2((dispatch2) => {
    return dispatch2(new TickSkip());
  });
}
function int_fraction(n, mult) {
  let _pipe = to_float(n) * mult;
  return round(_pipe);
}
function list_of_one(elem) {
  return toList([elem]);
}
function snek_to_points(snek2, size, offset) {
  let half_size = divideInt(size, 2);
  let _pipe = snek2;
  let _pipe$1 = map(
    _pipe,
    (pos) => {
      return new Pos(
        pos.x * size + half_size + offset.x,
        pos.y * size + half_size + offset.y
      );
    }
  );
  let _pipe$2 = map(
    _pipe$1,
    (pos) => {
      return to_string2(pos.x) + "," + to_string2(pos.y);
    }
  );
  return fold2(_pipe$2, "", (pos, acc) => {
    return acc + " " + pos;
  });
}
function center_number(n, w, h) {
  let text_w = (() => {
    let $ = n > 9;
    if ($) {
      return 9;
    } else {
      return 5;
    }
  })();
  let text_h = 10;
  let x = divideInt(w, 2) - text_w;
  let y = divideInt(h - text_h, 2);
  return new Pos(x, h - y);
}
var tick_speed2 = tick_speed;
function update_menu(model, msg) {
  if (msg instanceof Keydown && msg[0] === "Space") {
    let str = msg[0];
    return [
      model.withFields({ state: new Play(getTime()), keydown: str }),
      every(tick_speed2, new Tick())
    ];
  } else if (msg instanceof Keydown) {
    let str = msg[0];
    return [model.withFields({ keydown: str }), none()];
  } else {
    return [model, none()];
  }
}
function update_pause(model, msg) {
  if (msg instanceof Keydown) {
    let str = msg[0];
    if (str === "Escape") {
      playSound(new Unpause());
      return [
        model.withFields({ keydown: str, state: new Play(getTime()) }),
        every(tick_speed2, new Tick())
      ];
    } else if (str === "Space") {
      playSound(new Unpause());
      return [
        model.withFields({ keydown: str, state: new Play(getTime()) }),
        every(tick_speed2, new Tick())
      ];
    } else {
      return [model.withFields({ keydown: str }), none()];
    }
  } else {
    return [model, none()];
  }
}
function update_died(model, msg) {
  if (msg instanceof Keydown) {
    let str = msg[0];
    if (str === "Space") {
      return [
        model.withFields({
          board: init3(model.board.level.number),
          keydown: str,
          state: new Play(getTime())
        }),
        every(tick_speed2, new Tick())
      ];
    } else {
      return [model.withFields({ keydown: str }), none()];
    }
  } else {
    return [model, none()];
  }
}
function update_tick_exiting(model) {
  let $ = update_exiting(model.board);
  let new_board = $[0];
  let done = $[1];
  if (done) {
    let score = model.run.score + model.run.level_score;
    return [
      model.withFields({
        run: model.run.withFields({ score, level_score: 0 }),
        state: new Play(getTime()),
        board: next_level(model.board)
      }),
      every(tick_speed2, new Tick())
    ];
  } else {
    return [model.withFields({ board: new_board }), none()];
  }
}
function update_exiting2(model, msg) {
  if (msg instanceof Keydown) {
    let str = msg[0];
    return [model.withFields({ keydown: str }), none()];
  } else if (msg instanceof Tick) {
    playSound(new Move());
    return update_tick_exiting(model);
  } else if (msg instanceof TickSkip) {
    return [model, none()];
  } else if (msg instanceof TickStart) {
    let ms = msg[0];
    return [model, every(ms, new Tick())];
  } else {
    let $ = windowClearInterval();
    return [model, none()];
  }
}
var exiting_tick_speed = 50;
function update_tick(model) {
  let $ = update3(model.board);
  let new_board = $[0];
  let result = $[1];
  let $1 = result.died;
  if ($1) {
    playSound(new HitWall());
    let lives = model.run.lives - 1;
    let $2 = lives === 0;
    if ($2) {
      return [
        model.withFields({
          run: model.run.withFields({ lives }),
          board: new_board,
          state: new GameOver()
        }),
        none()
      ];
    } else {
      return [
        model.withFields({
          run: model.run.withFields({ lives }),
          board: new_board,
          state: new Died()
        }),
        none()
      ];
    }
  } else {
    let $2 = result.exit;
    if ($2) {
      playSound(new LevelFinished());
      return [
        model.withFields({ board: new_board, state: new Exiting() }),
        every(exiting_tick_speed, new Tick())
      ];
    } else {
      let lvl_score = (() => {
        let $3 = result.ate;
        if ($3) {
          return model.run.level_score + 1;
        } else {
          return model.run.level_score;
        }
      })();
      return [
        model.withFields({
          run: model.run.withFields({ level_score: lvl_score }),
          board: new_board,
          state: new Play(getTime())
        }),
        none()
      ];
    }
  }
}
function update_play(model, msg, last_tick_ms) {
  if (msg instanceof Keydown) {
    let str = msg[0];
    let level_num = model.board.level.number;
    let new_level = (() => {
      if (str === "Comma") {
        return clamp2(level_num - 1);
      } else if (str === "Period") {
        return clamp2(level_num + 1);
      } else {
        return level_num;
      }
    })();
    let late2 = late(last_tick_ms);
    let $ = (() => {
      if (str === "KeyW") {
        return [
          new Play(last_tick_ms),
          keypress(new Up(), late2, move_args(model.board))
        ];
      } else if (str === "ArrowUp") {
        return [
          new Play(last_tick_ms),
          keypress(new Up(), late2, move_args(model.board))
        ];
      } else if (str === "KeyA") {
        return [
          new Play(last_tick_ms),
          keypress(new Left(), late2, move_args(model.board))
        ];
      } else if (str === "ArrowLeft") {
        return [
          new Play(last_tick_ms),
          keypress(new Left(), late2, move_args(model.board))
        ];
      } else if (str === "KeyS") {
        return [
          new Play(last_tick_ms),
          keypress(new Down(), late2, move_args(model.board))
        ];
      } else if (str === "ArrowDown") {
        return [
          new Play(last_tick_ms),
          keypress(new Down(), late2, move_args(model.board))
        ];
      } else if (str === "KeyD") {
        return [
          new Play(last_tick_ms),
          keypress(new Right(), late2, move_args(model.board))
        ];
      } else if (str === "ArrowRight") {
        return [
          new Play(last_tick_ms),
          keypress(new Right(), late2, move_args(model.board))
        ];
      } else if (str === "Escape") {
        let $12 = windowClearInterval();
        playSound(new Pause());
        return [new Pause2(), [model.board.snek, false]];
      } else if (str === "Space") {
        let $12 = windowClearInterval();
        playSound(new Pause());
        return [new Pause2(), [model.board.snek, false]];
      } else {
        return [new Play(last_tick_ms), [model.board.snek, false]];
      }
    })();
    let new_state = $[0];
    let new_snek = $[1][0];
    let new_turn = $[1][1];
    let $1 = new_level === level_num;
    if (!$1) {
      return [
        model.withFields({ board: init3(new_level), keydown: str }),
        none()
      ];
    } else {
      return [
        model.withFields({
          board: model.board.withFields({ snek: new_snek }),
          keydown: str,
          state: new_state
        }),
        (() => {
          if (new_turn) {
            return tick_skip();
          } else {
            return none();
          }
        })()
      ];
    }
  } else if (msg instanceof Tick) {
    playSound(new Move());
    return update_tick(model);
  } else if (msg instanceof TickSkip) {
    let $ = windowClearInterval();
    return [model, f_every(tick_speed, new Tick())];
  } else if (msg instanceof TickStart) {
    let ms = msg[0];
    return [model, every(ms, new Tick())];
  } else {
    let $ = windowClearInterval();
    return [model, none()];
  }
}
var max_lives = 3;
function init4(_) {
  return [
    new Model(init3(1), new Run(0, 0, max_lives), new Menu(), "N/A"),
    none()
  ];
}
function update_game_over(model, msg) {
  if (msg instanceof Keydown) {
    let str = msg[0];
    if (str === "Space") {
      return [
        new Model(
          init3(1),
          new Run(0, 0, max_lives),
          new Play(getTime()),
          str
        ),
        every(tick_speed2, new Tick())
      ];
    } else {
      return [model.withFields({ keydown: str }), none()];
    }
  } else {
    return [model, none()];
  }
}
function update4(model, msg) {
  let $ = model.state;
  if ($ instanceof Menu) {
    return update_menu(model, msg);
  } else if ($ instanceof Play) {
    let ms = $[0];
    return update_play(model, msg, ms);
  } else if ($ instanceof Exiting) {
    return update_exiting2(model, msg);
  } else if ($ instanceof Pause2) {
    return update_pause(model, msg);
  } else if ($ instanceof Died) {
    return update_died(model, msg);
  } else {
    return update_game_over(model, msg);
  }
}
var class$2 = class$;
function menu_font_class() {
  return class$2("share-tech-mono-regular");
}
var attr_str = attribute;
function attr(name, value) {
  return attr_str(name, to_string2(value));
}
function line2(x1, y1, x2, y2, width3) {
  return line(
    toList([
      attr("x1", x1),
      attr("y1", y1),
      attr("x2", x2),
      attr("y2", y2),
      attr("stroke-width", width3)
    ])
  );
}
function bbox_to_attrs(bbox, offset) {
  return toList([
    attr("x", bbox.x + offset.x),
    attr("y", bbox.y + offset.y),
    attr("width", bbox.w),
    attr("height", bbox.h)
  ]);
}
function bbox_lines(bbox, offset, dir) {
  if (dir instanceof Left) {
    return toList([
      attr("x1", bbox.x + offset.x),
      attr("y1", bbox.y + offset.y),
      attr("x2", bbox.x + offset.x),
      attr("y2", bbox.y + offset.y + bbox.h)
    ]);
  } else if (dir instanceof Right) {
    return toList([
      attr("x1", bbox.x + offset.x + bbox.w),
      attr("y1", bbox.y + offset.y),
      attr("x2", bbox.x + offset.x + bbox.w),
      attr("y2", bbox.y + offset.y + bbox.h)
    ]);
  } else if (dir instanceof Up) {
    return toList([
      attr("x1", bbox.x + offset.x),
      attr("y1", bbox.y + offset.y),
      attr("x2", bbox.x + offset.x + bbox.w),
      attr("y2", bbox.y + offset.y)
    ]);
  } else {
    return toList([
      attr("x1", bbox.x + offset.x),
      attr("y1", bbox.y + offset.y + bbox.h),
      attr("x2", bbox.x + offset.x + bbox.w),
      attr("y2", bbox.y + offset.y + bbox.h)
    ]);
  }
}
function draw_snek(snek2, snek_width, size, offset) {
  return g(
    toList([
      attr_str("stroke", snek()),
      attr("stroke-width", snek_width),
      attr_str("fill-opacity", "0")
    ]),
    toList([
      polyline(
        toList([
          attr_str("stroke-linecap", "square"),
          attr_str("points", snek_to_points(snek2.body, size, offset))
        ])
      )
    ])
  );
}
function draw_food(food3, food_radius, size, offset) {
  let half_size = divideInt(size, 2);
  return g(
    toList([attr_str("fill", food2()), attr("stroke-width", 0)]),
    (() => {
      let _pipe = food3;
      return map(
        _pipe,
        (pos) => {
          return circle(
            toList([
              attr("cx", pos.x * size + half_size + offset.x),
              attr("cy", pos.y * size + half_size + offset.y),
              attr("r", food_radius)
            ])
          );
        }
      );
    })()
  );
}
function draw_edge_walls(pattern2, w, h, size, offset) {
  let fill = "url(#" + pattern2 + ")";
  let path_m = (p2, x, y) => {
    return p2 + "M " + to_string2(x) + " " + to_string2(y);
  };
  let path_h = (p2, a) => {
    return p2 + " h " + to_string2(a);
  };
  let path_v = (p2, a) => {
    return p2 + " v " + to_string2(a);
  };
  let path_z = (p2) => {
    return p2 + " z";
  };
  let wi = w - size;
  let hi = h - size * 2;
  let path2 = (() => {
    let _pipe = path_m("", 0, size);
    let _pipe$1 = path_h(_pipe, w);
    let _pipe$2 = path_v(_pipe$1, h);
    let _pipe$3 = path_h(_pipe$2, -w);
    return path_z(_pipe$3);
  })() + (() => {
    let _pipe = " ";
    let _pipe$1 = path_m(_pipe, offset.x, offset.y);
    let _pipe$2 = path_h(_pipe$1, wi);
    let _pipe$3 = path_v(_pipe$2, hi);
    let _pipe$4 = path_h(_pipe$3, -wi);
    return path_z(_pipe$4);
  })();
  return g(
    toList([attr_str("fill-rule", "evenodd")]),
    toList([
      path(
        toList([
          attr_str("fill", background()),
          attr_str("d", path2),
          attr("stroke-width", 0)
        ])
      ),
      path(
        toList([
          attr_str("fill", fill),
          attr_str("d", path2),
          attr("stroke-width", 0)
        ])
      )
    ])
  );
}
function draw_walls(walls2, size, offset) {
  let wall_size = int_fraction(size, 0.8);
  let center_offset = int_fraction(size, 0.1);
  return g(
    toList([attr_str("fill", grid_lines())]),
    (() => {
      let _pipe = walls2;
      return map(
        _pipe,
        (pos) => {
          return rect(
            toList([
              attr("x", pos.x * size + (offset.x + center_offset)),
              attr("y", pos.y * size + (offset.y + center_offset)),
              attr("width", wall_size),
              attr("height", wall_size)
            ])
          );
        }
      );
    })()
  );
}
function draw_exit(exit, exit_info2, state, to_bbox2, offset) {
  let exit_bbox = to_bbox2(exit_info2.pos);
  let wall_bbox = to_bbox2(exit_info2.wall);
  let behind = 2;
  let infront = 4;
  if (exit instanceof ExitTimer) {
    let hilite = hsl(126, 90, 61);
    let exiting_behind = (() => {
      let $ = isEqual(state, new Exiting());
      if ($) {
        return behind;
      } else {
        return infront;
      }
    })();
    return toList([
      (() => {
        let _pipe = rect(
          prepend(
            attr_str("fill", hilite),
            prepend(
              attr_str("opacity", "0.6"),
              bbox_to_attrs(exit_bbox, offset)
            )
          )
        );
        return ((_capture) => {
          return new ZElem(behind, _capture);
        })(_pipe);
      })(),
      (() => {
        let _pipe = rect(
          prepend(
            attr_str("fill", hilite),
            prepend(
              attr_str("opacity", "1.0"),
              bbox_to_attrs(wall_bbox, offset)
            )
          )
        );
        return ((_capture) => {
          return new ZElem(exiting_behind, _capture);
        })(
          _pipe
        );
      })(),
      (() => {
        let _pipe = line(
          prepend(
            attr_str("stroke", grid_lines()),
            prepend(
              attr("stroke-width", 5),
              bbox_lines(wall_bbox, offset, new Down())
            )
          )
        );
        return ((_capture) => {
          return new ZElem(exiting_behind, _capture);
        })(
          _pipe
        );
      })(),
      (() => {
        let _pipe = line(
          prepend(
            attr_str("stroke", grid_lines()),
            prepend(
              attr("stroke-width", 5),
              bbox_lines(wall_bbox, offset, new Up())
            )
          )
        );
        return ((_capture) => {
          return new ZElem(exiting_behind, _capture);
        })(
          _pipe
        );
      })()
    ]);
  } else {
    return toList([
      (() => {
        let _pipe = rect(
          prepend(
            attr_str("fill", grid_border()),
            prepend(
              attr_str("opacity", "0.2"),
              bbox_to_attrs(exit_bbox, offset)
            )
          )
        );
        return ((_capture) => {
          return new ZElem(behind, _capture);
        })(_pipe);
      })(),
      (() => {
        let _pipe = rect(
          prepend(
            attr_str("fill", background()),
            prepend(
              attr_str("stroke", grid_border()),
              prepend(
                attr("stroke-width", 2),
                bbox_to_attrs(wall_bbox, offset)
              )
            )
          )
        );
        return ((_capture) => {
          return new ZElem(infront, _capture);
        })(_pipe);
      })(),
      (() => {
        let countdown = exit_countdown(exit);
        let countdown_offset = center_number(
          countdown,
          wall_bbox.w,
          wall_bbox.h
        );
        let pos = (() => {
          let _pipe2 = new Pos(wall_bbox.x, wall_bbox.y);
          let _pipe$1 = add2(_pipe2, offset);
          return add2(_pipe$1, countdown_offset);
        })();
        let _pipe = text2(
          toList([
            attr("x", pos.x),
            attr("y", pos.y),
            attr_str("class", "share-tech-mono-regular"),
            attr_str("class", "pause-text"),
            attr_str("fill", "white")
          ]),
          to_string2(countdown)
        );
        return ((_capture) => {
          return new ZElem(infront, _capture);
        })(_pipe);
      })()
    ]);
  }
}
function draw_menu_bar(exit, run, _, w, _1, size) {
  return toList([
    g(
      toList([attr("stroke-width", 0), attr_str("fill", background())]),
      toList([
        rect(
          toList([
            attr("x", 0),
            attr("y", 0),
            attr("width", w),
            attr("height", size)
          ])
        )
      ])
    ),
    g(
      toList([attr_str("fill", "white")]),
      toList([
        text2(
          toList([
            attr("x", 12),
            attr("y", size - 12),
            attr_str("class", "share-tech-mono-regular"),
            attr_str("class", "pause-text")
          ]),
          "score:" + to_string2(run.score + run.level_score)
        ),
        text2(
          toList([
            attr("x", 110),
            attr("y", size - 12),
            attr_str("class", "share-tech-mono-regular"),
            attr_str("class", "pause-text")
          ]),
          "lives:" + to_string2(run.lives)
        ),
        (() => {
          if (exit instanceof Exit) {
            let to_unlock = exit.to_unlock;
            return text2(
              toList([
                attr("x", 210),
                attr("y", size - 12),
                attr_str("class", "share-tech-mono-regular"),
                attr_str("class", "pause-text")
              ]),
              "food to unlock:" + to_string2(to_unlock)
            );
          } else {
            let t = exit.timer;
            let col = (() => {
              let $ = t <= 0;
              if ($) {
                return "red";
              } else {
                return "white";
              }
            })();
            return text2(
              toList([
                attr("x", 240),
                attr("y", size - 12),
                attr_str("class", "share-tech-mono-regular"),
                attr_str("class", "pause-text"),
                attr_str("fill", col)
              ]),
              to_string2(t)
            );
          }
        })()
      ])
    )
  ]);
}
function rect_outline(pos, w, h, color, opacity) {
  let line_width = 1;
  let x0 = pos.x;
  let x1 = pos.x + w;
  let y0 = pos.y;
  let y1 = pos.y + h;
  return g(
    toList([
      attr_str("stroke", color),
      attr_str("opacity", to_string4(opacity))
    ]),
    toList([
      line2(x0, y0, x1, y0, line_width),
      line2(x0, y0, x0, y1, line_width),
      line2(x0, y1, x1, y1, line_width),
      line2(x1, y0, x1, y1, line_width)
    ])
  );
}
function draw_wall_spawns(wall_spawns, size, offset) {
  return g(
    toList([attr_str("fill", "red")]),
    (() => {
      let _pipe = wall_spawns;
      let _pipe$1 = filter(
        _pipe,
        (info) => {
          return !info.has_wall && wall_spawn_visible(info.delay);
        }
      );
      let _pipe$2 = map(
        _pipe$1,
        (info) => {
          let $ = (() => {
            let $1 = info.has_food;
            if ($1) {
              let $2 = info.delay;
              if ($2 >= 8) {
                let x = $2;
                return ["white", "white", 0];
              } else if ($2 >= 4) {
                let x = $2;
                return ["yellow", "orange", 0.3];
              } else {
                return ["orange", "red", 0.5];
              }
            } else {
              let $2 = info.delay;
              if ($2 >= 8) {
                let x = $2;
                return ["white", "white", 0];
              } else if ($2 >= 4) {
                let x = $2;
                return ["orange", "orange", 0.3];
              } else {
                return ["red", "red", 0.5];
              }
            }
          })();
          let text_color = $[0];
          let outline_color = $[1];
          let outline_opacity = $[2];
          let center_offset = center_number(info.delay, size, size);
          return toList([
            text2(
              toList([
                attr("x", info.pos.x * size + (offset.x + center_offset.x)),
                attr("y", info.pos.y * size + (offset.y + center_offset.y)),
                attr_str("class", "share-tech-mono-regular"),
                attr_str("class", "pause-text"),
                attr_str("fill", text_color)
              ]),
              to_string2(info.delay)
            ),
            (() => {
              let rect_size = int_fraction(size, 0.8);
              let rect_offset = int_fraction(size, 0.1);
              let x = info.pos.x * size + (offset.x + rect_offset);
              let y = info.pos.y * size + (offset.y + rect_offset);
              return rect_outline(
                new Pos(x, y),
                rect_size,
                rect_size,
                outline_color,
                outline_opacity
              );
            })()
          ]);
        }
      );
      return flatten(_pipe$2);
    })()
  );
}
function draw_board(b, run, state) {
  let last_tick_ms = (() => {
    if (state instanceof Play) {
      let ms = state[0];
      return ms;
    } else {
      return 0;
    }
  })();
  let size = b.size;
  let to_bbox2 = (p2) => {
    return to_bbox(p2, b.level.w, b.level.h, size);
  };
  let offset = new Pos(divideInt(size, 2), size + divideInt(size, 2));
  let board_w = b.level.w * size;
  let board_h = b.level.h * size;
  let w = board_w + offset.x * 2;
  let h = board_h + (offset.y + divideInt(size, 2));
  let half_size = divideInt(size, 2);
  let snek_width = int_fraction(size, 0.5);
  let food_radius = int_fraction(half_size, 0.5);
  let grid_line_width = 1;
  return svg(
    toList([
      attr("width", w),
      attr("height", h),
      attr_str("xmlns", "http://www.w3.org/2000/svg"),
      attr_str("version", "1.1")
    ]),
    (() => {
      let _pipe = toList([
        (() => {
          let _pipe2 = defs(
            toList([]),
            toList([
              pattern(
                toList([
                  attr_str("id", "pattern"),
                  attr("width", 8),
                  attr("height", 9),
                  attr_str("patternUnits", "userSpaceOnUse"),
                  attr_str("patternTransform", "rotate(45)")
                ]),
                toList([
                  line(
                    toList([
                      attr_str("stroke", game_outline()),
                      attr_str("stroke-width", "5px"),
                      attr_str("y2", "4")
                    ])
                  )
                ])
              )
            ])
          );
          let _pipe$12 = ((_capture) => {
            return new ZElem(0, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })(),
        (() => {
          let _pipe2 = draw_edge_walls("pattern", w, h, size, offset);
          let _pipe$12 = ((_capture) => {
            return new ZElem(
              (() => {
                let $ = isEqual(state, new Exiting());
                if ($) {
                  return 2;
                } else {
                  return 4;
                }
              })(),
              _capture
            );
          })(_pipe2);
          return list_of_one(_pipe$12);
        })(),
        (() => {
          let _pipe2 = rect(
            toList([
              attr("x", offset.x),
              attr("y", offset.y),
              attr("width", board_w),
              attr("height", board_h),
              attr("stroke-width", 0),
              attr_str("fill", grid_background())
            ])
          );
          let _pipe$12 = ((_capture) => {
            return new ZElem(0, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })(),
        (() => {
          let _pipe2 = g(
            toList([attr_str("stroke", grid_lines())]),
            (() => {
              let _pipe3 = range(0, divideInt(w, size) - 1);
              return map(
                _pipe3,
                (a) => {
                  let x = a * size + offset.x;
                  let y1 = offset.y;
                  let y2 = offset.y + board_h;
                  return line2(x, y1, x, y2, grid_line_width);
                }
              );
            })()
          );
          let _pipe$12 = ((_capture) => {
            return new ZElem(1, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })(),
        (() => {
          let _pipe2 = g(
            toList([attr_str("stroke", grid_lines())]),
            (() => {
              let _pipe3 = range(0, divideInt(h, size) - 1);
              return map(
                _pipe3,
                (a) => {
                  let x1 = offset.x;
                  let y = a * size + offset.y;
                  let x2 = offset.x + board_w;
                  return line2(x1, y, x2, y, grid_line_width);
                }
              );
            })()
          );
          let _pipe$12 = ((_capture) => {
            return new ZElem(1, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })(),
        (() => {
          let _pipe2 = draw_food(food(b), food_radius, size, offset);
          let _pipe$12 = ((_capture) => {
            return new ZElem(2, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })(),
        (() => {
          let _pipe2 = draw_wall_spawns(get_wall_spawns(b), size, offset);
          let _pipe$12 = ((_capture) => {
            return new ZElem(2, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })(),
        (() => {
          let _pipe2 = draw_snek(b.snek, snek_width, size, offset);
          let _pipe$12 = ((_capture) => {
            return new ZElem(3, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })(),
        (() => {
          let _pipe2 = draw_walls(walls(b), size, offset);
          let _pipe$12 = ((_capture) => {
            return new ZElem(4, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })(),
        draw_exit(b.exit, exit_info(b), state, to_bbox2, offset),
        (() => {
          let _pipe2 = draw_menu_bar(b.exit, run, last_tick_ms, w, h, size);
          return map(
            _pipe2,
            (_capture) => {
              return new ZElem(4, _capture);
            }
          );
        })(),
        (() => {
          let _pipe2 = g(
            toList([attr_str("stroke", game_outline())]),
            toList([
              line2(0, 0, w, 0, grid_line_width * 2),
              line2(0, size, w, size, grid_line_width),
              line2(0, 0, 0, h, grid_line_width * 2),
              line2(0, h, w, h, grid_line_width * 2),
              line2(w, 0, w, h, grid_line_width * 2)
            ])
          );
          let _pipe$12 = ((_capture) => {
            return new ZElem(4, _capture);
          })(
            _pipe2
          );
          return list_of_one(_pipe$12);
        })()
      ]);
      let _pipe$1 = flatten(_pipe);
      let _pipe$2 = sort(
        _pipe$1,
        (e1, e2) => {
          return compare(e1.index, e2.index);
        }
      );
      return map(_pipe$2, (e) => {
        return e.elem;
      });
    })()
  );
}
function view(model) {
  return div(
    toList([class$2("fullscreen")]),
    (() => {
      let $ = model.state;
      if ($ instanceof Menu) {
        return toList([draw_board(model.board, model.run, model.state)]);
      } else if ($ instanceof Play) {
        return toList([draw_board(model.board, model.run, model.state)]);
      } else if ($ instanceof Exiting) {
        return toList([draw_board(model.board, model.run, model.state)]);
      } else if ($ instanceof Pause2) {
        return toList([
          draw_board(model.board, model.run, model.state),
          div(
            toList([class$2("pause-mask")]),
            toList([
              div(
                toList([class$2("pause-box")]),
                toList([
                  h3(
                    toList([class$2("pause-header"), menu_font_class()]),
                    toList([text("PAUSED")])
                  ),
                  p(
                    toList([class$2("pause-text"), menu_font_class()]),
                    toList([text("Press 'SPACE' or 'ESC' to continue")])
                  )
                ])
              )
            ])
          )
        ]);
      } else if ($ instanceof Died) {
        return toList([
          draw_board(model.board, model.run, model.state),
          div(
            toList([class$2("pause-mask")]),
            toList([
              div(
                toList([class$2("pause-box")]),
                toList([
                  h3(
                    toList([class$2("pause-header"), menu_font_class()]),
                    toList([
                      text(
                        "Remaining Lives: " + to_string2(model.run.lives)
                      )
                    ])
                  ),
                  p(
                    toList([class$2("pause-text"), menu_font_class()]),
                    toList([text("Press 'SPACE' to restart level")])
                  )
                ])
              )
            ])
          )
        ]);
      } else {
        return toList([
          draw_board(model.board, model.run, model.state),
          div(
            toList([class$2("pause-mask")]),
            toList([
              div(
                toList([class$2("pause-box")]),
                toList([
                  h3(
                    toList([class$2("pause-header"), menu_font_class()]),
                    toList([text("GAME OVER")])
                  ),
                  p(
                    toList([class$2("pause-text"), menu_font_class()]),
                    toList([text("Press 'SPACE' to play again")])
                  )
                ])
              )
            ])
          )
        ]);
      }
    })()
  );
}
function main() {
  let app = application(init4, update4, view);
  let $ = start3(app, "#app", void 0);
  if (!$.isOk()) {
    throw makeError(
      "assignment_no_match",
      "snek",
      23,
      "main",
      "Assignment pattern did not match",
      { value: $ }
    );
  }
  let send_to_runtime = $[0];
  return documentAddEventListener(
    "keydown",
    (event) => {
      let _pipe = eventCode(event);
      let _pipe$1 = new Keydown(_pipe);
      let _pipe$2 = dispatch(_pipe$1);
      return send_to_runtime(_pipe$2);
    }
  );
}

// build/.lustre/entry.mjs
main();
