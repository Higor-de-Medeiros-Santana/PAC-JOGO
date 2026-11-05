extends RefCounted
# Historia.gd
# Textos da narrativa do Modo Aventura.
#
# Enredo: na Vila Aleatória todos acreditam que tudo é "questão de sorte".
# O Croupier, dono do Cassino do Acaso, roubou o Livro das Chances, o único
# livro que explica como o acaso funciona. O jogador (um aprendiz curioso),
# acompanhado do Pip (um dado falante), sobe os andares do cassino
# aprendendo probabilidade para recuperar o livro.
#
# Cada andar apresenta um conceito que combina com o tipo de aposta usado
# naquele andar (ver RunManager.get_config_combate):
#   Andar 1 -> chance de um número exato (1 em 6)
#   Andar 2 -> par ou ímpar (50%) e independência dos lançamentos
#   Andar 3 -> soma de dois dados (o 7 é o mais provável)
#   Andar 4 -> faixas de soma (a faixa do meio é a mais provável)
#   Andar 5 -> risco e recompensa (eventos)
#   Andar 6 -> chefe: mistura de tudo
#
# Uso: const Historia = preload("res://scripts/Historia.gd")

const NARRADOR := "Narrador"
const PIP := "Pip"

const PROLOGO: Array = [
	{
		"quem": NARRADOR,
		"texto": "Na Vila Aleatória, todo mundo achava que a vida era questão de sorte. Dia de chuva? Sorte. Nota boa na prova? Sorte. Até que, numa noite sem lua, o Cassino do Acaso apareceu no alto da colina, e com ele chegou o Croupier.",
	},
	{
		"quem": NARRADOR,
		"texto": "O Croupier roubou o Livro das Chances, o único livro que explicava como o acaso realmente funciona. Sem ele, a vila passou a acreditar em números da sorte, em dias de azar e em dados que ficam \"quentes\".",
	},
	{
		"quem": NARRADOR,
		"texto": "Você é a pessoa mais curiosa da vila, e ninguém acredita que alguém assim possa enfrentar o Croupier. Mas, no fundo da sua mochila, algo vermelho começa a se mexer...",
	},
	{
		"quem": PIP,
		"texto": "Oi! Eu sou o Pip, um dado de seis faces e cem opiniões! Cada rolagem é uma surpresa, mas não é bagunça: o acaso tem regras, e eu conheço todas elas.",
	},
	{
		"quem": PIP,
		"texto": "Vamos subir o cassino andar por andar, apostando com a cabeça e não com o palpite, até o salão do topo. Lá está o Livro das Chances. Vamos nessa?",
	},
]

# Narrativa de cada andar, exibida no mapa antes de o jogador escolher o caminho.
const ANDARES := {
	1: {
		"titulo": "Andar 1: Salão das Fichas",
		"texto": "Mesas simples, luzes quentes e apostadores distraídos. Aqui cada rolagem usa um único dado, e você precisa adivinhar o número exato.",
		"dica": "Um dado tem 6 faces e todas têm a mesma chance. Acertar o número exato é 1 chance em 6, cerca de 17%. Não é fácil, mas dá!",
	},
	2: {
		"titulo": "Andar 2: Corredor do Par ou Ímpar",
		"texto": "Um corredor comprido, com placas piscando PAR e ÍMPAR. Um apostador jura que o ímpar \"está quente\" e que o par \"está atrasado\".",
		"dica": "Metade das faces é par (2, 4, 6) e metade é ímpar (1, 3, 5): são 50% para cada lado. E dado não tem memória: o que saiu antes não muda o que vem depois.",
	},
	3: {
		"titulo": "Andar 3: Mesa dos Dois Dados",
		"texto": "Agora são dois dados rolando juntos, e o que vale é a soma deles. O Croupier mandou seus crupiês mais espertos para este andar.",
		"dica": "Com dois dados existem 36 combinações possíveis. A soma 7 aparece em 6 delas (cerca de 17%) e é a mais provável. Já o 2 e o 12 aparecem em apenas 1 de 36.",
	},
	4: {
		"titulo": "Andar 4: Galeria das Faixas",
		"texto": "Aqui ninguém aposta em números exatos: a escolha é entre faixa baixa, média ou alta. Espelhos por todo lado mostram quem se enganou.",
		"dica": "Somando dois dados, a faixa baixa (até 4) sai em 6 de 36 combinações, a média (5 a 8) em 20 de 36 (mais de 55%) e a alta (acima de 8) em 10 de 36. Apostar no meio costuma compensar.",
	},
	5: {
		"titulo": "Andar 5: Cofre do Risco",
		"texto": "O Croupier deixou baús, fontes e videntes com ofertas tentadoras. Quase tudo aqui esconde um risco, e é você quem decide se vale a pena.",
		"dica": "Antes de arriscar, pergunte: quanto eu posso ganhar, quanto posso perder e com que chance? Se o ganho é grande e o risco é pequeno, a aposta compensa. Se for o contrário, é melhor passar.",
	},
	6: {
		"titulo": "Andar 6: Salão do Croupier",
		"texto": "No topo da colina, o Croupier espera ao lado do Livro das Chances. Ele muda de estratégia sempre que perde terreno, então prepare-se para tudo.",
		"dica": "Use tudo que aprendeu: par ou ímpar, soma e faixas. E lembre: não existe número da sorte, só existem chances.",
	},
}

