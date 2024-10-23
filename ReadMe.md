## Executer le script sur un environnement windows ou linux
**This project is to run on unix s**
A executer en ligne de commande git bash ou linux:

chmod +x script.sh

Ajoutez la ligne suivante pour inclure le répertoire où se trouve votre script:

export PATH=$PATH:/chemin/vers/le/dossier/contenant/le/script

Rechargez votre configuration 
source ~/.bashrc


Exécutez votre script comme une commande

genereate_project.sh

### Renommer le script pour une exécution plus propre

alias generate='/chemin/vers/le/script.sh'
