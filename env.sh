# source env.sh  — desde la raiz del repositorio
# Hace importables:  unet_ag.*        (modelo propuesto, codigo/unet_ag)
#                    schiffner_das.*  (port Fd-F, codigo/schiffner_das)
_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="${_ROOT}/codigo:${PYTHONPATH:-}"
echo "PYTHONPATH: ${_ROOT}/codigo"
