# Código

Dos paquetes Python. `pip install -e .` desde la raíz los instala (con la orden
`unetag`); `source env.sh` los pone en `PYTHONPATH` sin instalar.

## `unet_ag/` — el modelo

| Subpaquete | Contenido |
|---|---|
| `inference.py`, `cli.py` | API pública (`unet_ag.inference.UNetAG`) y orden `unetag` |
| `data/` | Lectores de RF (Field II, PICMUS, CUBDL), particiones y augmentación de pulso |
| `physics/` | Operador de medida `OpHFdf`, su envoltorio y el mapa de F-number |
| `models/` | UNet con compuertas de atención condicionadas y el envoltorio residual con inicialización en cero |
| `losses/` | Pérdida compuesta MSE + L1 + SSIM |
| `metrics/` | CNR, gCNR y FWHM por alambre |
| `train/` | Entrenamiento: `b1_v5_pulse_aug` es el punto de entrada; `b1_attention_gate`, `b1_v4_anchored` y `base_trainer` aportan la rejilla, la compresión logarítmica, la pérdida con ancla y el bucle de entrenamiento |
| `eval/` | Evaluadores sobre PICMUS, Field II y CUBDL, con sus máscaras |
| `tests/` | Pruebas de humo y de especificación |

Puntos de entrada:

```bash
unetag --help                                      # inferencia (unet_ag.inference.UNetAG)
python -m unet_ag.train.b1_v5_pulse_aug --help     # entrenamiento
python -m unet_ag.eval.evaluate_picmus  --help     # evaluación sobre PICMUS
python -m unet_ag.eval.evaluate_fieldii --help     # evaluación en dominio (Field II)
python -m unet_ag.eval.evaluate_cubdl   --help     # evaluación fuera de dominio (CUBDL)
```

Los evaluadores aceptan `--model_type b1_v4` para los checkpoints de este
modelo (la clase `B1V3Residual`, entrenada con el ancla L1).

## `schiffner_das/` — port del F-number dependiente de la frecuencia

Implementación en PyTorch del conformador en dominio de Fourier de Schiffner
(2021). El operador físico del modelo usa sus F-numbers, ventanas y
normalizaciones, y su `das_pw()` genera los objetivos de supervisión
(`datos/precompute_schiffner_targets_fieldii.py`).

⚠️ `das_pw()` acepta `tx_sign` y `tx_reference`. Los valores por defecto
(`-1.0`, `"edge"`) reproducen la convención del dataset original de Schiffner;
**para PICMUS y Field II la convención física es `tx_sign=+1.0,
tx_reference="origin"`**.