const NOMES_COMBATE := {
	1: "Apostador Distraído",
	2: "Vidente do Corredor",
	3: "Dupla de Crupiês",
	4: "Guardião dos Espelhos",
	5: "Cofre Ambulante",
}

const FALAS_COMBATE := {
	1: [
		"«O 6 está atrasado, ele TEM que sair!»",
		"«Meu dado da sorte nunca falha... quase nunca.»",
	],
	2: [
		"«Saiu ímpar três vezes seguidas. Agora é par, certeza!»",
		"«Eu leio o futuro nas faces do dado.»",
	],
	3: [
		"«Dois dados, o dobro de sorte!»",
		"«Apostar no 12 é coragem. Ou loucura.»",
	],
	4: [
		"«Os espelhos nunca mentem... só confundem.»",
		"«Baixo, médio ou alto? Escolha logo!»",
	],
	5: [
		"«Tudo aqui tem um preço, e um risco.»",
		"«Você calcula ou chuta?»",
	],
}

const FALAS_ELITE: Array = [
	"«Você passou pelos meus colegas, mas eu sou mais esperto.»",
	"«A Casa SEMPRE ganha. Pergunte a qualquer um!»",
]

const FALAS_BOSS: Array = [
	"«Então foi você quem subiu até aqui. A Casa sempre ganha, sabia?»",
	"«Gostou do par ou ímpar? Agora vem a soma!»",
	"«Última chance: faixas! Diga adeus ao Livro!»",
]


static func andar(floor_i: int) -> Dictionary:
	return ANDARES.get(floor_i, {})


static func nome_inimigo(floor_i: int, eh_elite: bool, eh_boss: bool) -> String:
	if eh_boss:
		return "O Croupier Final"
	if eh_elite:
		return "Crupiê de Elite"
	return String(NOMES_COMBATE.get(floor_i, "Apostador Sombrio"))


static func fala_inimigo(floor_i: int, eh_elite: bool, eh_boss: bool) -> String:
	if eh_boss:
		return String(FALAS_BOSS[0])
	if eh_elite:
		return String(FALAS_ELITE.pick_random())
	var opcoes: Array = FALAS_COMBATE.get(floor_i, [])
	if opcoes.is_empty():
		return ""
	return String(opcoes.pick_random())


# fase: 1 = chefe passa para a aposta de soma; 2 = passa para as faixas.
static func fala_boss_fase(fase: int) -> String:
	return String(FALAS_BOSS[clampi(fase, 0, FALAS_BOSS.size() - 1)])


static func epilogo(venceu: bool) -> String:
	if venceu:
		return "O Croupier tropeça nas próprias fichas. \"Impossível... a Casa não deveria perder!\" Pip responde: \"A Casa só ganha quando as pessoas não conhecem as chances.\"\n\nO Livro das Chances brilha e volta para as suas mãos. Na Vila Aleatória, ninguém mais diz \"foi só sorte\": agora todo mundo sabe contar as chances."
	return "O Croupier ri, mas Pip sussurra: \"Cada rolagem é independente. A próxima pode ser diferente, e agora você sabe mais do que antes.\"\n\nO Livro das Chances continua lá no topo, esperando. Que tal tentar outro caminho?"
