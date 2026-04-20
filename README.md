# Flappy Bird en Lua

Version simple pour débuter avec `Lua` et `LOVE2D`.

## Lancement

1. Installer `LOVE2D` version 11.x : https://love2d.org/
2. Ouvrir un terminal dans `flappy_bird`
3. Lancer :

```powershell
cd C:\wamp64\www\Portfolio2\flappy_bird
"C:\Program Files\LOVE\love.exe" .
```

## Commandes

- `Espace` ou clic gauche : sauter
- `P` : mettre en pause
- `Entrée` : recommencer après un game over
- `Échap` : revenir au menu

## Organisation du code

- `main.lua` : point d'entrée du jeu. Ce fichier relie LOVE2D au projet, charge les autres modules au démarrage, puis redirige les événements (`load`, `update`, `draw`, clavier, souris`) vers les bonnes fonctions.
- `config.lua` : coeur de la logique. Il contient l'état global de la partie, la sauvegarde, les variables de gameplay, la progression du joueur, les achats de boutique, les collisions, le score, les vies et le déclenchement des modes spéciaux.
- `assets.lua` : gestion des ressources visuelles et sonores. Il charge les images, les sons, les polices, découpe les spritesheets, prépare les frames d'animation et construit aussi les variantes de tuyaux.
- `controls.lua` : gestion des entrées et de la boucle de mise à jour. Il traite les touches selon l'écran actif, le clic souris, les animations, la physique de l'oiseau, le déplacement du décor et l'avancement de la partie.
- `screens.lua` : rendu de tous les écrans. Il dessine la partie, le HUD, les menus, la boutique, la pause, le game over, ainsi que les aperçus des oiseaux, fonds et tuyaux.
- `conf.lua` : configuration technique de LOVE2D. Il définit l'identité du jeu, le comportement de la fenêtre et les paramètres de base avant le lancement.
- `assets/` : dossier de ressources. Il contient les images et sons utilisés par le jeu, par exemple les oiseaux, les backgrounds, les tuyaux, les pièces, les coeurs et les effets sonores.

## Rôle de chaque écran du jeu

- `menu` : écran principal avec les choix pour jouer, ouvrir la boutique, réinitialiser la progression ou quitter.
- `difficulty` : écran de sélection de difficulté avant de lancer une partie.
- `playing` : écran de jeu principal avec l'oiseau, les tuyaux, les pièces, le fond, le score et les vies.
- `paused` : pause de la partie en cours, avec possibilité de reprendre ou de revenir au menu.
- `shop` : boutique où le joueur peut acheter ou équiper des skins d'oiseau, de décor et de tuyaux.
- `reset_confirm` : écran de confirmation avant d'effacer la progression sauvegardée.
- `gameover` : écran de fin de partie avec le score final, le meilleur score, les pièces gagnées et un rappel des bonus spéciaux.

## Contenu du jeu

- un menu principal
- trois niveaux de difficulté
- trois vies
- des pièces à ramasser
- une boutique
- des skins pour l'oiseau, le décor et les tuyaux
- un meilleur score sauvegardé
- un sol qui défile

Le jeu utilise les images présentes dans `assets/`.