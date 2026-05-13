# import io
# import json
# import torch
# import torch.nn as nn
# from torchvision import transforms, models
# from PIL import Image
# from fastapi import FastAPI, File, UploadFile, HTTPException
# import uvicorn

# app = FastAPI(title="Cropsify Disease Detection")

# # ── Load class names ────────────────────────────────────────────────────────────
# with open("class_names.json") as f:
#     CLASS_NAMES: list[str] = json.load(f)

# NUM_CLASSES = len(CLASS_NAMES)  # 51

# # ── Load model ──────────────────────────────────────────────────────────────────
# def _build_and_load():
#     checkpoint = torch.load("cropsify_model.pth", map_location="cpu", weights_only=False)

#     if not isinstance(checkpoint, dict):
#         # Saved as a full model object
#         return checkpoint

#     # Extract state dict from checkpoint or plain state dict
#     if "state_dict" in checkpoint:
#         state = checkpoint["state_dict"]
#     elif "model_state_dict" in checkpoint:
#         state = checkpoint["model_state_dict"]
#     else:
#         state = checkpoint

#     # Try ResNet18 first (matches ~43 MB), fall back to ResNet50
#     for build_fn in [models.resnet18, models.resnet50]:
#         m = build_fn(weights=None)
#         m.fc = nn.Linear(m.fc.in_features, NUM_CLASSES)
#         try:
#             m.load_state_dict(state, strict=True)
#             return m
#         except RuntimeError:
#             continue

#     raise RuntimeError("Could not load cropsify_model.pth into ResNet18 or ResNet50.")

# model = _build_and_load()
# model.eval()

# # ── Preprocessing ───────────────────────────────────────────────────────────────
# _transform = transforms.Compose([
#     transforms.Resize((224, 224)),
#     transforms.ToTensor(),
#     transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
# ])

# # ── Status classifier ───────────────────────────────────────────────────────────
# def _status(label: str) -> str:
#     lo = label.lower()
#     if "healthy" in lo or "fresh" in lo:
#         return "healthy"
#     severe = ["blight", "blast", "rust", "virus", "mosaic", "greening"]
#     return "danger" if any(k in lo for k in severe) else "warning"

# # ── Label formatter ─────────────────────────────────────────────────────────────
# def _format(label: str) -> str:
#     """'Potato___Late_blight' -> 'Potato Late Blight'"""
#     clean = label.replace("___", " ").replace("_", " ").replace(",", "")
#     return " ".join(w.capitalize() for w in clean.split() if w)

# # ── Predict endpoint ────────────────────────────────────────────────────────────
# @app.post("/predict")
# async def predict(file: UploadFile = File(...)):
#     if not (file.content_type or "").startswith("image/"):
#         raise HTTPException(status_code=400, detail="Uploaded file must be an image.")

#     data = await file.read()
#     try:
#         image = Image.open(io.BytesIO(data)).convert("RGB")
#     except Exception:
#         raise HTTPException(status_code=400, detail="Cannot decode image.")

#     tensor = _transform(image).unsqueeze(0)

#     with torch.no_grad():
#         probs = torch.softmax(model(tensor), dim=1)
#         confidence, idx = probs.max(1)

#     raw_label = CLASS_NAMES[idx.item()]
#     return {
#         "disease":    _format(raw_label),
#         "raw_label":  raw_label,
#         "confidence": round(confidence.item() * 100, 1),
#         "status":     _status(raw_label),
#     }

# @app.get("/health")
# def health():
#     return {"status": "ok", "classes": NUM_CLASSES}

# if __name__ == "__main__":
#     uvicorn.run(app, host="0.0.0.0", port=8000)
import io
import json
import torch
import torch.nn as nn
from torchvision import transforms
from PIL import Image
from fastapi import FastAPI, File, UploadFile, HTTPException
import timm
import uvicorn

app = FastAPI(title="Cropsify Disease Detection")

# ── Load class names ────────────────────────────────────────────────────────────
with open("class_names.json") as f:
    CLASS_NAMES: list[str] = json.load(f)

NUM_CLASSES = len(CLASS_NAMES)
print(f"✅ Loaded {NUM_CLASSES} classes")

# ── Build & load EfficientNet-B3 ────────────────────────────────────────────────
def _build_and_load():
    # Build EfficientNet-B3 — must match training architecture exactly
    m = timm.create_model('efficientnet_b3', pretrained=False, num_classes=NUM_CLASSES)

    # Load weights
    checkpoint = torch.load("cropsify_model.pth", map_location="cpu", weights_only=False)

    # Handle different save formats
    if isinstance(checkpoint, dict):
        if "model_state_dict" in checkpoint:
            state = checkpoint["model_state_dict"]
        elif "state_dict" in checkpoint:
            state = checkpoint["state_dict"]
        else:
            state = checkpoint   # plain state dict
    else:
        # Saved as full model — extract state dict
        state = checkpoint.state_dict()

    m.load_state_dict(state, strict=True)
    m.eval()
    print(f"✅ EfficientNet-B3 loaded — {NUM_CLASSES} classes")
    return m

model = _build_and_load()

# ── Preprocessing — must match val_transform from training ─────────────────────
_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std =[0.229, 0.224, 0.225]
    ),
])

# ── Status classifier ───────────────────────────────────────────────────────────
def _status(label: str) -> str:
    lo = label.lower()
    if "healthy" in lo or "fresh" in lo:
        return "healthy"
    severe = ["blight", "blast", "rust", "virus", "mosaic",
              "greening", "smut", "wilt", "rot"]
    return "danger" if any(k in lo for k in severe) else "warning"

# ── Label formatter ─────────────────────────────────────────────────────────────
def _format(label: str) -> str:
    """'rice_Bacterialblight' -> 'Rice Bacterialblight'"""
    clean = label.replace("___", " ").replace("_", " ").replace(",", "")
    return " ".join(w.capitalize() for w in clean.split() if w)

# ── Predict endpoint ────────────────────────────────────────────────────────────
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if not (file.content_type or "").startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image.")

    data = await file.read()
    try:
        image = Image.open(io.BytesIO(data)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Cannot decode image.")

    tensor = _transform(image).unsqueeze(0)

    with torch.no_grad():
        probs      = torch.softmax(model(tensor), dim=1)
        top5_probs, top5_idxs = probs.topk(5, dim=1)

    # Top prediction
    top_idx   = top5_idxs[0][0].item()
    top_prob  = top5_probs[0][0].item()
    raw_label = CLASS_NAMES[top_idx]

    # Top 5 list
    top5 = [
        {
            "disease":    _format(CLASS_NAMES[top5_idxs[0][i].item()]),
            "raw_label":  CLASS_NAMES[top5_idxs[0][i].item()],
            "confidence": round(top5_probs[0][i].item() * 100, 1),
            "status":     _status(CLASS_NAMES[top5_idxs[0][i].item()])
        }
        for i in range(5)
    ]

    return {
        "disease":    _format(raw_label),
        "raw_label":  raw_label,
        "confidence": round(top_prob * 100, 1),
        "status":     _status(raw_label),
        "top5":       top5
    }

@app.get("/health")
def health():
    return {
        "status":  "ok",
        "classes": NUM_CLASSES,
        "model":   "EfficientNet-B3"
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)