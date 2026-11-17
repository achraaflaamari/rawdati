# 🌱 Rawdati — Kindergarten Management Application

**Rawdati** est une application mobile développée avec Flutter pour les garderies et les jardins d'enfants. Elle permet au personnel de partager les photos des activités quotidiennes avec les parents, dans un espace organisé et sécurisé.

## 🎯 Fonctionnalités principales

### 👨‍💼 Administrateur
- Gestion des informations de la garderie.
- Gestion des enfants et de leurs groupes.
- Création et gestion des comptes du personnel et des parents.
- Association des enfants à leurs parents.
- Activation et désactivation des comptes.

### 👩‍🏫 Personnel (Staff)
- Création de dossiers organisés par date et activité.
- Sélection de plusieurs photos depuis la galerie.
- Attribution des photos aux enfants concernés.
- Prévisualisation et publication des photos.
- Suivi de l'envoi des photos.

### 👨‍👩‍👧 Parents
- Consultation des photos de leurs enfants.
- Affichage des photos par date et activité.
- Réactions aux photos avec des emojis.
- Téléchargement des photos.
- Réception de notifications lors de nouvelles publications.

## 📸 Organisation des photos

Les photos sont organisées par journée et par activité.

```text
22-04-2026/
├── Arrivée/
├── Jeux/
├── Goûter/
└── Activités/
```

Le personnel peut sélectionner plusieurs photos, les associer aux enfants concernés, puis les publier immédiatement ou ultérieurement.

## 🔔 Notifications

- **Parents :** notification lors de la publication de nouvelles photos.
- **Personnel :** notification en cas d'échec d'envoi.
- **Administrateur :** notification lors de la création d'un compte.

## 🛠️ Technologies utilisées

| Technologie | Utilisation |
|---|---|
| Flutter & Dart | Développement mobile |
| Supabase | Backend et base de données |
| Supabase Auth | Authentification |
| PostgreSQL | Gestion des données |
| Image Picker | Sélection des photos |
| Flutter SVG | Affichage des illustrations |

## ⚙️ Installation

**1. Cloner le projet**

```bash
git clone https://github.com/achraaflaamari/rawdati.git
```

**2. Accéder au dossier**

```bash
cd rawdati
```

**3. Installer les dépendances**

```bash
flutter pub get
```

**4. Configurer Supabase**

Vérifier la configuration dans `lib/core/constants/supabase_config.dart` avec les informations de votre projet Supabase.

**5. Lancer l'application**

```bash
flutter run
```

## 🔐 Sécurité

Rawdati prévoit une gestion des rôles et des accès afin que chaque parent puisse consulter uniquement les photos de ses enfants. La sécurité doit également être assurée côté Supabase avec les politiques RLS appropriées.

## 📱 Plateformes

- Android
- iOS

## 👨‍💻 Dépôt GitHub

[github.com/achraaflaamari/rawdati](https://github.com/achraaflaamari/rawdati)

---

🌱 **Rawdati — Chaque moment de l'enfance mérite d'être partagé.**
