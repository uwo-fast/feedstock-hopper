# Design log

Implementation records behind [`docs/design-notes.md`](../docs/design-notes.md):
how the bayonet library is used, why BOSL2 is not, and the OpenSCAD behaviour
the build depends on.

## Bayonet joint decisions

Four decisions worth recording:

**The locked position is `+sweep_angle`, not a common origin.** The library
README says instantiating both halves at a common origin gives the locked
position. Measured by intersecting the two halves, it does not: a common origin
is the _entry_ position, and for `turn_direction = "CCW"` locked is
`+sweep_angle`. At +25 degrees the halves seat with no interference and stay
captured with 99.6 mm3 of overlap when lifted by `entry_depth`; at 0 degrees
they lift straight out. `joint_neck()` is therefore authored pre-rotated, so the
body's nominal orientation is the seated one. Getting this wrong sits the bin 25
degrees skew to the roof -- and note the sign depends on `turn_direction`, so a
result measured for `CW` does not carry over. (The library's README was
corrected in 0.12.0, which also adds `bayonet_locked_rotation()`, `+sweep_angle`
for `CCW`.)

**The annular seat stays.** Both library halves span the same z range with
nothing to bottom out on, so the pins would carry the entire pellet load. The
mount keeps the flange top between the pellet bore and the socket bore as a
~430 mm2 land. Flat bearing there is well under 1 MPa; sphere-in-trough contact
would be tens of MPa, which does not break but beds in, and every 0.1 mm of
bed-in is 0.1 mm of new axial slop.

**The pattern is keyed.** Four evenly spaced pins give four identical locked
positions, and the bin is rectangular, so half of them mount it crosswise.
`key_angle = 15` pulls one pin off the even pattern; the resulting margin (15
degrees) clears the channel half-angle (8.1 degrees), and the smallest gap (75
degrees) clears the channel-merge floor (49.3 degrees).

**Three asserts are ours, not the library's.** It checks `sweep_angle` against
the raw pin gap but not the sweep's own tangency extension, so adjacent channels
can merge into a continuous slot -- no retention at all -- with every library
assert passing. It also never checks that the channel stays inside the part, or
that the shell is thinner than the interface radius; either failure yields a
plausible-looking part that does not lock. `hopper_joint()` asserts all three,
plus that the pellet bore does not cut into the pins. (Since 0.12.0 the library
refuses a sweep past its turn stop and a channel that breaks out of the bottom
face; ours stay, being stricter and covering the shell and the bore too.)

Verified in situ against the assembled mount, not just as two isolated halves:
the body seats at its nominal orientation, is captured when lifted (67 mm3 of
interference at 2 mm, 188 mm3 at 5 mm), and is blocked at 90 degrees, 180
degrees and 270 degrees, so the keying does prevent a crosswise mount. The
annular seat measures 213.5 mm3 over a 0.5 mm probe against 214.1 mm3 predicted,
so it is fully intact. Seated, there is 0.25 mm3 of interference across the
whole joint, unchanged at higher facet counts and therefore real rather than
faceting -- consistent with the library's detent sitting just short of the stop,
i.e. a light snap-past.

## No BOSL2

BOSL2's `prismoid(xang=)` is close to the feature we needed, but it does not
solve the shell problem -- its only true 3D offset uses `minkowski()` and its
own docs advise against it -- so an inner solid still has to be subtracted and
the `sin(theta)` compensation still has to be written by hand. Measured on this
geometry the plain-OpenSCAD version rendered slightly faster. Not worth a second
dependency and ~1850 global symbols for one `tan()`.

Revisit if rounded _horizontal_ edges (a bin rim, a funnel-to-bin fillet) or
threads are ever needed; those are genuinely painful to hand-roll.

## OpenSCAD behaviour this repo depends on

All established by compiling on 2021.01, not from documentation.

- `use <>` imports modules and functions but **not variables**, and is not
  transitive through another `use`. Hence accessor functions on every registry.
- A module reading a caller's global across `use <>` is a **warning, exit 0**,
  and silently coerces `undef` into geometry -- it ships a wrong part rather
  than failing. Hence `--hardwarnings` in the gate, and modules that never read
  globals.
- Customizer parameters must be top-level assignments in the **main file**,
  textually before the first `module` definition. Parameters in an included file
  never reach the panel. Hence the dummy-module fence in `pellet_hopper.scad`.
- A failing `assert()` exits 1 on STL export and writes no file, so asserts are
  usable as a gate -- but `-o file.echo` exits 0 through the same failure.
- A top-level `assert()` **statement cannot guard the assignments above it**.
  Assignments in a scope are evaluated before the statements run, so a bad
  parameter reaches the geometry first and reports as `undefined operation`
  from inside whatever function touched it -- three files from the cause, with
  the assert never firing. Put it in the assignment expression instead
  (`x = assert(cond, msg) value;`) or inside an accessor function. That is why
  every registry here validates its index in the accessor rather than beside it.
- A reversed range `[begin:end]` with `begin > end` reports only `DEPRECATED`,
  exits 0 **even under `--hardwarnings`**, and iterates backwards instead of
  empty. The gate greps for it. Soft diagnostics must therefore never echo the
  literal tokens `ERROR:`, `WARNING:` or `DEPRECATED:`.
- STL facets are not emitted in a stable order, so meshes cannot be compared by
  hash. `just geom` compares signed volume, bounding box and triangle count.
- **Two solids meeting on a coincident plane are not reliably one volume.** They
  union without complaint, render clean, pass every assert, and export an STL
  that slices as several separate objects. This has caught us three times -- the
  coupon's legs against its flange, the MK3S saddle against its plate, and the
  outlet's cone against its neck. Overlap anything that has to be one part, and
  never rely on faces just touching. `just check` now reads CGAL's volume count
  and fails a part that is not exactly one solid, which is the only reliable way
  to notice.
- A `use`d file's own top-level `$fn` is what **its** modules see, overriding
  whatever the consumer set. So no file here assigns `$fn` at top level except
  the driver; standalone previews pass `$fn` on the call instead. Getting this
  wrong is silent: the driver's facet setting simply has no effect, which is how
  a body render sat at 170 s regardless of what it was asked for.
