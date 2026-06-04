extends Node

var almas_cosechadas: int = 0
const REQUISITO_DEVORADOR: int = 10

signal alma_cosechada(almas: int, requisito: int)
signal pacto_listo()

func cosechar_alma_directa() -> void:
	if almas_cosechadas < REQUISITO_DEVORADOR:
		almas_cosechadas += 1
		print("Alma absorbida. Progreso: ", almas_cosechadas, "/", REQUISITO_DEVORADOR)
		alma_cosechada.emit(almas_cosechadas, REQUISITO_DEVORADOR)
		if almas_cosechadas >= REQUISITO_DEVORADOR:
			print("¡EL PACTO DE SOMBRA ESTÁ LISTO!")
			pacto_listo.emit()

func consumir_almas() -> void:
	almas_cosechadas = 0
	alma_cosechada.emit(0, REQUISITO_DEVORADOR)

func almas_suficientes() -> bool:
	return almas_cosechadas >= REQUISITO_DEVORADOR

func obtener_almas() -> int:
	return almas_cosechadas
