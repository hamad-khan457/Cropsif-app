"""
Run this once to identify the model architecture:
    python inspect_model.py
"""
import torch

ckpt = torch.load("cropsify_model.pth", map_location="cpu", weights_only=False)

print("=== TYPE ===")
print(type(ckpt))

if isinstance(ckpt, dict):
    print("\n=== TOP-LEVEL KEYS ===")
    for k in list(ckpt.keys())[:10]:
        v = ckpt[k]
        print(f"  {k!r:40s}  {type(v).__name__}")

    # Which key holds the state dict?
    state = None
    for candidate in ("state_dict", "model_state_dict", "model"):
        if candidate in ckpt:
            inner = ckpt[candidate]
            if isinstance(inner, dict):
                state = inner
                print(f"\nState dict found under key: {candidate!r}")
                break
    if state is None:
        state = ckpt
        print("\nUsing checkpoint itself as state dict.")

    keys = list(state.keys())
    print(f"\n=== FIRST 15 STATE DICT KEYS ({len(keys)} total) ===")
    for k in keys[:15]:
        print(f"  {k:60s}  {list(state[k].shape)}")

    # DataParallel check
    if keys[0].startswith("module."):
        print("\n*** DataParallel prefix detected ('module.') ***")

    # Output layer shape
    for k in keys:
        if any(x in k for x in ("fc.weight", "classifier.weight", "head.weight")):
            print(f"\n=== OUTPUT LAYER: {k} -> {list(state[k].shape)} ===")

else:
    print("\n=== FULL MODEL (not a state dict) ===")
    print(ckpt)
