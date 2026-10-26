# Hokora bell pixel-density update

The bell sprite at `textures/pet/shrine_new/bell.png` is fitted to the original 72×82 px footprint, with chunkier clusters and a dark plum-brown outline matched more closely to the New Shrine lantern. The separate hanging bead ribbon remains unchanged.

The bell now swings from its top attachment and tilts with phone gravity, with a small impulse when `ring()` is triggered, using the same pendulum approach as the lanterns. The change is limited to the New Shrine; the regular shrine bell remains upright.

- `bell_density_preview.png` is the transparent, high-resolution source concept.
- `textures/pet/shrine_new/bell.png` is the runtime-sized sprite.
