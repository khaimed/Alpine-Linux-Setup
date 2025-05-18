# Guide de Configuration pour i3wm, rofi et polybar

Ce guide vous aidera à personnaliser votre environnement i3wm, rofi et polybar après l'installation de base. Les scripts d'installation ont déjà mis en place les configurations de base, mais vous pourriez vouloir les personnaliser davantage selon vos préférences.

## Table des matières

1. [Configuration de i3wm](#configuration-de-i3wm)
2. [Configuration de polybar](#configuration-de-polybar)
3. [Configuration de rofi](#configuration-de-rofi)
4. [Configuration de picom](#configuration-de-picom)
5. [Personnalisation des thèmes et des polices](#personnalisation-des-thèmes-et-des-polices)

## Configuration de i3wm

Le fichier de configuration principal de i3wm se trouve à `~/.config/i3/config`. Voici quelques modifications courantes que vous pourriez vouloir apporter :

### Modifier les raccourcis clavier

Pour modifier un raccourci clavier, recherchez la ligne correspondante et changez la combinaison de touches :

```
# Raccourci par défaut pour ouvrir un terminal
bindsym $mod+Return exec xfce4-terminal

# Vous pouvez le changer pour :
# bindsym $mod+t exec xfce4-terminal
```

### Changer les applications de démarrage

Pour ajouter ou modifier les applications qui démarrent automatiquement avec i3 :

```
# Ajouter des applications au démarrage
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
exec --no-startup-id feh --bg-fill ~/Images/wallpaper.jpg
```

### Configurer les espaces de travail

Vous pouvez assigner des applications spécifiques à des espaces de travail particuliers :

```
# Assigner des applications à des espaces de travail spécifiques
assign [class="Firefox"] $ws2
assign [class="Thunar"] $ws3
assign [class="virt-manager"] $ws4
```

### Personnaliser l'apparence des fenêtres

Modifiez l'apparence des fenêtres, des bordures et des indicateurs :

```
# Couleurs des fenêtres
# class                 border  backgr. text    indicator child_border
client.focused          #4c7899 #285577 #ffffff #2e9ef4   #285577
client.focused_inactive #333333 #5f676a #ffffff #484e50   #5f676a
client.unfocused        #333333 #222222 #888888 #292d2e   #222222
client.urgent           #2f343a #900000 #ffffff #900000   #900000
client.placeholder      #000000 #0c0c0c #ffffff #000000   #0c0c0c
```

## Configuration de polybar

Polybar est un outil puissant pour créer des barres d'état personnalisées. Le fichier de configuration principal se trouve à `~/.config/polybar/config.ini`.

### Structure de base de la configuration

La configuration de polybar est divisée en sections :

```ini
[colors]
; Définition des couleurs
background = #282A2E
background-alt = #373B41
foreground = #C5C8C6
primary = #F0C674
secondary = #8ABEB7
alert = #A54242
disabled = #707880

[bar/main]
; Configuration de la barre principale
width = 100%
height = 24pt
radius = 0
background = ${colors.background}
foreground = ${colors.foreground}
...

[module/...]
; Configuration des modules
```

### Ajouter des modules

Polybar utilise des modules pour afficher différentes informations. Voici quelques modules utiles :

```ini
[module/i3]
type = internal/i3
pin-workspaces = true
show-urgent = true
strip-wsnumbers = true
index-sort = true
enable-click = true
enable-scroll = false
wrapping-scroll = false
reverse-scroll = false
fuzzy-match = true

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = "CPU "
format-prefix-foreground = ${colors.primary}
label = %percentage:2%%

[module/memory]
type = internal/memory
interval = 2
format-prefix = "RAM "
format-prefix-foreground = ${colors.primary}
label = %percentage_used:2%%

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d%
time = %H:%M:%S
label = %date% %time%
```

### Personnaliser la barre principale

Configurez l'apparence et le contenu de votre barre principale :

```ini
[bar/main]
width = 100%
height = 27
radius = 0
fixed-center = true
background = ${colors.background}
foreground = ${colors.foreground}

line-size = 3
line-color = #f00

border-size = 0
border-color = #00000000

padding-left = 0
padding-right = 2

module-margin-left = 1
module-margin-right = 1

font-0 = "DejaVu Sans:size=10;2"
font-1 = "Font Awesome 5 Free:style=Solid:size=10;2"
font-2 = "Font Awesome 5 Free:style=Regular:size=10;2"
font-3 = "Font Awesome 5 Brands:style=Regular:size=10;2"

modules-left = i3
modules-center = date
modules-right = cpu memory pulseaudio

tray-position = right
tray-padding = 2
```

### Script de lancement

Le script de lancement de polybar (`~/.config/polybar/launch.sh`) est déjà configuré par les scripts d'installation. Vous pouvez le modifier pour lancer plusieurs barres ou avec des configurations différentes.

## Configuration de rofi

Rofi est un lanceur d'applications et sélecteur de fenêtres. Son fichier de configuration principal est `~/.config/rofi/config.rasi`.

### Configuration de base

```rasi
configuration {
    modi: "window,run,ssh,drun";
    font: "DejaVu Sans 12";
    show-icons: true;
    icon-theme: "Papirus";
    terminal: "xfce4-terminal";
    drun-display-format: "{name}";
    location: 0;
    disable-history: false;
    hide-scrollbar: true;
    display-drun: "Applications";
    display-run: "Commandes";
    display-window: "Fenêtres";
    display-ssh: "SSH";
    sidebar-mode: true;
}
```

### Personnaliser le thème

Créez un fichier de thème personnalisé dans `~/.config/rofi/themes/custom.rasi` :

```rasi
* {
    background-color: #282a36;
    border-color: #bd93f9;
    text-color: #f8f8f2;
    spacing: 0;
    width: 512px;
}

inputbar {
    border: 0 0 1px 0;
    children: [prompt,entry];
}

prompt {
    padding: 16px;
    border: 0 1px 0 0;
}

entry {
    padding: 16px;
}

listview {
    cycle: false;
    margin: 0 0 -1px 0;
    scrollbar: false;
}

element {
    border: 0 0 1px 0;
    padding: 16px;
}

element selected {
    background-color: #44475a;
}
```

Puis référencez ce thème dans votre configuration principale :

```rasi
@theme "~/.config/rofi/themes/custom.rasi"
```

## Configuration de picom

Picom est un compositeur pour X11 qui ajoute des effets visuels comme la transparence et les ombres. Son fichier de configuration est `~/.config/picom/picom.conf`.

### Transparence et ombres

```
# Transparence
inactive-opacity = 0.9;
active-opacity = 1.0;
frame-opacity = 0.9;
inactive-opacity-override = false;

# Ombres
shadow = true;
shadow-radius = 7;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.7;
```

### Flou et coins arrondis

```
# Flou
blur-background = true;
blur-method = "dual_kawase";
blur-strength = 5;

# Coins arrondis
corner-radius = 10;
rounded-corners-exclude = [
  "class_g = 'Polybar'",
  "class_g = 'i3bar'"
];
```

### Animations

```
# Animations de fenêtres
transition-length = 300;
transition-pow-x = 0.1;
transition-pow-y = 0.1;
transition-pow-w = 0.1;
transition-pow-h = 0.1;
size-transition = true;
```

## Personnalisation des thèmes et des polices

### Installation de polices supplémentaires

Pour une meilleure expérience, vous pouvez installer des polices supplémentaires :

```bash
sudo apk add font-noto font-noto-emoji font-awesome font-noto-extra
```

### Thèmes GTK

Pour installer et configurer des thèmes GTK :

1. Installez les paquets nécessaires :
   ```bash
   sudo apk add gtk-engines gtk-engine-murrine gtk-theme-configs lxappearance
   ```

2. Téléchargez un thème (par exemple, Arc-Dark) :
   ```bash
   mkdir -p ~/.themes
   cd ~/.themes
   wget https://github.com/jnsh/arc-theme/releases/download/20221218/arc-theme-20221218.tar.xz
   tar -xf arc-theme-20221218.tar.xz
   ```

3. Utilisez lxappearance pour appliquer le thème :
   ```bash
   lxappearance
   ```

### Thèmes d'icônes

Pour installer et configurer des thèmes d'icônes :

1. Installez les paquets nécessaires :
   ```bash
   sudo apk add adwaita-icon-theme
   ```

2. Téléchargez un thème d'icônes (par exemple, Papirus) :
   ```bash
   mkdir -p ~/.icons
   cd ~/.icons
   wget https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/master.zip
   unzip master.zip
   mv papirus-icon-theme-master/* .
   rm -rf papirus-icon-theme-master master.zip
   ```

3. Utilisez lxappearance pour appliquer le thème d'icônes.

## Astuces supplémentaires

### Raccourcis clavier utiles pour i3wm

- `$mod+Shift+r` : Recharger la configuration i3
- `$mod+Shift+c` : Recharger la configuration i3 sans redémarrer
- `$mod+Shift+e` : Quitter i3
- `$mod+Shift+q` : Fermer la fenêtre active
- `$mod+f` : Basculer en mode plein écran
- `$mod+v` : Diviser verticalement
- `$mod+h` : Diviser horizontalement
- `$mod+r` : Mode redimensionnement

### Personnalisation avancée de polybar

Pour une personnalisation plus avancée, vous pouvez consulter la documentation officielle de polybar et des exemples de configurations sur GitHub :

- Documentation officielle : https://github.com/polybar/polybar/wiki
- Exemples de configurations : https://github.com/polybar/polybar-scripts

### Utilisation de rofi comme remplaçant de dmenu

Pour utiliser rofi comme remplaçant de dmenu dans i3, modifiez la ligne suivante dans votre configuration i3 :

```
bindsym $mod+d exec --no-startup-id rofi -show drun
```

Cela lancera rofi en mode lanceur d'applications lorsque vous appuyez sur `$mod+d`.

---

Ce guide vous donne les bases pour personnaliser votre environnement i3wm, polybar et rofi. N'hésitez pas à explorer davantage et à adapter ces configurations à vos besoins spécifiques.
