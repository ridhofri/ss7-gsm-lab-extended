<h1 align="center">SS7 / GSM Simulation Lab — Extended</h1>

<p align="center">
  A fully containerized, <strong>isolated</strong> SS7/GSM core <strong>and</strong> radio access network —
  where a software-defined virtual handset camps on a cell, authenticates, registers (Location Update),
  and exchanges SMS, with <strong>no physical radio hardware</strong>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/stack-Osmocom-1f6feb" alt="Stack">
  <img src="https://img.shields.io/badge/protocols-SS7%20%7C%20SIGTRAN%20%7C%20GSM-blue" alt="Protocols">
  <img src="https://img.shields.io/badge/status-educational-success" alt="Status">
</p>

<p align="center">
[ mobile ]                 osmocom-bb virtual handset (MS)
                             |
                             |   L1CTL : unix socket /tmp/osmocom_l2
                             |
                        [ virtphy ]                 virtual L1 / PHY
                             |
                             |   Um : GSMTAP multicast  (simulated radio)
                             |        DL 239.193.23.1 / UL 239.193.23.2 : 4729
                             |
                   [ osmo-bts-virtual ]             BTS
                             |
                             |   Abis : OML + RSL   (IPA 3002 / 3003)
                             |
                       [ osmo-bsc ]                 BSC   (point code 0.23.1)
                             |
                             |   A-interface : BSSAP / SCCP   (over M3UA)
                             |
                       [ osmo-stp ]                 SS7 / SIGTRAN router
                             |                      (M3UA @ 2906, point code 0.23.0)
                             |   M3UA / SCTP
                             |
                       [ osmo-msc ]                 MSC   (point code 0.23.2)
                          /        \
              GSUP : 4222          MGCP : 2427
                        /            \
                 [ osmo-hlr ]    [ osmo-mgw ]
                 subscriber DB   media gateway
</p>

