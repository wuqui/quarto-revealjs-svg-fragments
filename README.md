# Quarto: SVG Fragments for Reveal.js

Quarto extension to inline SVGs and reveal Inkscape layers as Reveal.js fragments.

## Install

```bash
quarto add wuqui/quarto-revealjs-svg-fragments --no-prompt
```

## Usage (shortcode)

```markdown
{{< svg-frag file="img/layered.svg" start=0 class="fragment" effect="fade-in" >}}
```

- `file`: SVG path (required)
- `start`: starting index (default 0)
- `class`: base fragment class (default `fragment`)
- `effect`: reveal effect appended to class (optional)
- `reduced_motion`: `show-all` to disable fragments (optional)

## Notes

- Layers ordered by numeric suffix in `inkscape:label` if present; else by document order.
- If no layers, SVG is emitted unchanged.
- Extension contributes responsive SVG CSS for Reveal.js slides.

## Optional pre-process

Crop to drawing with Inkscape CLI wrapper:

```bash
lua src/crop_svg_to_drawing.lua img/source.svg img/source_cropped.svg
```

## License

MIT

