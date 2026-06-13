# LeBlogOSD

Base documentaire et scripts autour de l'administration poste de travail, du deploiement, de la securite et des outils endpoint.

## Structure

- `tanium/` : deploiement, patch, provisioning, client et environnements on-prem.
- `intune/` : Autopilot, applications, conformite et remediations.
- `mdt/` : scripts, outils et notes Microsoft Deployment Toolkit.
- `wsus/` : scripts et automatisations WSUS et Windows Update.
- `master/` : scripts et modeles pour la preparation d'images Windows.
- `packaging/` : scripts de packaging et d'installation applicative.
- `scripts/` : scripts PowerShell generiques d'administration.
- `ivanti/` : Ivanti EPM et SQL.
- `kace/` : scripts et automatisations KACE.

## Regles de contenu

- Ne pas commiter de secrets, tokens, mots de passe, exports clients ou donnees nominatives.
- Placer les scripts reutilisables dans le dossier correspondant a leur technologie.
- Ajouter un `README.md` dans les sous-dossiers importants quand le contenu devient significatif.
