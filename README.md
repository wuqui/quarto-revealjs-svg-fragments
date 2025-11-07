# Quarto: SVG Fragments for Reveal.js

Quarto extension to inline SVGs and reveal Inkscape layers as Reveal.js fragments.

## Install

```bash
quarto add wuqui/quarto-revealjs-svg-fragments --no-prompt
```

## Usage (shortcode)

```markdown
{{< svg-frag file="img/layered.svg" >}}
{{< svg-frag file="img/layered.svg" start=5 >}}
{{< svg-frag file="img/layered.svg" class="custom-fragment" >}}
```

- `file`: SVG path (required)
- `start`: starting fragment index (default 0)
- `class`: fragment class name (default `fragment`)

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

