# feedstock-hopper — CAD tasks
# Requires: openscad (tested on 2021.01)

hopper := "cad/hopper/pellet_hopper.scad"

# Facet counts are set per purpose. The gate proves the model compiles and its
# asserts hold, which facet count has no bearing on, and the bayonet library's
# swept channels are expensive: a body is ~3 s at 32 facets and ~100 s at 120.
# geom uses a fixed count so the baseline is reproducible. Exported meshes use
# the file default, which is high enough for the bayonet fit to be real.
check_facets := "32"
geom_facets := "64"
build  := "build"

# Capacity preset index:label — must match _footprints in cad/hopper/pellet_hopper.scad
sizes := "0:150x150 1:175x175 2:202x202"

# The body prints as segments that bolt together, and each is its own
# render_part entry — so they need no special handling here, only listing. Must
# match `segments` in cad/hopper/pellet_hopper.scad.
body_parts := "body0 body1"

# Only the body and the cap change with the footprint preset. The hub, plate and
# outlet come out identical at all three, so the gate renders them once —
# sweeping them spent three renders proving one thing, and the driver's
# size-dependent asserts run on every render whichever part is asked for.
sized_parts := body_parts + " cap"
fixed_parts := "hub plate outlet"
parts := sized_parts + " " + fixed_parts
plate_variants := "mk3s universal panel"

default:
    @just --list

