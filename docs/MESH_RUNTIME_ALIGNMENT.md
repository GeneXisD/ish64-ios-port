# iSH64 Mesh Runtime Alignment

## Purpose
This document defines how iSH64 fits into the broader RitualMesh architecture.

It bridges:
- mobile execution (iOS)
- mesh experimentation
- federated node infrastructure

## Core realization

iSH64 is not just a Linux emulator.

It is:

> a portable execution node for the mesh

## Role in the system

### 1. Portable node

The iPhone becomes:
- a lightweight node
- a testing environment
- a portable operator console

### 2. Experimental runtime

iSH64 allows:
- testing networking stacks
- validating service discovery models
- experimenting with identity propagation

### 3. Bridge between environments

It connects:
- Apple ecosystem
- Linux runtime
- mesh-based services

## Lessons from DECnet / FreakNet

Observed:
- terminals can act as access points to larger systems
- identity can traverse systems
- users do not need full system control to interact with the network

Applied to iSH64:

- the device does not need to host the primary node
- it only needs to interact correctly

## Functional targets

### Networking

- slirp-based networking (current)
- future mesh integration (libp2p / custom)
- experimental routing layers

### Identity

- key storage
- request signing
- node verification

### Service interaction

- query federated nodes
- run diagnostics
- submit transactions (future)

## Position in architecture

| Layer | Role |
|---|---|
| Intel host | canonical execution |
| M4 Mac | orchestration + verification |
| iSH64 | portable interaction + experimentation |

## Immediate next steps

- ensure stable build on iOS
- validate networking reliability
- create simple host communication scripts
- log behavior differences vs desktop environments

## Long-term direction

- mesh-aware runtime
- decentralized service discovery
- secure communication channels

## Guardrail

iSH64 must remain:

- lightweight
- portable
- experimental

It should not attempt to replace the primary node.

## Final statement

iSH64 turns a mobile device into a **controlled, experimental edge node of the RitualMesh system**.

That is its power.