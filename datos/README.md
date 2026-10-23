# Datos

Los conjuntos crudos no están en el repositorio por tamaño (~30 GB). Esta carpeta
contiene lo necesario para reconstruirlos o localizarlos, y para generar los
objetivos de supervisión del entrenamiento.

## Estructura esperada

```
<datasets>/
├── PICMUS/
│   └── database/
│       ├── simulation/{contrast_speckle,resolution_distorsion}/*.hdf5
│       └── experiments/{contrast_speckle,resolution_distorsion}/*.hdf5
└── field_ii_data_multiangle/
    ├── points/points_XXXX.mat      (300 phantoms, 75 ángulos c/u)
    └── cysts/cysts_XXXX.mat        (300 phantoms, 75 ángulos c/u)
```

## PICMUS

Benchmark público del *Plane-wave Imaging Challenge in Medical Ultrasound*
(IEEE IUS 2016). Descarga: <https://www.creatis.insa-lyon.fr/Challenge/IEEE_IUS_2016/>

Se usan los cuatro phantoms canónicos, cada uno con 75 ángulos en ±16°:
`simulation/{resolution_distorsion, contrast_speckle}` y
`experiments/{resolution_distorsion, contrast_speckle}`. Formato HDF5 según el
estándar UFF. El lector es `unet_ag.data.rf_loader.PICMUSLoader`; la orden
`unetag reconstruct --picmus` y `UNetAG.reconstruct_picmus()` aceptan
directamente uno de estos ficheros.

**PICMUS se reserva íntegramente para evaluación**: no interviene en el
entrenamiento en ningún momento.

## Field II

Conjunto de entrenamiento simulado: 600 phantoms (300 de reflectores puntuales
con 20 dispersores cada uno, 300 de inclusiones anecoicas con fondo de speckle y
10 quistes), simulados con 75 ángulos por phantom. El modelo se entrena con los
de reflectores puntuales (`--phantom_type points`).

Los scripts de generación están en `field_ii/`. Requieren
[Field II](https://www.field-ii.dk/) sobre MATLAB:

| Script | Función |
|---|---|
| `generate_training_data_multiangle.m` | Genera un phantom con sus 75 ángulos |
| `run_generation_multiangle.m` | Lanza la generación del conjunto completo |
| `generate_range_cluster.m` / `run_cluster_generation.m` | Variantes por rangos, para paralelizar en clúster |

Parámetros del transductor (replican PICMUS): `f_c` = 5.208 MHz, `f_s` =
20.832 MHz, 128 elementos con paso de 300 µm y ancho de 270 µm, altura de 5 mm
con foco en elevación a 20 mm, excitación de 2.5 ciclos, respuesta al impulso
gaussiana con 67 % de ancho de banda fraccional, `c` = 1540 m/s.

## Objetivos de supervisión

El modelo se entrenó contra **287 reconstrucciones Schiffner Fd-F de 75 ondas
planas** de los phantoms de reflectores puntuales, en
`<target_root>/points/<id>/compounded.npy`. Hay dos formas de obtenerlas:

- **Descargarlas**: están en el repositorio de la tesis,
  [`datos/targets_schiffner_75pw/`](https://github.com/hectorddlb/UNet-AG_Tesis/tree/main/datos/targets_schiffner_75pw)
  (262 MB).
- **Regenerarlas** a partir del conjunto Field II (días de cómputo en GPU):

  ```bash
  python datos/precompute_schiffner_targets_fieldii.py \
      --data_root  /ruta/a/field_ii_data_multiangle \
      --output_dir /ruta/a/targets_schiffner_75pw \
      --phantom_types points
  ```

  `--range_start` / `--range_end` reparten los phantoms entre trabajos de un
  arreglo SLURM.

⚠️ Este script reproduce los objetivos **tal como se usaron para entrenar** el
modelo publicado: llama a `das_pw()` con la convención de transmisión por
defecto (borde, −sin θ), no con la convención física de Field II (`tx_sign=+1`,
`tx_reference="origin"`), y por eso portan estelas laterales en los ángulos
inclinados. Se conservan así porque son la supervisión real de los checkpoints
de `checkpoints/`.

## CUBDL

Usado solo para la evaluación cruzada de dominio (`unet_ag.eval.evaluate_cubdl`).
No se incluye; disponible en <https://cubdl.jhu.edu/>. El subconjunto empleado
son las adquisiciones de onda plana con geometría compatible (~L7-4/L10-5).
