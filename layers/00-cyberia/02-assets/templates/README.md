# Homepage Dashboard Theme System Architecture

This directory defines the design system and asset split for the NFP Homepage Dashboard (`luffy:3007`).

## File Ownership Split

1. **`homepage-theme.css`**:
   - **Role**: Core Design System implementing `plan.md` ("Grandlix × One Piece Cyberpunk Dashboard — Vegapunk Records Edition").
   - **Contents**: Color tokens, typography (`Orbitron`, `Exo 2`, `Space Grotesk`), glassmorphism cards, Straw Hat Command Bar header, Egghead Island atmosphere, Den Den Mushi status snails, Vegapunk Records constellation, unwanted/wanted poster CSS effects, micro-animations, and `prefers-reduced-motion` rules.
   - **Rule**: Standard across all NFP hosts; modified only when updating the overall visual design system.

2. **`homepage-custom.css`**:
   - **Role**: Host & Local Overrides (`layers/50-cli-tui-programs/58-theming/templates/homepage-custom.css`).
   - **Contents**: User custom CSS overrides, specific display tweaks, local font-size tweaks, or temporary visual flags.
   - **Rule**: Injected after `homepage-theme.css` so custom styles take precedence without mutating the base theme.

## Font & Asset Vendoring

- All fonts are vendored 100% offline from `nixpkgs` (`google-fonts`) via `@font-face` definitions pointing to `/assets/fonts/`. Zero external Google Fonts `@import` or CDN requests are permitted.
- Avatar images are stored in `layers/00-cyberia/02-assets/png-ico/` and served locally under `/assets/images/`.
