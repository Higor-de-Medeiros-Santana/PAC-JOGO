extends Control

# Tutorial.gd
# Explica as mecânicas e conceitos de probabilidade.

const PAGES = [
	{
		"title": "O que é Probabilidade?",
		"text": "Probabilidade é a chance de um evento ocorrer.\n\n" +
				"Ex: Um dado de 6 lados tem 1/6 de chance de cair no número 4.\n" +
				"Isso significa ~16.7% de probabilidade.",
		"icon": "🎲"
	},
	{
		"title": "Como jogar",
		"text": "1. Escolha sua aposta (ex: número que vai sair)\n" +
				"2. Clique em 'Rolar' (ou pressione R)\n" +
				"3. Veja o resultado!\n" +
				"4. Acertos dão pontos — erros ensinam!",
		"icon": "📋"
	},
	{
		"title": "Dados e Fases",
		"text": "Nas fases iniciais você usa 1 dado de 6 lados.\n\n" +
				"Nas fases avançadas: múltiplos dados, dados com mais lados, " +
				"apostas em faixas de soma e combinações complexas!",
		"icon": "📈"
	},
	{
		"title": "O Gráfico de Frequência",
		"text": "Cada lançamento aparece no gráfico.\n\n" +
				"Com muitos lançamentos, a distribuição se aproxima da " +
				"probabilidade teórica — isso é a Lei dos Grandes Números!",
		"icon": "📊"
	},
	{
		"title": "Pronto para começar?",
		"text": "Lembre-se:\n" +
				"• Cada fase aumenta a dificuldade\n" +
				"• Analise o gráfico para entender os padrões\n" +
				"• Acurácia acima de 70% = Especialista!\n\n" +
				"Boa sorte, Mestre dos Dados! 🎲",
		"icon": "🏆"
	}
]

var _current_page: int = 0

@onready var _icon_label: Label    = $VBox/IconLabel
@onready var _title_label: Label   = $VBox/TitleLabel
@onready var _text_label: Label    = $VBox/TextLabel
@onready var _page_label: Label    = $VBox/PageLabel
@onready var _next_btn: Button     = $VBox/HBox/NextButton
@onready var _prev_btn: Button     = $VBox/HBox/PrevButton


func _ready() -> void:
	_show_page(0)


func _show_page(idx: int) -> void:
	_current_page = idx
	var page = PAGES[idx]
	_icon_label.text  = page["icon"]
	_title_label.text = page["title"]
	_text_label.text  = page["text"]
	_page_label.text  = "%d / %d" % [idx + 1, PAGES.size()]
	_prev_btn.disabled = (idx == 0)
	_next_btn.text = "Próximo →" if idx < PAGES.size() - 1 else "Jogar!"


func _on_next_button_pressed() -> void:
	if _current_page < PAGES.size() - 1:
		_show_page(_current_page + 1)
	else:
		get_tree().change_scene_to_file("res://scenes/CenaJogo.tscn")


func _on_prev_button_pressed() -> void:
	if _current_page > 0:
		_show_page(_current_page - 1)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