# Compile every part at every size, failing on any diagnostic. CI gate.
check:
    #!/usr/bin/env bash
    # The exit code alone is not a gate. Verified on OpenSCAD 2021.01: STL export
    # does return non-zero on a failing assert, and --hardwarnings promotes a
    # WARNING to non-zero. But a reversed range [begin:end] with begin > end only
    # says DEPRECATED, exits 0, and silently iterates BACKWARDS rather than empty,
    # so a loop over [1:n] with n <= 0 yields confident wrong geometry through a
    # clean exit. Both streams are therefore grepped as well.
    set -uo pipefail
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    fail=0

    # One place where a render is judged, so every case below is one line.
    #   solid  a printed part; must also come out as exactly one CGAL volume
    #   mesh   an assembly or example, where several solids are the point
    #   echo   a module file on its own. The function-only ones carry no
    #          geometry and STL export fails on an empty top-level object, where
    #          echo export exits 0 and the grep below is what catches problems.
    run() {
      local kind=$1 col1=$2 col2=$3 file=$4; shift 4
      local args=() d out rc vols
      for d in "$@"; do args+=(-D "$d"); done
      printf '  %-7s %-13s ' "$col1" "$col2"
      if [ "$kind" = echo ]; then
        out=$(openscad -o "$tmp/out.echo" "${args[@]}" "$file" 2>&1); rc=$?
        out="$out"$'\n'"$(cat "$tmp/out.echo")"
      else
        out=$(openscad --hardwarnings -o "$tmp/out.stl" "${args[@]}" "$file" 2>&1); rc=$?
      fi
      if [ "$rc" -ne 0 ] || grep -qE 'ERROR:|WARNING:|DEPRECATED:' <<<"$out"; then
        echo FAIL
        grep -hE 'ERROR:|WARNING:|DEPRECATED:|TRACE:' <<<"$out" | head -3 | sed 's/^/      /'
        [ "$rc" -ne 0 ] && [ -z "$out" ] && echo "      exit $rc"
        fail=1; return
      fi
      # CGAL reports one volume for the solid plus one for the space around it,
      # so a single printable part is exactly 2. More means the part is in
      # disconnected pieces -- which renders clean, passes every assert, and
      # slices as several objects. Two solids meeting on a coincident plane do
      # it, and it has caught us three times.
      vols=$(grep -oP 'Volumes:\s*\K\d+' <<<"$out" | head -1)
      if [ "$kind" = solid ] && [ -n "$vols" ] && [ "$vols" -ne 2 ]; then
        echo "FAIL  $vols volumes -- the part is in disconnected pieces"
        fail=1; return
      fi
      echo ok
    }

    for s in {{sizes}}; do
      i=${s%%:*}; label=${s##*:}
      for p in {{sized_parts}}; do
        run solid "$p" "$label" {{hopper}} "render_part=\"$p\"" "hopper_size=$i" \
          "render_facets={{check_facets}}"
      done
    done
    for p in {{fixed_parts}}; do
      run solid "$p" "any size" {{hopper}} "render_part=\"$p\"" "render_facets={{check_facets}}"
    done

    # Every plate variant. The driver's own defaults reach one of the three, so
    # the other two were compiled only as their standalone previews, never as
    # the driver assembles them.
    for v in {{plate_variants}}; do
      run solid plate "$v" {{hopper}} 'render_part="plate"' "plate_variant=\"$v\"" \
        "render_facets={{check_facets}}"
    done

    # Composite views at one size only: they render the same solids again, so
    # sweeping every size buys nothing but minutes.
    for p in assembly all; do
      run mesh "$p" default {{hopper}} "render_part=\"$p\"" "render_facets={{check_facets}}"
    done

    # Every module file, rendered on its own.
    for f in cad/*/*.scad; do
      run echo mod "$(basename "$f" .scad | sed 's/^hopper_//')" "$f" '$fn={{check_facets}}'
    done

    # Every part exists twice: the driver builds it, and its module file previews
    # it. Nothing forces those to agree, and when they drift the driver quietly
    # builds a different part from the one being looked at.
    printf '  %-7s %-13s ' "drift" "parts"
    if out=$(python3 scripts/drift.py --facets {{check_facets}} 2>&1); then
      echo ok
    else
      echo FAIL; sed 's/^/      /' <<<"$out"; fail=1
    fi

    # Examples set their own $fn as any consumer should, so the gate overrides
    # it -- at their preview quality a sweep takes minutes and proves nothing
    # extra, since this checks that they compile and their asserts hold.
    for f in examples/*.scad; do
      run mesh ex "$(basename "$f" .scad)" "$f" '$fn={{check_facets}}'
    done

    # `just geom` is not in CI, and rightly so: a zero-tolerance mesh compare
    # only holds for one OpenSCAD build. The side effect is that a stale
    # baseline says nothing at all -- 8c8cf87 changed the panel plate and left
    # the baseline describing the old geometry for ten days before anyone ran
    # `just geom`. Comparing commit dates costs nothing and closes that gap.
    #
    # A warning, never a failure: plenty of cad/ edits are comments or
    # formatting and move no geometry, so this cannot judge whether the
    # baseline is actually wrong -- only that it has not been looked at since.
    # Skipped silently without git history, which includes a shallow CI clone.
    if git rev-parse --git-dir >/dev/null 2>&1; then
      cad_at=$(git log -1 --format=%ct -- cad/ 2>/dev/null || true)
      base_at=$(git log -1 --format=%ct -- tests/geometry-baseline.json 2>/dev/null || true)
      if [ -n "$cad_at" ] && [ -n "$base_at" ] && [ "$cad_at" -gt "$base_at" ]; then
        echo
        echo "  note   cad/ has changed since the geometry baseline was written"
        echo "         ($(git log -1 --format=%cs -- cad/) vs $(git log -1 --format=%cs -- tests/geometry-baseline.json))."
        echo "         Run 'just geom'. If the change was intended, 'just geom-baseline'."
      fi
    fi

    exit $fail

# Render every part at every size to build/ as STL.
render:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{build}}
    for s in {{sizes}}; do
      i=${s%%:*}; label=${s##*:}
      for p in {{parts}}; do
        out={{build}}/hopper-$label-$p.stl
        echo "  -> $out"
        openscad -o "$out" -D "render_part=\"$p\"" -D "hopper_size=$i" {{hopper}}
      done
    done

# Open the assembly in the OpenSCAD GUI with the Customizer.
edit:
    openscad {{hopper}}

clean:
    rm -rf {{build}}

# Check rendered geometry against the committed baseline (see the script docstring).
geom:
    @python3 scripts/geom_stats.py --facets {{geom_facets}}

# Overwrite the geometry baseline. Only after an INTENDED geometry change.
geom-baseline:
    @python3 scripts/geom_stats.py --write --facets {{geom_facets}}
