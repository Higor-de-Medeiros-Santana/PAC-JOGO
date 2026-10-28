extends Control

# FimJogo.gd
# Tela de fim de jogo com estatísticas finais.

@onready var _score_label: Label    = $VBox/ScoreLabel
@onready var _accuracy_label: Label = $VBox/AccuracyLabel
@onready var _rolls_label: Label    = $VBox/RollsLabel                    
@onready var _rank_label: Label     = $VBox/RankLabel

func _ready() -> void:
	_score_label.text    = "Pontuação Final: %d" % Gerenciador.score
	_accuracy_label.text = "Precisão Total: %.1f%%" % Gerenciador.get_accuracy()
	_rolls_label.text    = "Total de Lançamentos: %d" % Gerenciador.total_rolls

	_rank_label.text = _get_rank(Gerenciador.get_accuracy())


func _get_rank(acc: float) -> String:
	if acc >= 90:
		return " Mestre dos Dados!"
	elif acc >= 70:
		return " Especialista em Probabilidade"
	elif acc >= 50:
		return " Analista de Dados"
	elif acc >= 30:
		return " Aprendiz"
	else:
		return " Iniciante — Continue praticando!"


func _on_restart_button_pressed() -> void:
	Gerenciador.reset_game()
	get_tree().change_scene_to_file("res://scenes/CenaJogo.tscn")


func _on_menu_button_pressed() -> void:
	Gerenciador.reset_game()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
