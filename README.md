<div align="center">
  <img width="50%" src="https://github.com/asger-finding/ddu-kemispillet/raw/main/.github/banner.png" alt="kemispillet banner"/>

  <h1>DDU Projektforløb 2: Kemispillet</h1>
</div>

Minieksamensprojekt.

Lavet af: Asger, Emilie og Kristine

---

Anvender Godot 4.5 til et kemifagligt spil.

## Hvordan kører man spillet?

**Som bruger:**

- Download, udpak og kør spillet for [Linux](https://nightly.link/asger-finding/ddu-kemispillet/workflows/build-and-artifact/main/linux-build.zip) (64-bit) eller for [Windows](https://nightly.link/asger-finding/ddu-kemispillet/workflows/build-and-artifact/main/windows-build.zip).
- Vent på, at din vært har sat spillet op.
- Indtast den IP-adresse, de giver, og tryk Tilslut
- Hyg dig!

---

**Som vært:**

- Installér podman og sikrer dig, at dit system understøtter linux-kommandoer (evt. gennem Windows Subsystem for Linux, hvis på Windows PC). Backenden vil kræve sudo/administratortilladelser, da den laver en netværksudgang.
- Klon dette repository (`git clone https://github.com/asger-finding/ddu-kemispillet.git`) eller hent som ZIP
- `cd ddu-kemispillet/`
  - Kør `./backend/start.sh`
  - Vent til podman images er downloaded og apache og MySQL sat op
  - ZeroTier kræver en bruger. Du bliver givet et link i konsollen. Tilgå linket, opret en konto eller log ind med konto.
    - Når du er inde, tilgå netværket `kemispillet`
    - Tjek adressen i kolonnen under Members (bør have et 🚫 udenfor), og tryk Authorize
  - Proxy-server og reverse-tunnel bliver automatisk oprettet når du har authenticated og authorized ZeroTier.
- Download, udpak og kør spillet for [Linux](https://nightly.link/asger-finding/ddu-kemispillet/workflows/build-and-artifact/main/linux-build.zip) (64-bit) eller for [Windows](https://nightly.link/asger-finding/ddu-kemispillet/workflows/build-and-artifact/main/windows-build.zip).
- Tryk Host
- Hav det sjovt!

Hvis du skal flush, kør `./backend/destroy.sh`

## Tjekliste til viderearbejde

- [ ] Implementer round-state (progress bar, win conditions)
- [ ] Implementer checkpoints
- [ ] Justér konstanter
- [ ] Implementer statistik - opdater spillerstatistik ved slutningen af en runde
- [ ] Nemmere måde at hoste et spil på - evt. med HTTPS, så det kan tilgås online
- [ ] Tjek server health når man forsøger at tilslutte til en vært
- [ ] Bedre måde at vælge spørgsmål på - vægt spørgsmål, så vi undgår gentagne spørgsmål kort efter hinanden
- [ ] Justér konstanter
- [ ] Bug fixes, styrk WebSocket-forbindelsen, bedre fejlhåndtering
