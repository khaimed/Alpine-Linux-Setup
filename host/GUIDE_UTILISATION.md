# Guide d'utilisation du script d'installation Alpine Linux comme hôte VM

Ce document explique comment utiliser le script d'installation automatique pour configurer Alpine Linux comme un hôte de virtualisation minimal et efficace pour vos machines virtuelles Windows 11 et Pop!OS.

## Prérequis

- Un SSD externe avec la structure de partitionnement suivante :
  - /dev/sda1 = Alpine Linux (20G, ext4)
  - /dev/sda2 = swap (2G)
  - /dev/sda3 = vm (220G, ext3)
  - /dev/sda4 = storage (234G, ntfs)
- Une installation de base d'Alpine Linux sur /dev/sda1
- Au moins 16 Go de RAM sur la machine hôte
- Un processeur Intel Ultra 7 ou AMD Ryzen 9 5000 avec carte graphique NVIDIA GeForce RTX

## Installation

1. Téléchargez et installez Alpine Linux sur la partition /dev/sda1
2. Connectez-vous en tant que root
3. Copiez le script `alpine_vm_host_setup.sh` sur votre système
4. Rendez le script exécutable :
   ```
   chmod +x alpine_vm_host_setup.sh
   ```
5. Exécutez le script :
   ```
   ./alpine_vm_host_setup.sh
   ```
6. Suivez les instructions à l'écran pour créer un utilisateur et configurer le système
7. Redémarrez le système lorsque demandé

## Après l'installation

1. Connectez-vous avec votre nom d'utilisateur et mot de passe
2. Configurez le passthrough GPU en exécutant :
   ```
   sudo setup-gpu-passthrough
   ```
3. Suivez les instructions pour identifier et configurer votre GPU pour le passthrough
4. Si vous avez une carte NVIDIA, redémarrez puis exécutez :
   ```
   sudo extract-nvidia-vbios <GPU_ID>
   ```
5. Redémarrez une dernière fois pour appliquer toutes les configurations

## Utilisation des machines virtuelles

Pour démarrer vos machines virtuelles, utilisez les commandes suivantes :

- Sur machine Intel :
  ```
  start-win11-intel
  ```

- Sur machine AMD avec NVIDIA :
  ```
  start-win11-amd
  ```

- Sur les deux types de machines :
  ```
  start-popos
  ```

## Personnalisation

- Les fichiers XML des VM se trouvent dans `/mnt/vm/xml/`
- Les images disque sont stockées dans `/mnt/vm/images/`
- Les fichiers NVRAM sont dans `/mnt/vm/nvram/`
- Les VBIOS extraits sont dans `/mnt/vm/vbios/`

## Dépannage

Si vous rencontrez des problèmes avec le passthrough GPU :

1. Vérifiez que IOMMU est activé dans le BIOS/UEFI
2. Vérifiez que les modules vfio sont chargés :
   ```
   lsmod | grep vfio
   ```
3. Vérifiez que votre GPU est correctement détaché du système hôte :
   ```
   dmesg | grep -i vfio
   ```

Pour tout autre problème, consultez les journaux système :
```
dmesg
journalctl -xe
```
