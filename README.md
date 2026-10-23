# UNet-AG: B-mode de ultrasonido 2D desde una sola onda plana

Modelo propuesto en la tesis de maestría de **Héctor David De Lara Berumen**
(CIMAT, 2026), empaquetado por separado: código, los tres modelos entrenados,
el entrenamiento y el evaluador. Para usar el modelo no hace falta clonar el
repositorio completo de la tesis.

> **UNet-AG** (*B1-v5_anchor05*). Red UNet con compuertas de atención
> condicionadas por un mapa de profundidad derivado del F-number dependiente de
> la frecuencia (Fd-F) de Schiffner, que refina de forma residual el adjunto con
> apodización Fd-F de **una sola onda plana**. 3 529 366 parámetros y
> **749 GFLOP** por imagen.

La comparación completa con los demás métodos (DAS y Fd-F de 75 ondas planas y
el método de difusión DRUS) está en el repositorio de la tesis,
[hectorddlb/UNet-AG_Tesis](https://github.com/hectorddlb/UNet-AG_Tesis).

---

## Estructura

| Carpeta | Contenido |
|---|---|
| `codigo/unet_ag/` | El modelo: API de inferencia y orden `unetag`, red, operador físico, cargadores de datos, pérdidas, métricas, entrenamiento, evaluadores y pruebas |
| `codigo/schiffner_das/` | Port en PyTorch del conformador Fd-F de Schiffner: lo usan el operador físico del modelo y la generación de los objetivos de supervisión |
| `checkpoints/` | Los tres modelos entrenados, `anchor05_{s42,s1,s2}.pt` (41 MB cada uno) |
| `entrenamiento/` | Registros de entrenamiento y evaluación de las tres semillas y los trabajos SLURM con los que se entrenaron |
| `datos/` | Generación del conjunto Field II, obtención de PICMUS y generación de los objetivos de supervisión |

---

## Instalación

```bash
git clone git@github.com:hectorddlb/Us-BMode_UNet-AG.git
cd Us-BMode_UNet-AG
python -m venv .venv && source .venv/bin/activate
pip install -e ".[todo]"           # instala los paquetes y la orden `unetag`
```

`pip install -e .` deja importables `unet_ag` y `schiffner_das` desde cualquier
directorio. Si prefieres no instalar nada, `source env.sh` pone `codigo/` en el
`PYTHONPATH` y `pip install -r requirements.txt` cubre las dependencias.

> **Instalación en máquinas sin internet** (nodos de cómputo, entornos aislados).
> Por omisión `pip` construye el paquete en un entorno aislado y descarga
> `setuptools` para ello, lo que falla sin red. Si ya tienes `setuptools` en el
> entorno, evita ese paso:
>
> ```bash
> pip install --no-build-isolation --no-deps -e .
> ```

## Uso

```bash
unetag info                  # comprueba que carga (3 529 366 parámetros)

# reconstruir un phantom de PICMUS
unetag reconstruct --picmus resolution_distorsion_expe_dataset_rf.hdf5 \
                   --out bmode.png --save-adjoint inicial.png

# reconstruir RF propio
unetag reconstruct --rf mis_datos.npy --geometry mi_geometria.json --out bmode.png
```

Desde Python:

```python
from unet_ag.inference import UNetAG, Geometry

modelo = UNetAG.from_pretrained()                    # semilla 42
bmode  = modelo.reconstruct_picmus("...expe_dataset_rf.hdf5")   # (612, 388) en [0,1]

# o con RF propio
geom  = Geometry(n_elements=128, n_samples=1527, pitch_m=300e-6,
                 sampling_freq_hz=20.832e6, speed_of_sound=1540.0)
bmode = modelo.reconstruct(rf, geom)                 # rf: (n_samples, n_elements)
```

Los pesos viven en `checkpoints/` y se localizan solos desde un clon; fuera de
él, indica la carpeta con `UNETAG_CHECKPOINTS=/ruta/a/checkpoints` o con
`--ckpt`. El modelo principal es la semilla 42; las cifras publicadas son la
media de las tres.

---

## Resultados

Protocolo de evaluación sobre los cuatro fantomas de PICMUS: envolvente → 60 dB
de rango dinámico → [0, 1] sobre la rejilla de 612 × 388 puntos. UNet-AG como
media ± desviación estándar poblacional de las semillas 42, 1 y 2; como
referencia, el DAS de una onda plana con apertura completa.

| Fantoma | Métrica | DAS 1 PW | UNet-AG | Semillas 42 / 1 / 2 |
|---|---|---|---|---|
| Experimental, contraste | gCNR ↑ | 0.528 | **0.721 ± 0.058** | 0.790 / 0.724 / 0.647 |
| Experimental, contraste | CNR (dB) ↑ | −3.974 | **−3.692 ± 0.222** | −3.756 / −3.925 / −3.393 |
| Experimental, resolución | FWHM lateral (mm) ↓ | 3.728 | **2.765 ± 0.245** | 2.755 / 3.070 / 2.471 |
| Experimental, resolución | FWHM axial (mm) ↓ | 1.318 | 1.857 ± 0.024 | 1.882 / 1.863 / 1.825 |
| Simulado, contraste | gCNR ↑ | 0.558 | 0.564 ± 0.006 | 0.558 / 0.572 / 0.563 |
| Simulado, contraste | CNR (dB) ↑ | 0.744 | 1.458 ± 0.180 | 1.254 / 1.429 / 1.691 |
| Simulado, resolución | FWHM lateral (mm) ↓ | 1.236 | 1.487 ± 0.157 | 1.376 / 1.710 / 1.376 |
| Simulado, resolución | FWHM axial (mm) ↓ | 0.728 | 1.682 ± 0.225 | 1.521 / 2.000 / 1.525 |

En los escenarios experimentales, la detectabilidad de lesión (gCNR) mejora un
**36.6 %** respecto del DAS de una onda plana, y el contraste y la resolución
lateral mejoran en cada una de las tres semillas por separado. En todos los
fantomas se resuelven todos los alambres (20 de 20 en simulación y 7 de 7 en el
experimental).

### Reproducir las cifras del modelo

Requiere PICMUS (ver [`datos/README.md`](datos/README.md)):

```bash
python -m unet_ag.eval.evaluate_picmus \
    --ckpt checkpoints/anchor05_s42.pt --model_type b1_v4 \
    --picmus_root /ruta/a/PICMUS --mode both --phantom both \
    --out eval_picmus_s42.csv --device cuda
```

Las columnas `b1_*` del CSV coinciden con las de la tabla. Las columnas
`das_1pw_*` de este evaluador corresponden al **adjunto Fd-F** (la entrada de
la red), no al DAS de apertura completa de la tabla. Los registros de
`entrenamiento/registros/<semilla>/` se produjeron con este mismo evaluador
sobre PICMUS, Field II (`unet_ag.eval.evaluate_fieldii`) y CUBDL
(`unet_ag.eval.evaluate_cubdl`).

---

## Entrenamiento

Requiere el conjunto Field II y los 287 objetivos de supervisión Schiffner Fd-F
de 75 ondas planas (detalles en [`datos/README.md`](datos/README.md)).

```bash
python -m unet_ag.train.b1_v5_pulse_aug \
    --data_root  "/ruta/a/field_ii_data_multiangle" \
    --target_root /ruta/a/targets_schiffner_75pw \
    --output_dir  resultados/mi_corrida \
    --phantom_type points --anchor_weight 0.5 --epochs 20 --seed 42 \
    --device cuda
```

~9 h por semilla en una NVIDIA TITAN RTX de 24 GB. Los trabajos SLURM
equivalentes están en `entrenamiento/slurm/` y `entrenamiento/submit_anchor05_seeds.sh`
lanza las semillas 1 y 2 con su evaluación; conservan las rutas del clúster en
el que se ejecutaron y se reutilizan pasando las rutas por variables de entorno.

---

## Cita

```bibtex
@mastersthesis{DeLara2026,
  author  = {De Lara Berumen, Héctor David},
  title   = {Reconstrucción de imágenes de ultrasonido 2D en modo B desde datos
             crudos RF de una sola onda plana mediante una red UNet informada
             por el F-number dependiente de la frecuencia},
  school  = {Centro de Investigación en Matemáticas (CIMAT)},
  year    = {2026},
  address = {Zacatecas, México}
}
```

## Agradecimiento a trabajos previos

Este modelo se apoya en el F-number dependiente de la frecuencia de
**Schiffner (2021)**, las compuertas de atención de **Oktay et al. (2018)**, el
simulador **Field II** y el benchmark **PICMUS**.
