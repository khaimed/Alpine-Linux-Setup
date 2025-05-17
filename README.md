# Guide d'utilisation des fichiers Alpine Linux

Ce dossier contient tous les fichiers nécessaires pour configurer Alpine Linux avec i3wm, ly-dm, et tous les packages pour le gaming, le son, le clavier, le bluetooth, ainsi que KVM/QEMU pour la virtualisation de Windows 11 et Pop! OS.

## Structure des fichiers

1. **packages_base_gaming.md** - Liste des paquets de base pour Alpine Linux et le gaming
2. **packages_i3wm_lydm_sound_keyboard_bluetooth.md** - Liste des paquets pour i3wm, ly-dm, son, clavier et bluetooth
3. **packages_kvm_qemu.md** - Liste des paquets pour KVM/QEMU et virtualisation
4. **installation_guide.md** - Guide d'installation et de configuration détaillé
5. **win11_intel.xml** - Fichier XML pour Windows 11 sur processeur Intel
6. **win11_amd.xml** - Fichier XML pour Windows 11 sur processeur AMD (avec support NVIDIA)
7. **popos.xml** - Fichier XML pour Pop!_OS (compatible Intel et AMD)
8. **validation.md** - Vérification de l'exhaustivité et de la cohérence des fichiers
9. **todo.md** - Liste des tâches accomplies

## Ordre d'installation recommandé

1. Suivez le guide d'installation de base d'Alpine Linux dans **installation_guide.md** (sections 1 et 2)
2. Installez l'environnement graphique i3wm et ly-dm (sections 3 et 8)
3. Configurez le son, le clavier et le bluetooth (section 4)
4. Configurez les paquets pour le gaming (section 5)
5. Configurez KVM/QEMU pour la virtualisation (section 6)
6. Configurez la sécurité (section 7)
7. Utilisez les fichiers XML pour créer vos machines virtuelles

## Notes importantes

- Les fichiers XML doivent être placés dans `/etc/libvirt/qemu/` sur votre système Alpine Linux
- Vous devrez peut-être ajuster les chemins des images disque dans les fichiers XML
- Pour le passthrough GPU NVIDIA sur AMD, vous devrez extraire le VBIOS de votre carte graphique
- Tous les paquets listés sont disponibles dans les dépôts Alpine Linux standard, community ou testing

## Personnalisation

- Les fichiers de configuration i3wm, i3status, rofi et picom peuvent être personnalisés selon vos préférences
- Les paramètres de virtualisation peuvent être ajustés en fonction de votre matériel spécifique
- Les allocations de mémoire et de CPU pour les VMs peuvent être modifiées selon vos besoins
