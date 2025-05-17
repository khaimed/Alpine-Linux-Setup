# Vérification du script et des fichiers XML

## Vérification du script d'installation

- [x] Détection automatique du matériel (Intel/AMD/NVIDIA)
- [x] Installation des paquets minimaux pour un hôte de virtualisation
- [x] Configuration correcte du montage /mnt/vm sur /dev/sda3
- [x] Configuration de i3wm et ly-dm minimaliste
- [x] Configuration du passthrough matériel (IOMMU, vfio)
- [x] Scripts utilitaires pour le passthrough GPU
- [x] Création des images disque avec les bonnes tailles (120G pour Win11, 80G pour Pop!OS)
- [x] Portabilité entre différentes machines (Intel/AMD)

## Vérification des fichiers XML

- [x] Chemins d'accès corrects pour les images disque (/mnt/vm/images/)
- [x] Chemins d'accès corrects pour les NVRAM (/mnt/vm/nvram/)
- [x] Configuration mémoire adaptée (14GB pour Win11, 8GB pour Pop!OS)
- [x] Configuration CPU adaptée (4 cœurs)
- [x] Masquage de l'hyperviseur pour des performances natives
- [x] Support du passthrough GPU pour NVIDIA sur AMD
- [x] Compatibilité avec Intel et AMD

## Vérification de la documentation

- [x] Instructions claires pour l'installation
- [x] Instructions pour la configuration post-installation
- [x] Instructions pour le passthrough GPU
- [x] Instructions pour le démarrage des VM
- [x] Instructions de dépannage

## Optimisations pour un hôte minimal

- [x] Réduction des paquets au strict minimum nécessaire
- [x] Configuration légère de i3wm
- [x] Désactivation des services non essentiels
- [x] Optimisation pour la virtualisation
