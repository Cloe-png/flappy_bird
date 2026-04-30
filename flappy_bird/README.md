# Flappy Bird

Projet de jeu 2D realise en `Lua` avec `LOVE2D`, inspire du principe de Flappy Bird et enrichi avec une boutique, plusieurs difficultés, des skins a débloquer et une sauvegarde de progression.

## Apercu

Le joueur contrôle un oiseau qui doit traverser des series de tuyaux sans les toucher. Chaque passage reussi augmente le score. Pendant la partie, il est possible de récuperer des pièces pour acheter des contenus cosmetiques dans la boutique, ainsi que des bonus de soin quand la situation devient critique.

Le projet a été pensé comme un jeu complet en local :

- menu principal interactif
- séléction de difficulté avant chaque partie
- trois vies par run
- système de pièces a collecter
- boutique avec équipement et achats
- sauvegarde automatique des scores et de la progression
- skins d'oiseaux, de fonds et de tuyaux
- mode spécial lié au score

## Fonctionnalites

### Gameplay

- contrôle simple avec saut au clavier ou a la souris
- collision avec le plafond, le sol et les tuyaux
- score qui augmente a chaque tuyau depassé
- difficulté dynamique pendant une run : vitesse, gravité et écart des tuyaux évoluent
- trois niveaux de difficulté :
  - `Facile`
  - `Moyen`
  - `Difficile`

### Vies et objets

- le joueur commence avec `3 vies`
- des pièces apparaissent régulierement pendant la partie
- les pièces existent en plusieurs valeurs :
  - bronze
  - argent
  - or
- quand il ne reste qu'une vie, un objet de soin peut apparaitre pour récuperer de la marge

### Progression et boutique

- les pièces gagnées pendant une partie sont ajoutées au total à la fin de la run
- la boutique permet d'acheter ou d'equiper :
  - des oiseaux
  - des décors
  - des skins de tuyaux
- certaines récompenses sont cachées et se débloquent selon la progression
- un tuyau `rainbow` se débloque avec un meilleur score global eleve
- entre `100` et `110` points, une présentation spéciale s'active automatiquement

### Sauvegarde

Le jeu sauvegarde automatiquement :

- les meilleurs scores par difficulté
- le nombre total de pièces
- les skins débloqués
- les élèments actuellement équipés

Les données sont stockées dans un fichier `save.txt` via `love.filesystem`.

## Commandes

### Dans les menus

- `Haut / Bas` : naviguer
- `Entree` ou `Espace` : valider
- `Echap` : retour

### Pendant la partie

- `Espace` : sauter
- `Clic gauche` : sauter
- `P` : pause / reprise
- `Echap` : revenir au menu

### Dans la boutique

- `Tab` : changer de catégorie
- `Fleche gauche / droite` : changer de page
- `1` a `9` : acheter ou équiper un objet visible
- `Echap` : revenir au menu

### Ecran de fin

- `Entree` ou `Espace` : recommencer
- `Echap` : revenir au menu

## Installation et lancement

### Prerequis

- `LOVE2D` version `11.x`

Site officiel : `https://love2d.org/`

### Lancer le projet sous Windows

Depuis le dossier du projet :

```powershell
cd C:\wamp64\www\Portfolio2\flappy_bird
"C:\Program Files\LOVE\love.exe" .
```

## Structure du projet

### Fichiers principaux

- `main.lua` : point d'entrée LOVE2D, relie les modules du projet et distribue les callbacks `load`, `update`, `draw`, clavier et souris.
- `config.lua` : coeur du jeu. Contient l'état global, les variables de gameplay, la sauvegarde, les difficultés, la progression, la boutique et les règles de débloquage.
- `assets.lua` : charge les images, sons, polices, animations et variantes visuelles.
- `controls.lua` : gère les entrées utilisateur, la navigation dans les menus, les clics, les achats et la boucle d'update en jeu.
- `screens.lua` : gère tout le rendu visuel des écrans, du HUD, des panneaux, de la boutique et du game over.
- `conf.lua` : configure la fenêtre et les paramètres de base LOVE2D.

### Ressources

Le dossier `assets/` contient :

- les oiseaux jouables
- les fonds du jeu
- les visuels des menus
- les aperçus de boutique
- les sprites de tuyaux
- les pièces et coeurs
- les sons du jeu

## Ecrans du jeu

- `menu` : écran principal avec acces au jeu, à la boutique, au reset et à la sortie
- `difficulty` : choix du niveau de difficulté et affichage des meilleurs scores
- `playing` : partie en cours
- `paused` : pause avec reprise rapide
- `shop` : achat et équipement des skins
- `reset_confirm` : confirmation de remise a zéro
- `gameover` : récapitulatif de fin de partie

## Logique de progression

- chaque difficulé possède son propre meilleur score
- la progression cosmetique est persistante
- les objets cachés ne sont pas affichés comme les objets classiques tant qu'ils ne sont pas débloqués
- le jeu synchronise les débloquages spéciaux a partir du meilleur score global

## Points techniques interessants

- architecture separée par responsabilité : logique, rendu, assets, contrôles
- utilisation de tableaux Lua pour les catalogues de skins et d'objets
- gestion simple mais complète de la sauvegarde texte
- ajustement progressif de la difficulté pendant la run
- overlays et interfaces de menu personnalisés