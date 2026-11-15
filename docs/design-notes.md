# Design notes

Why the geometry is the way it is, and where the numbers came from. Open work is
in the [issues](https://github.com/uwo-fast/feedstock-hopper/issues).

## Funnel angle is measured on the diagonal corner

On a rectangular funnel the corner runs further out than either flat face over
the same drop, so it is always the shallowest surface. Pellets bridge on the
shallowest surface, not the average one, so constraining a face leaves the
corner well under target -- the imported design sat at 32-50 degrees on its
faces but 27-36 degrees at the corner.

A rectangular bin also cannot hold equal X and Y angles for one drop, so a
single "wall angle" has to name a surface. The corner is the honest choice: set
it, and both faces come out steeper.

Hopper literature usually quotes the angle from **vertical**; ours is from
**horizontal**, which is 90 minus theirs. 60 degrees here is 30 degrees from
vertical.

## Feedstock minimum angles: 60 degrees virgin, 70 degrees regrind

Design targets from general bulk-solids practice, **not measurements**. The
critical mass-flow angle depends on the material _and_ on the wall friction of
the surface it slides on [J], so a printed wall is not interchangeable with the
steel these figures assume. Regrind is set steeper because irregular flake nests
and bridges where free-flowing pellets do not [W].

Treat these as provisional. A hopper that bridges in service wants a measured
wall friction angle against an actual printed surface, not a nudge to these.

## Bulk densities: 0.62 kg/L virgin (assumed), 0.489 kg/L regrind (measured)

Pellet bulk density spans roughly 450-850 kg/m3 across resin types [C]; virgin
PLA sits near the middle of that. Regrind flake is markedly lighter and its
density is variable rather than a property [W] -- which is exactly why the
regrind figure is now **measured** rather than assumed: 0.489 kg/L on our own
shred. See [`feedstock.md`](feedstock.md). Virgin is still the general-practice
0.62 and worth measuring the same way if it ever becomes the main feedstock.

These only affect the reported capacity, never the geometry. Every capacity
figure in this repo inherits their uncertainty.

## `min_wall` is perpendicular material, compensated on the corner

Wall thickness is applied by insetting the inner surface horizontally, but on a
face sloped at theta the material perpendicular to it is only `inset *
sin(theta)`. The imported design applied 3 mm horizontally, which is 1.61 mm of
real material on the 10 kg funnel.

The inset is sized on the corner angle -- the shallowest surface -- so nothing
finishes thinner than asked; flat faces and the vertical bin come out thicker.
One inset for the whole profile also keeps every inner surface parallel to its
outer, so the funnel meets the bin with no internal ledge to catch pellets.

Verified on the rendered mesh: at the funnel corner a
1.44 mm sphere sits entirely inside the wall and a 1.56 mm one breaks out,
bracketing the 3.00 mm target.

## Inner corner radii must follow the wall inward

An inner radius clamped at a floor is no longer a parallel offset, and it thins
the wall exactly at the corner that is already shallowest -- about 8% in the
imported geometry. So the radii subtract the inset and the geometry **asserts**
the result stays at or above 0.8 mm, roughly two 0.4 mm extrusions, rather than
clamping quietly.

## Physical rules live in functions, not in comments

Anything the geometry depends on physically -- how much room a particle needs,
how steep a wall has to be, how much a litre of feedstock weighs -- is a
function or a registry row in `hopper_specs.scad`, never a bare number with a
note beside it.

That lets the same rule be read both ways. Give it a requirement and it sizes
the geometry: `design_particle_size = 5` with regrind selected demands a 50 mm
outlet, and the build refuses to render if the coupling cannot provide one. Give
it the geometry and it reports the capability: every render echoes the largest
particle the whole path will actually pass, which is the narrowest section, not
the one you were thinking about.

That is how the coupling came to be 58 mm rather than 44. The requirement drove
it; the assert refused the old size; the resize followed.

## Bayonet joint uses `bayonet-lock-scad` [B]

The joint was hand-rolled with rectangular tabs. It now comes from our own
`bayonet-lock-scad`, which brings a hard end stop, a keyed pattern, and a
thicker socket wall outside the channel. `scadman.lock` pins it to the `v0.12.0` tag (it
was pinned by commit `85c43ae`, v0.11.0, before the library published tags);
at least 0.9.1 is required, which fixed the z alignment of the two halves when
`entry_depth` is not half of `part_height`, exactly the case used here.

The decisions behind how it is used, and how they were verified, are in the
[design log](https://github.com/uwo-fast/feedstock-hopper/blob/main/dev/design-log.md).

**Anti-rotation is not a screw.** A radial self-tapping M4 into a pocket in the
neck was tried and removed. Two sockets are not the same case, and treating them
as a symmetric pair was the mistake: disengaging a bayonet means rotating back
through `sweep_angle` and _then_ travelling `entry_depth` axially, and gravity
sits on opposite sides of that travel at each end. At the **upper** socket the
body must be lifted 12 mm against its own loaded 4.24 kg, so rotation alone
releases nothing and the screw guarded a failure gravity already prevents. At
the **lower** socket the outlet simply drops out, and the hub is an open bore,
so the hopper would drain through it.

The lower screw was also unbuildable as drawn: it could only exit on the hub
skirt's 45 degree cone, where no head seats.

So the outlet's retention rests on the bayonet, and on the hose thread that
screws into it. It has held in service; strain-relieving the hose near the outlet is still the
cheap insurance, because it removes the torque instead of resisting it.

## The fed machine's opening caps the system

The machine's own feed opening is the last section of the path, and it is
metal and not ours to size, so it is a target registry row rather than a
number in the check. On the GreenBoy3D toolhead it was taken off the vendor
STEP files: **dia 18.30 mm, centred on the extruder axis**, identical in both
sliding-pit parts at z 9.5 and 10.1. That is where material drops onto the
screw.

Against the parallel rule that gives a system ceiling of **6.1 mm for virgin
pellets and 4.6 mm for regrind flake** -- below the 5 mm the build is otherwise
specified for. Our own sections are all sized for 5 mm, which is harmless
headroom, but the assembled machine tops out lower and the spec echo now says
so. Leaving the machine's opening out of the path would report a system limit
we do not have.

It also explains the 3 mm sieve the feedstock is currently prepared to: the bore
is 6.1x the sieve, comfortably inside, rather than an arbitrary choice.

## Build volume 250 x 210 x 210 mm

The Original Prusa i3 MK3S envelope [P], and the largest printer available here
for the foreseeable future. Reported on every render; `require_printable` turns
it into a hard error. It is on, and every preset passes with it.

## Known limits

Built, verified and working; nothing to do unless something changes.

- **The coupling is past the bayonet library's exercised range.** Its examples
  use `interface_radius` of 15 or less and its angular corrections are tuned for
  `pin_radius` of 3.0 or less; we run 29.15 at 3.0. Rendering shows it seats,
  captures and keys, but the detent's snap-past grew fourfold with the radius,
  because it is placed by angle. Re-verify if the coupling grows again.
- **Bin wall creep.** The safety factors in [`loads.md`](loads.md) are against
  short-term yield and say little about months of sustained load on a
  thermoplastic in a warm enclosure. The failure would be slow bowing, not a
  break. In order of cost: raise `min_wall`, add perimeters, add a rib at
  mid-height.

## References

- [C] Conair -- _What is Bulk Density?_ <https://www.conairgroup.com/resources/resource/what-is-bulk-density/>
- [J] Jenike & Johanson -- _Designing bulk material storage and feeding systems_ <https://jenike.com/designing-end-to-end-bulk-material-storage-and-feeding-systems-hoppers-silos-mass-flow-feeders/>
- [W] Wijay Systems -- _Plastic pellet conveying systems_ <https://wijaysystems.com/plastic-pellet-conveying-systems/>
- [P] Prusa Research -- _Original Prusa i3 MK3S+_ <https://www.prusa3d.com/product/original-prusa-i3-mk3s-3d-printer-3/>
- [B] `bayonet-lock-scad` <https://github.com/CameronBrooks11/bayonet-lock-scad>
- GreenBoy3D toolhead: [`GB3DPE.md`](https://github.com/uwo-fast/Prusa-Firmware-GB3DPE/blob/MK3/GB3DPE.md) in the firmware repo.
