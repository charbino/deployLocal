## Deploy Local
Ce script bash permet d'automatiser la phase de configuration d'un projet sur le poste d'un développeur. 

Process : 
 <ul>
    <li>Ajout du hostname dans /etc/hosts</li>
    <li>Création de la configuration nginx en fonction du type de projet (prestashop, symfony, wordpress)</li>
    <li>Téléchargement des sources depuis git (github, gitlab ect ....)  [Optionnel]</li>
    <li>Création de la base de donnée  [Optionnel]</li>
</ul>

### Installation
1) Changer les paramètres au début du fichier `deployLocal/deployLocal.sh`

2) Mettre les sources dans le dossier `/usr/local/bin/deployLocal`
```bash 
sudo cp -r deployLocal /usr/local/lib/deployLocal
```
3) Créer le lien symbolique de la commande pour qu'elle soit accessible depuis n'importe où. 
```bash
sudo ln -s /usr/local/lib/deployLocal/deploy.sh /usr/local/bin/deployLocal
```

### Utilisation
Vous pouvez utiliser la commande n'importe ou. 

Il faut utiliser la commande en sudo : 
```bash
sudo deployLocal
```