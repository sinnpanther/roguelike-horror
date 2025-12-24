Latente Fear
============

# Concept

1. Roguelike horreur
   Passer de salle en salle avec une porte à choisir
   Événements aléatoires avec des screamers des fois
   Seed

Jauge de peur, si pleine => état de folie. Que se passe-t-il ensuite ? Vision + musique qui changent ?


| Monstres de base | Monstres élites | Bosses | Portes | Items Communs | Item Rares | Items Epiques | Items Légendaires | Items maudits | Types d'horreur | Armes                  | Enigmes |
| ---------------- | --------------- | ------ | ------ | ------------- | ---------- | ------------- | ----------------- | ------------- | --------------- | ---------------------- | ------- |
|                  |                 |        |        |               | Ampoule UV |               |                   |               | Analog horror   | Couteau (arme de base) |         |
|                  |                 |        |        |               |            |               |                   |               | Légendes        |                        |         |
|                  |                 |        |        |               |            |               |                   |               | Body horror     |                        |         |



# Gameplay
## Notions
### Paranoïa
Jauge qui monte en fonction de certaines conditions/évènements
Elle augmente quand il se passe des trucs “suspects”, par exemple :

- **Tuer un ennemi** :  
  +X paranoïa (le calme après coup n’est pas rassurant).
- **Lampe qui éclate** :  
  +X paranoïa.
- **Porte qui s’ouvre toute seule** :  
  +X paranoïa.
- **Bruitage / apparition étrange** (events spéciaux) :  
  +X paranoïa.

La paranoïa déclenche des évènements bizarre qui eux-même augmente la paranoïa => boucle

|   %    | 0%  | 25% | 50% | 75% | 100% |
| :----: | :-: | :-: | :-: | :-: | :--: |
| Icone  |     |     |     |     |      |
| Effets |     |     |     |     |      |
Elle est représentée par un icône qui change de forme : 5 formes
### Bruit

## Boucle de gameplay
### 1. Forme / taille des salles

- **Base** : grandes salles **rectangulaires**, comme tu as déjà, avec :
    - taille aléatoire dans une plage (600–900 de large, 400–700 de haut),
    - obstacles (piliers / murs intérieurs) qui créent :
        - des couloirs,
        - des “presque L”,
        - des zones cachées.
- Progression :
    - Début : salles plutôt **ouvertes** et moyennes.
    - Milieu : salles plus grandes ou plus **cloisonnées** (plus de piliers).
    - Fin : salles plus **serrées** et étouffantes.

---
### 2. Nombre de niveaux / boss

- Première version : **~10 niveaux** par run.
    - 1–3 : mise en jambes.
    - 4–6 : vraie difficulté.
    - 7–9 : très tendu.
    - 10 : **salle spéciale de boss / épreuve finale**.
- Le boss n’est pas un sac à PV mais :
    - un **puzzle de mouvement / lumière**,
    - ou un combat basé sur le **décor** (lumières, pièges, générateur, etc.),
    - pour rester compatible avec les **munitions rares**.

---
### 3. Nombre d’ennemis par niveau

- Peu d’ennemis, mais **chaque rencontre compte** :
    - Niveaux 1–3 : 1–2 ennemis par salle.
    - Niveaux 4–6 : 2–3 ennemis.
    - Niveaux 7–9 : 3–4 ennemis max, parfois “dormants” tant que tu ne t’approches pas.
- La difficulté ne vient pas que du nombre, mais :
    - du **placement** (angles morts, piliers),
    - du **mélange de types** (chaser + plus tard stalker),
    - de la **visibilité limitée**.

---
### 4. Énigmes procédurales / loot

Des **micro-énigmes rapides et optionnelles** pour obtenir du stuff :

- Porte verrouillée → 1–3 interrupteurs à trouver/activer (pattern aléatoire, parfois piégé).
- Coffre maudit : gros loot mais spawn d’ennemi / montée de peur / blackout.
- Objets à retrouver dans la salle (certains dans l’ombre).
- Plaques au sol à activer dans un ordre aléatoire.

Récompenses typiques :

- munitions rares,
- sedatifs,
- petits upgrades (vision, peur max, etc.).

---
### 5. Roguelike + ressources rares + boss : cohérence

- C’est compatible si :
    - les **combats sont souvent évitables** (fuite / esquive viables),
    - les **balles sont puissantes mais rares** (1 bonne balle = moment décisif),
    - les boss reposent plus sur :
        - le **mouvement**,
        - la **lumière**,
        - le **décor**.
# Types d'horreur

# Personnage

## Contrôles clavier/souris

| Touche |  Action   |
| :----: | :-------: |
|   Z    |  Avancer  |
|   S    |  Reculer  |
|   Q    |  Gauche   |
|   D    |  Droite   |
|        |   Dash    |
|        |   Tirer   |
|        | Recharger |

## Contrôles manette

# IA

# Portes

# Map

# Enigmes

# Armes
Munitions très limitées possible d'augmenter avec certains items
# Items

## Communs
## Rares
### Ampoule UV
Permet de bruler certains ennemis (remplace la couleur de la lampe torche par bleu/violet)

## Epiques

## Légendaires

# Settings

# Builds

| Build                    | Avantages ✅                                                                                                                     | Inconvénients ❌                                                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |

