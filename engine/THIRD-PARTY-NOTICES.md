# Third-party notices

kyoten is licensed MIT OR Apache-2.0 (`LICENSE-MIT`, `LICENSE-APACHE` at the repository's root). This file holds the
notices of other people's code that a program built on kyoten contains, which travel with every copy of that program.

## musl's math functions, through `reproducible-float`

kyoten's manifest declares `"reproducible-float": true`, so a simulation gives the same bits on every target
(frame-phases.md § Decided). kama then compiles 14 of `std::math`'s functions (`sin`, `cos`, `tan`, `asin`, `acos`,
`atan`, `exp`, `log`, `log2`, `log10`, `cbrt`, `pow`, `atan2` and `hypot`, in both widths) from musl 1.2.6 into every
program built on kyoten, natively and on wasm (kama `docs/targets.md`, "And a notice"). The key propagates from a
dependency, so every game built on kyoten is built with it, and kama's documentation says that a program built with
the key carries musl's licence.

The text below is copied verbatim from kama's `include/kama_libm.h` (kama 0.9.876), which kama generates from musl's
sources: first its first comment, musl's licence, then the notices that header keeps above the code that carries
them. Sun's notice asks that it be preserved.

### musl

```
musl as a whole is licensed under the following standard MIT license:

----------------------------------------------------------------------
Copyright © 2005-2020 Rich Felker, et al.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
----------------------------------------------------------------------

Much of the math library code (src/math/* and src/complex/*) is
Copyright © 1993,2004 Sun Microsystems or
Copyright © 2003-2011 David Schultz or
Copyright © 2003-2009 Steven G. Kargl or
Copyright © 2003-2009 Bruce D. Evans or
Copyright © 2008 Stephen L. Moshier or
Copyright © 2017-2018 Arm Limited
and labelled as such in comments in the individual source files. All
have been licensed under extremely permissive terms.
```

### Sun Microsystems

The header carries this notice in three forms, above the code each covers.

```
====================================================
Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.

Developed at SunPro, a Sun Microsystems, Inc. business.
Permission to use, copy, modify, and distribute this
software is freely granted, provided that this notice
is preserved.
====================================================
```

```
====================================================
Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.

Developed at SunSoft, a Sun Microsystems, Inc. business.
Permission to use, copy, modify, and distribute this
software is freely granted, provided that this notice
is preserved.
====================================================
```

```
====================================================
Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved.

Permission to use, copy, modify, and distribute this
software is freely granted, provided that this notice
is preserved.
====================================================
```

### Arm

The header carries this notice in two forms, above the code each covers. Both are under the MIT licence, whose text
is musl's above.

```
Copyright (c) 2017-2018, Arm Limited.
SPDX-License-Identifier: MIT
```

```
Copyright (c) 2018, Arm Limited.
SPDX-License-Identifier: MIT
```
