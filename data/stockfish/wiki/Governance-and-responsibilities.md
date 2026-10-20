# Governance and responsibilities

A detailed breakdown of the team members responsible for Stockfish repositories, Fishtest infrastructure, domain hosting, and official communication channels.

## Stockfish Organization

| Role | Access Level | Description |
| :--- | :--- | :--- |
| **Owners** | Admin (Org-wide) | Full access to all repos; can manage members and roles. |
| **Maintainers** | Admin (Repo) | Administrative permissions for specific repositories. |
| **Collaborators** | Write | Permission to push changes to specific repositories. |

| Link | Type | Owners |
| :--- | :--- | :--- |
| [official-stockfish](https://github.com/official-stockfish) | Organization, GitHub Team for Open Source | [glinscott], [mcostalba], [zamar], [snicolet], [vondele], [disservin] |

-----

### Repository Management

| Repository | Link | Maintainers | Collaborators |
| :--- | :--- | :--- | :--- |
| **Stockfish** | [Stockfish](https://github.com/official-stockfish/Stockfish) | [disservin], [snicolet], [vondele]<br>***Inactive:** [glinscott], [mcostalba], [zamar][zamar], [locutus2]* | - |
| **Fishtest** | [fishtest](https://github.com/official-stockfish/fishtest) | [ppigazzini]<br>***Inactive:** [tomtor][tomtor], [stefano80][stefano80], [glinscott]* | [zungur] |
| **NN Trainer** | [nnue-pytorch](https://github.com/official-stockfish/nnue-pytorch) | [Sopel97], [vondele], [glinscott], [xu-shawn][xu-shawn] | - |
| **Website** | [stockfish-web](https://github.com/official-stockfish/stockfish-web) | [daylen], [dav1312] | - |
| **Books** | [books](https://github.com/official-stockfish/books) | [vondele], [snicolet], [disservin] | - |

-----

## Infrastructure & Hosting

### Fishtest

| Service | Link | Owner | Maintainers | Contributors |
| :--- | :--- | :--- | :--- | :--- |
| **VPS** | [tests.stockfishchess.org](https://tests.stockfishchess.org) | [glinscott] | [ppigazzini], [zungur] | [vondele], [disservin] |
| **Networks** | data.stockfishchess.org / [tests.stockfishchess.org/nns](https://tests.stockfishchess.org/nns) | [glinscott] | [ppigazzini], [zungur] | [vondele], [disservin] |
| **AWS S3 Backups** | Mongodb & Nets | [glinscott] | - | [ppigazzini], [vondele], [disservin] |

### Historical data

| Resource | Link / Resource | Owner / Admin | Contributor |
| :--- | :--- | :--- | :--- |
| **Hugging Face** | [official-stockfish](https://huggingface.co/official-stockfish) | [vondele], [disservin]| [robertnurnberg] |
| **Archived Releases** | [drive.google.com](https://drive.google.com/drive/folders/1nzrHOyZMFm4LATjF5ToRttCU0rHXGkXI) | [daylen] | - |
| **Past Tests (a)** | [fishcooking-results](https://groups.google.com/g/fishcooking-results) | [ppigazzini], [vondele], [zungur] | - |
| **Past Tests (b)** | [fishcooking\_results](https://groups.google.com/g/fishcooking_results) | [mcostalba] | - |

### Main Website

| Component | Resource | Owner |
| :--- | :--- | :--- |
| **Domain** | [stockfishchess.org](https://stockfishchess.org/) | [daylen] |
| **CDN** | Content Delivery | [daylen] |

-----

## Social Media & Community

| Platform | Link | Owner | Admin |
| :--- | :--- | :--- | :--- |
| **Discord** | [Join Server](https://discord.gg/GWDRS3kU6R) | [disservin]| [Sopel97], [vondele]
| **Twitter** | [@stockfishchess](https://twitter.com/stockfishchess) | [daylen] | - |
| **Bluesky** | [@stockfishchess.org](https://bsky.app/profile/stockfishchess.org) | [dav1312] | - |
| **Facebook** | [stockfishchess](https://www.facebook.com/stockfishchess) | [daylen] | - |

[glinscott]: https://github.com/glinscott
[mcostalba]: https://github.com/mcostalba
[zamar]: https://github.com/zamar
[snicolet]: https://github.com/snicolet
[vondele]: https://github.com/vondele
[Disservin]: https://github.com/Disservin
[ppigazzini]: https://github.com/ppigazzini
[tomtor]: https://github.com/tomtor
[stefano80]: https://github.com/stefano80
[Sopel97]: https://github.com/Sopel97
[zungur]: https://github.com/zungur
[daylen]: https://github.com/daylen
[locutus2]: https://github.com/locutus2
[noobpwnftw]: https://github.com/noobpwnftw
[dav1312]: https://github.com/dav1312
[xu-shawn]: https://github.com/xu-shawn
[robertnurnberg]: https://github.com/robertnurnberg