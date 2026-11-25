🧠 PAC-JOGO — NeuroMind: Aventura pelo Mundo do Conhecimento

Jogo educativo de aventura desenvolvido na Godot Engine 4.6, utilizando GDScript, no contexto do Projeto de Aprendizagem Cooperativa (PAC III).

O NeuroMind tem como objetivo estimular o raciocínio lógico, a percepção visual, o reconhecimento de padrões, o pensamento espacial e a resolução de problemas por meio de desafios interativos.

O jogador percorre quatro fases temáticas, enfrentando enigmas e desafios para restaurar as sinapses e recuperar a fonte mágica. Durante a jornada, conta com a orientação de Sinap, personagem-guia do jogo.

Integrantes: Higor de Medeiros, Felipe Silveira, Gustavo Henrique Forte e Jenifer Alves Scherpinski.
## Estrutura do repositório

Organização definida na seção 4.3 do Plano de Gerenciamento de Configuração
([docs/PlanoDiceMind.pdf](docs/PlanoDiceMind.pdf)):

| Caminho | Conteúdo |
| --- | --- |
| `project.godot`, `export_presets.cfg` | Configuração do projeto e dos presets de exportação |
| `scenes/` | Cenas da Godot (`.tscn`) |
| `scripts/` | Scripts GDScript (`.gd`) do jogo |
| `assets/` | Imagens (`imagens/`, `Icons/`) e áudio (`musica/`) |
| `addons/` | Plugins de terceiros (por exemplo, GUT), com versão registrada |
| `tests/` | Testes automatizados (GUT) |
| `docs/` | Documentação técnica e de gestão (PGC, relatórios) |
| `.github/` | Workflows do GitHub Actions e configuração do Dependabot |

## Como abrir

1. Instale a Godot Engine 4.6 (versão registrada em `project.godot`).
2. No Project Manager, importe a pasta raiz deste repositório (`project.godot`).
3. Execute o projeto (F5); a cena principal é `scenes/Menu.tscn`.

## Como gerar o build

No editor: **Projeto → Exportar… → Windows Desktop → Exportar Projeto**. O executável é
gerado em `build/windows/DiceMind.exe`.

Por linha de comando (com os export templates instalados):

```
godot --headless --export-release "Windows Desktop" build/windows/DiceMind.exe
```

A pasta `build/` não é versionada; os builds oficiais são publicados nas Releases do GitHub.

## Fluxo de contribuição

GitHub Flow: crie uma branch `feature/<issue>-<descricao>` ou `fix/<issue>-<descricao>`,
use Conventional Commits e abra um Pull Request para a `main`.
