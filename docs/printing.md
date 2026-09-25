# Printing and assembly

The shipping configuration: 202 × 202, two segments, regrind at 70°, mounted on
the MK3S frame. `just render` writes every part.

## Parts

| Part           | Qty | Size (mm)       | PETG     | Orientation                |
| -------------- | --- | --------------- | -------- | -------------------------- |
| body segment 0 | 1   | 173 × 173 × 205 | ~0.37 kg | **flip** — flange down     |
| body segment 1 | 1   | 202 × 202 × 205 | ~0.66 kg | as modelled                |
| cap            | 1   | 209 × 209 × 19  | ~0.22 kg | **flip** — top face down   |
| hub            | 1   | 95 × 95 × 36    | ~0.08 kg | as modelled                |
| plate (MK3S)   | 1   | 135 × 135 × 98  | ~0.33 kg | **flip** — plate face down |
| outlet         | 1   | 59 × 61 × 83    | ~0.06 kg | as modelled                |

About 1.7 kg of PETG all told. Segment 1 at 202 × 202 leaves 4 mm either side
on an MK3S bed, and the cap at 209 leaves half a millimetre — check first layer
placement rather than trusting it.

### Why those orientations

Measured, not guessed: downward-facing flat area above the bed, per part.

- **Segment 0** has 8 280 mm² of it — the split flange's underside, which is a
  12 mm horizontal ledge all the way round. Flipped, that lands on the bed and
  everything else slopes inward.
- **The cap** has 41 225 mm² — the whole cavity ceiling. Printed as modelled it
  would be one enormous unsupported span.
- **The MK3S plate** has 10 229 mm², mostly the plate underside outside the
  saddle's footprint. Flipped, the plate is on the bed and the saddle legs point
  up with the slot opening upward. It is the tallest thing in the list at 98 mm,
  because the saddle also stands the mount off the frame — see
  [`interfaces.md`](interfaces.md).
- **Segment 1 has none at all**, and the hub 67 mm². Both print as modelled.
- **The outlet** has about 1 000 mm², a narrow annulus where the cone meets the
  neck. Small enough to bridge; watch it on the first one.

## Settings

Print in the material and layer height you intend to keep: the layer lines are
the wall texture the funnel angle depends on.

Perimeters matter more than infill here. Everything structural in
[`loads.md`](loads.md) is bending in a thin wall, so shell thickness is what
carries it; the bin wall governs at a safety factor of 6.7 and creep is the
thing that factor does not cover. Four perimeters is a better spend than more
infill.

## Hardware

| Where            | Fastener                             | Notes                                                                                                |
| ---------------- | ------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| hub → plate      | 4 × M4 × 20 + nuts                   | straight through both; the nut seats in the hub's counterbore, which spotfaces the skirt's cone flat |
| split joint      | 6 × M4 × 20 + nuts                   | plus 2 × Ø4 dowels, which locate while the bolts clamp                                               |
| split joint seal | closed-cell foam tape, ~2 mm × 10 mm | one face only, inside the bolt circle                                                                |
| MK3S clamp       | 2 × M4 grub                          | pinch the frame; the saddle roof carries the weight                                                  |
| panel variant    | 4 × M4 + washers                     | **washers or a backing plate**, not bare heads on sheet                                              |

### The split joint seal

Closed-cell foam tape — EPDM or neoprene, around 2 mm thick and 10 mm wide —
run round one flange face inside the bolt circle. Deliberately a consumable
rather than a groove and an O-ring: what leaks here is flake dust rather than
liquid, printed flanges are never flat enough to seal metal-to-metal anyway,
and foam takes up that error where a hard seal would need the flatness it
cannot get. It also costs no geometry, so nothing has to be reprinted to
change it.

Compress it with the bolts, not beyond about half its thickness. The dowels set
the alignment, so the tape is not being asked to hold anything in place.

## Assembly order

1. Bolt the **hub** down to the **plate**: bolts up from under the plate, nuts
   into the hub's counterbores. There is 4 mm of flange under each seat.
2. Mount the plate: MK3S clamp over the frame's top edge and pinch, or bolt
   through the drilled panel. Panel hole is **Ø65**.
3. Twist the **outlet** up into the hub's lower socket.
4. Screw the **hose** into the outlet — it threads, the reinforcing rib is the
   thread. Right-handed, 0.2 mm clearance, both settled on a coupon. A different
   hose needs its fits found by trial.
5. Bolt the two **body segments** together, dowels first.
6. Turn the body back by the sweep angle, drop it into the hub, and turn it
   forward to seat.
7. **Cap** on last.

Steps 3 and 6 are quarter-turns by hand. That is the point of the couplings:
clearing a jam is twisting the outlet off, not undoing the assembly.
