# Terminal — Navigation et fichiers

Référence transversale, indépendante de la progression Wagon (utile dès le jour 1, quel que soit le module en cours).

## Se déplacer

| Commande | Effet |
|---|---|
| `pwd` | Affiche le dossier où tu te trouves (Print Working Directory) |
| `ls` | Liste les fichiers/dossiers du dossier courant |
| `ls -la` | Liste tout, y compris les fichiers cachés, avec détails |
| `cd nom_dossier` | Entre dans un dossier |
| `cd ..` | Remonte d'un niveau (dossier parent) |
| `cd ~` ou `cd` | Va directement à la racine de ton compte (`/Users/brice`) |
| `cd -` | Retourne au dossier précédent |
| `cd /chemin/absolu` | Va directement à un chemin précis |

> Rappel Mac : le tilde `~` s'obtient avec **⌥ (Alt) + N**, puis espace pour le valider seul.

## Créer, copier, déplacer, supprimer

| Commande | Effet |
|---|---|
| `mkdir nom` | Crée un dossier |
| `touch fichier.sql` | Crée un fichier vide |
| `cp fichier.sql copie.sql` | Copie un fichier |
| `cp -r dossier1 dossier2` | Copie un dossier entier (récursif) |
| `mv fichier.sql nouveau_nom.sql` | Renomme (ou déplace) un fichier |
| `rm fichier.sql` | Supprime un fichier (⚠️ définitif, pas de corbeille) |
| `rm -r dossier` | Supprime un dossier et son contenu (⚠️ à utiliser avec prudence) |

## Lire et chercher

| Commande | Effet |
|---|---|
| `cat fichier.sql` | Affiche tout le contenu d'un fichier |
| `less fichier.sql` | Affiche le contenu page par page (`q` pour quitter) |
| `head fichier.sql` | Affiche les 10 premières lignes |
| `tail fichier.sql` | Affiche les 10 dernières lignes |
| `grep "mot" fichier.sql` | Cherche une chaîne de caractères dans un fichier |
| `tree` | Affiche l'arborescence des fichiers/dossiers |
| `find . -name "*.sql"` | Cherche tous les fichiers `.sql` à partir du dossier courant |

## Divers utiles

| Commande | Effet |
|---|---|
| `clear` | Nettoie l'écran du terminal |
| `history` | Affiche l'historique des commandes tapées |
| `open .` | Ouvre le dossier courant dans le Finder (Mac) |
| `code .` | Ouvre le dossier courant dans VS Code |
| `echo $SHELL` | Affiche le shell utilisé (zsh, bash…) |
| `Ctrl + C` | Interrompt une commande en cours |
| `Ctrl + L` | Nettoie l'écran (équivalent à `clear`) |
| `Tab` | Autocomplète un nom de fichier/dossier |