> [!WARNING]
> **Educational / research use only.** Everything runs on `localhost` with a *test* SIM and
> **no RF transmission**. See the [Disclaimer](#disclaimer).

---

## Table of Contents

- [Highlights](#highlights)
- [Overview](#overview)
- [Attribution](#attribution)
- [Architecture](#architecture)
- [Components](#components)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Results](#results)
- [Project Structure](#project-structure)
- [Troubleshooting Highlights](#troubleshooting-highlights)
- [Limitations](#limitations)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## Highlights

- **Full 2G stack, core to handset** — SS7/SIGTRAN core, RAN (BSC + virtual BTS), and a software handset, all in Docker.
- **Authenticated registration** — COMP128v1 challenge/response, A5/1 ciphering, and TMSI allocation, verified end to end.
- **SMS service** — mobile-terminated SMS delivered over the simulated air interface.
- **Fully observable** — every step traceable in application logs, the Osmocom VTY, and Wireshark (DTAP/BSSAP on the A-interface).
- **No hardware required** — the radio (Um) is simulated via GSMTAP multicast; runs entirely on one host.

## Overview

The lab is organized into three layers, the last two of which are the original contribution
of this repository:

- **Core (SS7 / SIGTRAN):** OsmoSTP, OsmoMSC, OsmoHLR, OsmoMGW
- **RAN (added):** OsmoBSC (A-interface) + `osmo-bts-virtual` (Abis)
- **Subscriber side (added):** an [`osmocom-bb`](https://osmocom.org/projects/baseband) virtual
  mobile station (`virtphy` + `mobile`), compiled from source

The end result is a virtual phone that camps on a cell, performs **COMP128v1 authentication**,
enables **A5/1 ciphering**, completes a **Location Update**, receives a **TMSI**, and handles
**SMS** — all observable in application logs, the Osmocom VTY, and Wireshark.

## Attribution

Built on top of **[Tagurkrishna/SS7-Simulation-Lab](https://github.com/Tagurkrishna/SS7-Simulation-Lab)**
(the core SS7 signaling lab). The RAN extension (OsmoBSC + `osmo-bts-virtual`), the virtual
handset (`osmocom-bb`), the integration fixes, and the documentation are original additions
by this repository's author.

## Architecture

The diagram at the top shows the full path from the virtual handset down to the SS7 core.
Each interface and its transport:

| Interface | Between        | Protocol stack                 | Transport                       |
|-----------|----------------|--------------------------------|---------------------------------|
| **Um**    | mobile ↔ BTS   | GSM L1 / L2 / L3               | GSMTAP multicast (simulated RF) |
| **Abis**  | BTS ↔ BSC      | OML + RSL                      | IPA / TCP : 3002 / 3003         |
| **A**     | BSC ↔ MSC      | DTAP / BSSAP / SCCP / M3UA     | SCTP : 2906 (via STP)           |
| **GSUP**  | MSC ↔ HLR      | GSUP                           | TCP : 4222                      |

<details>
<summary>Text (ASCII) version of the architecture</summary>

```
┌──────────────────────────────────────────────────────────────────┐
│  Subscriber side  (osmocom-bb, built from source)                  │
│     mobile ── L1CTL (unix socket /tmp/osmocom_l2) ── virtphy        │
└────────────────────────────────┬───────────────────────────────────┘
                                  │ Um  (GSMTAP multicast — simulated radio)
                                  │     DL 239.193.23.1 / UL 239.193.23.2 : 4729
┌────────────────────────────────▼───────────────────────────────────┐
│  osmo-bts-virtual              (BTS)                                 │
└────────────────────────────────┬───────────────────────────────────┘
                                  │ Abis  (OML + RSL, IPA : 3002 / 3003)
┌────────────────────────────────▼───────────────────────────────────┐
│  osmo-bsc                      (RAN / BSC)                           │
└────────────────────────────────┬───────────────────────────────────┘
                                  │ A-interface  (DTAP / BSSAP / SCCP / M3UA : 2906)
┌────────────────────────────────▼───────────────────────────────────┐
│  osmo-stp ── osmo-msc ── osmo-hlr ── osmo-mgw      (Core)            │
│                          GSUP : 4222                                 │
└──────────────────────────────────────────────────────────────────────┘
```

</details>

## Components

| Service               | Role                          | VTY (telnet) |
|-----------------------|-------------------------------|:------------:|
| `osmo-stp`            | SS7 / SIGTRAN router (M3UA)   | 4239         |
| `osmo-msc`            | Mobile Switching Centre       | 4254         |
| `osmo-hlr`            | Home Location Register        | 4258         |
| `osmo-mgw`            | Media Gateway                 | —            |
| `osmo-bsc`            | Base Station Controller       | 4242         |
| `osmo-bts-virtual`    | Virtual BTS                   | 4241         |
| `mobile` (osmocom-bb) | Virtual handset               | 4247         |

**Point codes:** STP `0.23.0`, BSC `0.23.1`, MSC `0.23.2`.

## Prerequisites

- A Linux host with **Docker** and **Docker Compose** (developed on Kali Linux)
- The SCTP kernel module: `sudo modprobe sctp`
- *(Optional)* Wireshark / `tshark` for packet inspection

## Quick Start

### 1. Bring up the core + RAN
```bash
git clone https://github.com/ridhofri/ss7-gsm-lab-extended.git
cd ss7-gsm-lab-extended
sudo modprobe sctp
docker compose -f docker/docker-compose.yml up -d
```
Check that the A-interface association is established:
```bash
docker compose -f docker/docker-compose.yml logs bsc | grep -i "BSSMAP"
```

### 2. Build the virtual-handset image (once)
```bash
docker build -t ss7lab-bb -f docker/bb/Dockerfile .
```
> The handset is built inside `debian:12` (GCC 12) to avoid GCC 15 / C23 build errors that
> occur on newer host distributions.

### 3. Run the handset → triggers a Location Update
```bash
docker run -d --name bbrun --network host \
  -v "$PWD/config/mobile.cfg:/data/mobile.cfg:ro" ss7lab-bb bash -c '
  mkdir -p ~/.osmocom/bb && touch ~/.osmocom/bb/sms.txt
  host/virt_phy/src/virtphy -s /tmp/osmocom_l2 &
  sleep 2
  host/layer23/src/mobile/mobile -c /data/mobile.cfg'
```
Confirm registration from the **network** side:
```bash
docker compose -f docker/docker-compose.yml logs msc | grep -iE "AUTH established|TMSI"
```
…or from the **handset's own** VTY:
```bash
telnet 127.0.0.1 4247
#   enable
#   show ms          -> expect "service is normal"
#   show subscriber  -> expect "U1_UPDATED", valid LAI, a TMSI
```

### 4. Send an SMS (network-originated / MT)
```bash
telnet 127.0.0.1 4254          # OsmoMSC VTY
#   enable
#   subscriber msisdn 1001 sms sender msisdn 1001 send Hello from the lab
docker exec bbrun cat ~/.osmocom/bb/sms.txt
```

### Tear down
```bash
docker rm -f bbrun
docker compose -f docker/docker-compose.yml down
```

## Results

### Authenticated Location Update (captured on the A-interface)

Captured with `tshark -i lo -f "sctp port 2906" -Y gsm_a.dtap`
(point codes: `185 = BSC`, `186 = MSC`):

| Direction | Message                          | Meaning                               |
|-----------|----------------------------------|---------------------------------------|
| BSC→MSC   | **CR** + Location Updating Request | LU begins; SCCP connection opens     |
| MSC→BSC   | **CC**                           | connection accepted                   |
| MSC→BSC   | Authentication Request           | RAND challenge (vector from HLR)      |
| BSC→MSC   | Authentication Response          | SRES = COMP128(Ki, RAND)              |
| MSC→BSC   | Cipher Mode Command              | A5/1 ciphering ordered                |
| BSC→MSC   | Ciphering Mode Complete          | radio link encrypted                  |
| MSC→BSC   | **Location Updating Accept**     | network accepts + assigns TMSI        |
| BSC→MSC   | TMSI Reallocation Complete       | handset stores TMSI → done            |

The MSC confirms `AUTH established GSM security context` and reaches state
`MSC_A_ST_AUTHENTICATED`.

### Default subscriber

| Field   | Value                       |
|---------|-----------------------------|
| IMSI    | `001010000000001`           |
| MSISDN  | `1001`                      |
| Auth    | COMP128v1 (2G)              |
| PLMN    | MCC `001` / MNC `01` (Test) |

## Project Structure

```
config/                 osmo-*.cfg and mobile.cfg
docker/
  ├─ docker-compose.yml
  ├─ stp/  msc/  hlr/  mgw/    core services
  ├─ bsc/                      A-interface          (added)
  ├─ bts-virtual/              Abis / virtual BTS   (added)
  └─ bb/                       osmocom-bb handset   (added)
scripts/                helper scripts
docs/                   documentation & images
```

## Troubleshooting Highlights

A few hard-won fixes encountered while building the lab:

- Osmocom configs are **indentation-sensitive** — prefer full-file rewrites over `sed`.
- **BTS:** bind the TRX to a PHY (`phy 0 instance 0` inside `trx 0`) and use a valid GSM900
  ARFCN (e.g. `1`, not `871`, which belongs to DCS1800).
- **BSC:** declare `e1_input` / `e1_line 0 driver ipa` *before* the `bts` block.
- **osmocom-bb deps:** the `libosmo-gprs-*` packages are **split**
  (`rlcmac` / `llc` / `gmm` / `sm` / `sndcp`).
- **`--network host`:** only one `mobile` can hold VTY port `4247`. Clean up stale containers
  *by image*: `docker ps -q --filter ancestor=ss7lab-bb | xargs -r docker rm -f`.
- **MT-SMS** requires `~/.osmocom/bb/sms.txt` to exist, otherwise the handset replies with
  *Memory Exceeded* (RP cause 22).

## Limitations

- Fully simulated radio (GSMTAP multicast) — no real RF.
- 2G circuit-switched only; GPRS is disabled.
- Single cell and a single subscriber by default.

## Disclaimer

This lab demonstrates **known, decades-old weaknesses** of legacy 2G security
(COMP128v1, A5/1) for **education and research only**, in a **fully isolated environment**
with a test SIM and **no over-the-air transmission**. Do **not** apply these techniques to
networks, equipment, or subscribers you are not explicitly authorized to test. The author
accepts no liability for misuse.

## License

Released under the [MIT License](LICENSE) — see the `LICENSE` file. You are free to use,
modify, and distribute this work with attribution. This project builds upon
[Tagurkrishna/SS7-Simulation-Lab](https://github.com/Tagurkrishna/SS7-Simulation-Lab);
please preserve the attribution noted above.

## Acknowledgements

- [Osmocom](https://osmocom.org) — the open-source mobile communications stack.
- [Tagurkrishna/SS7-Simulation-Lab](https://github.com/Tagurkrishna/SS7-Simulation-Lab) — the original core lab.

---

<p align="center">
  <em>Maintained by <a href="https://github.com/ridhofri">@ridhofri</a> · Built as part of telecommunications engineering coursework, 2026.</em>
</p>
