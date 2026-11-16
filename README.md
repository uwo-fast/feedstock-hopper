# feedstock-hopper

> A parametric, printable bulk hopper for pellets and shredded regrind, with
> quick-release couplings and a small adapter per machine.

[![check](https://github.com/uwo-fast/feedstock-hopper/actions/workflows/check.yml/badge.svg)](https://github.com/uwo-fast/feedstock-hopper/actions/workflows/check.yml)
[![Software: GPL-3.0-or-later](https://img.shields.io/badge/Software-GPL--3.0--or--later-blue.svg)](LICENSES/GPL-3.0-or-later.txt)
[![Hardware: CERN-OHL-S-2.0](https://img.shields.io/badge/Hardware-CERN--OHL--S--2.0-orange.svg)](LICENSES/CERN-OHL-S-2.0.txt)
[![Contributions welcome](https://img.shields.io/badge/Contributions-welcome-brightgreen.svg)](https://github.com/uwo-fast/.github/blob/main/CONTRIBUTING.md)

## Overview

A gravity bulk hopper sized from what it has to pass, not from a capacity. You
state the feedstock (virgin pellets or shredded regrind) and the largest
particle, and the funnel angle, outlet and bin follow from bulk-solids flow
rules; capacity is whatever that leaves, and every render reports it.

It is modular at three [interfaces](docs/interfaces.md): the body twists into a
bolted-down hub (A), an outlet twists into the hub's other end (B, varies with
the hose or throat it feeds), and the hub bolts to a plate (C, varies with the
machine). A new machine needs a plate and perhaps an outlet, not a new hopper.
The machine's own feed opening is a registry row, and the report checks the
whole path against it.

**Used on:**
- **The GreenBoy3D pellet extruder on a Prusa MK3S**, in service in the lab,
  feeding the toolhead through its 1 m conveyor tube from the MK3S frame mount.
  The machine and its firmware are in
  [`uwo-fast/Prusa-Firmware-GB3DPE`](https://github.com/uwo-fast/Prusa-Firmware-GB3DPE).
- **A filament recycling extruder**, planned: an outlet that bolts to the
  extruder barrel's feed pad.

**Status.** Printed and in service. Every part compiles and holds its asserts
under `just check`, and geometry is regression-tested against a committed
baseline. The funnel angles are design targets the built hopper appears to
satisfy, not measurements; open work is in the
[issues](https://github.com/uwo-fast/feedstock-hopper/issues).

## Repository layout

- `cad/hopper/` -- the hopper: body, cap, hub, outlet, the feedstock, hose and
  target registries, and the plate in its universal, MK3S-frame and panel
  variants
- `docs/` -- interfaces, design notes, feedstock, loads and printing
- `dev/` -- the design log and the review of the imported design
- `examples/` -- one file per configuration, each rendering standalone
- `scripts/`, `tests/` -- geometry regression harness and its baseline

## Getting started

Requires [OpenSCAD](https://openscad.org/) (tested on 2021.01),
[just](https://github.com/casey/just), and
[`bayonet-lock-scad`](https://github.com/CameronBrooks11/bayonet-lock-scad) at its
`v0.12.0` tag (0.9.1 or later is required), which `scadman.lock` pins. With
[scadman](https://github.com/CameronBrooks11/scadman) installed, run `just setup`, which
puts it in `.scadman/env/`, where every recipe looks first. Without scadman, install it as
an OpenSCAD library at that tag:

```sh
git clone https://github.com/CameronBrooks11/bayonet-lock-scad \
  ~/.local/share/OpenSCAD/libraries/bayonet-lock-scad
git -C ~/.local/share/OpenSCAD/libraries/bayonet-lock-scad checkout v0.12.0
```

```sh
just            # list recipes
just check      # compile every part at every size, any diagnostic fails
just geom       # check rendered geometry against the committed baseline
just render     # write STLs for every part and size to build/
just edit       # open the assembly in the OpenSCAD GUI Customizer
```

The design is driven from `cad/hopper/pellet_hopper.scad`, which holds every
tunable parameter and hands them to the part modules. Pick a part with
`render_part`, a footprint with `hopper_size`, and what it will hold with
`feedstock_type`.

The funnel angle is an input, not a consequence. Set `funnel_angle` in degrees
from horizontal and the drop is solved from it; capacity is then whatever falls
out, and is echoed on every render along with a build-volume fit report. The
angle is measured on the **diagonal corner**, which on a rectangular funnel runs
further out than either flat face over the same drop and is therefore the
shallowest surface and the one pellets bridge on. Each feedstock carries the
shallowest angle it will still flow at, and a render below it is an error rather
than a quiet under-performing hopper.

Note that the presets are named for their footprint rather than a capacity. The
imported design worked the other way round -- capacity first, wall angle
whatever was left -- which is how it ended up at 27 to 36 degrees at the corner.

Each of the other files under `cad/hopper/` defines one part or one concern and
renders on its own, so you can open `hopper_hub.scad` directly and iterate on
the hub without the rest of the model in the way.

`examples/` holds worked configurations that drive the modules directly rather
than through the Customizer: the two feedstocks side by side, each split into
the segments its funnel height demands, and the MK3S frame mount with the hub
and outlet around it. They are covered by `just check`, so they cannot drift
away from the API they demonstrate.

`just geom` exists because OpenSCAD does not emit STL facets in a stable order,
so a mesh cannot be compared by hash. It compares signed volume, bounding box
and triangle count instead, which is enough to prove a refactor changed
nothing. Re-baseline with `just geom-baseline` only after an intended geometry
change.

## Documentation

- [Interfaces](docs/interfaces.md) -- the three couplings, and what a new machine needs
- [Design notes](docs/design-notes.md) -- why the geometry is the way it is, where the numbers came from, and known limits
- [Feedstock](docs/feedstock.md) -- measured bulk density and provenance
- [Printing and assembly](docs/printing.md) -- parts, orientations, hardware, order
- [Load cases](docs/loads.md) -- hand calculations and what they do not cover
- [Design log](https://github.com/uwo-fast/feedstock-hopper/blob/main/dev/design-log.md) and
  [review of the imported design](https://github.com/uwo-fast/feedstock-hopper/blob/main/dev/hopper-design-review.md)

## Contributing

Contributions are welcome. See the organization
[contribution guide](https://github.com/uwo-fast/.github/blob/main/CONTRIBUTING.md).

## Citation

If you use this project in your work, please cite it. Use the **Cite this
repository** button on GitHub, or see [`CITATION.cff`](https://github.com/uwo-fast/feedstock-hopper/blob/main/CITATION.cff).

## Acknowledgements

The bulk hopper was initially designed by [Hadden Christ](https://github.com/HaddenChrist),
whose body, roof mount, cap and bayonet coupling are the basis of `cad/hopper/`.

## License

Copyright © 2026 feedstock-hopper and its contributors.

This project is free software: you may redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later version.
Hardware design files and the outputs generated from them are licensed instead
under [CERN-OHL-S-2.0](LICENSES/CERN-OHL-S-2.0.txt), and the parametric CAD source
under both. See [`LICENSING.md`](LICENSING.md) for what applies where, and the
organization
[licensing policy](https://github.com/uwo-fast/.github/blob/main/LICENSING.md) for
why.

This project is not affiliated with GreenBoy3D or Prusa Research.

## Contact

Maintained by the [FAST research group](https://uwo-fast.github.io/). For
research collaboration inquiries, contact Dr. Joshua Pearce
(<joshua.pearce@uwo.ca>).
