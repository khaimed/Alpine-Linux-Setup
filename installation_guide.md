# Guide d'Installation Alpine Linux VM Host

Ce guide détaille les étapes d'installation d'Alpine Linux comme hôte de virtualisation avec i3wm, polybar, et KVM/QEMU pour les machines virtuelles Windows 11 et Pop!OS.

## Prérequis

- Une clé USB bootable avec Alpine Linux
- Un ordinateur avec processeur Intel Ultra 7 ou AMD Ryzen 9 5000
- Au moins 16 Go de RAM
- Un disque dur avec au moins 500 Go d'espace

## Étape 0: Partitionnement initial

Avant d'exécuter les scripts, vous devez installer Alpine Linux et partitionner votre disque comme suit:

```
/dev/sda1 = EFI 512M
/dev/sda2 = Alpine Linux 20G ext4
/dev/sda3 = swap 2G
/dev/sda4 = vm 220G ext4
/dev/sda5 = storage 234G ntfs
```

Pour ce faire:
1. Démarrez sur la clé USB Alpine Linux
2. Connectez-vous en tant que root
3. Exécutez `setup-alpine` et suivez les instructions
4. Pour le partitionnement, choisissez "sys" et créez les partitions comme indiqué ci-dessus

## Étape 1: Installation de base

1. Copiez tous les fichiers du zip sur votre système Alpine Linux:
   ```
   mkdir -p ~/alpine_scripts
   # Copiez les fichiers du zip dans ce répertoire
   ```

2. Rendez les scripts exécutables:
   ```
   chmod +x ~/alpine_scripts/*.sh
   ```

3. Exécutez le premier script:
   ```
   cd ~/alpine_scripts
   ./step1_base_setup.sh
   ```

4. Ce script va:
   - Détecter votre matériel (Intel/AMD et NVIDIA)
   - Configurer les dépôts Alpine
   - Installer les paquets système essentiels
   - Configurer le réseau
   - Monter les partitions pour VM et stockage
   - Créer un utilisateur (si vous le souhaitez)

5. Redémarrez lorsque vous y êtes invité:
   ```
   reboot
   ```

## Étape 2: Configuration de l'environnement de bureau

1. Après le redémarrage, connectez-vous en tant que root
2. Exécutez le deuxième script:
   ```
   cd ~/alpine_scripts
   ./step2_desktop_setup.sh
   ```

3. Ce script va:
   - Installer Xorg et les pilotes graphiques
   - Installer i3wm comme gestionnaire de fenêtres
   - Installer polybar (remplaçant i3status)
   - Installer ly-dm comme gestionnaire de connexion
   - Configurer l'audio (pulseaudio)
   - Configurer le bluetooth
   - Installer les pilotes spécifiques à votre CPU (Intel/AMD)
   - Installer les pilotes NVIDIA si détectés
   - Copier les fichiers de configuration pour l'utilisateur

4. Redémarrez lorsque vous y êtes invité:
   ```
   reboot
   ```

## Étape 3: Configuration de la virtualisation

1. Après le redémarrage, connectez-vous avec votre utilisateur ou en tant que root
2. Exécutez le troisième script:
   ```
   cd ~/alpine_scripts
   sudo ./step3_virtualization_setup.sh
   ```

3. Ce script va:
   - Installer KVM/QEMU et libvirt
   - Configurer les services nécessaires
   - Créer les répertoires pour les VM
   - Configurer IOMMU pour le passthrough matériel
   - Configurer les modules pour le passthrough
   - Créer des scripts utilitaires pour le passthrough GPU
   - Ajouter l'utilisateur aux groupes de virtualisation

4. Redémarrez lorsque vous y êtes invité:
   ```
   reboot
   ```

## Étape 4: Configuration des machines virtuelles

1. Après le redémarrage, connectez-vous avec votre utilisateur ou en tant que root
2. Exécutez le quatrième script:
   ```
   cd ~/alpine_scripts
   sudo ./step4_vm_setup.sh
   ```

3. Ce script va:
   - Créer les fichiers XML pour les VM (Windows 11 Intel/AMD et Pop!OS)
   - Créer les images disque pour les VM
   - Définir les VM dans libvirt
   - Créer des scripts de démarrage pour les VM

4. L'installation est maintenant terminée!

## Utilisation des machines virtuelles

### Préparation des ISO

Avant de démarrer les VM, vous devez copier les ISO d'installation dans le répertoire de stockage:

```
sudo cp chemin/vers/windows11.iso /mnt/storage/
sudo cp chemin/vers/pop-os.iso /mnt/storage/
```

### Configuration du passthrough GPU

Pour configurer le passthrough GPU (nécessaire pour les performances de jeu):

```
sudo setup-gpu-passthrough
```

Suivez les instructions à l'écran pour sélectionner votre GPU.

Si vous avez une carte NVIDIA, après redémarrage, exécutez:

```
sudo extract-nvidia-vbios ID_GPU
```

Remplacez ID_GPU par l'identifiant de votre GPU (ex: 01:00.0).

### Démarrage des VM

Pour démarrer les VM, utilisez les commandes suivantes:

- Sur machine Intel:
  ```
  start-win11-intel
  ```

- Sur machine AMD:
  ```
  start-win11-amd
  ```

- Sur les deux types de machines:
  ```
  start-popos
  ```

## Dépannage

### Problèmes de démarrage de VM

Si une VM ne démarre pas:

1. Vérifiez les logs:
   ```
   sudo virsh start nom_vm --verbose
   ```

2. Vérifiez que les ISO sont présentes:
   ```
   ls -la /mnt/storage/*.iso
   ```

3. Vérifiez les permissions:
   ```
   sudo chmod -R 777 /mnt/vm
   ```

### Problèmes de passthrough GPU

Si le passthrough GPU ne fonctionne pas:

1. Vérifiez que IOMMU est activé:
   ```
   dmesg | grep -i iommu
   ```

2. Vérifiez les modules chargés:
   ```
   lsmod | grep vfio
   ```

3. Reconfigurer le passthrough:
   ```
   sudo setup-gpu-passthrough
   ```

## Personnalisation

Pour personnaliser votre environnement i3wm, polybar, rofi et autres composants, consultez le fichier `config_guide.md` inclus.

---

Pour toute question ou problème, référez-vous à la documentation officielle d'Alpine Linux ou aux forums de la communauté.
