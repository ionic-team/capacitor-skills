# Capacitor Skills

A catalog of agent skills for working with Capacitor.

## Overview

This repository contains agent skills focused on the Capacitor development lifecycle. Currently, it includes skills specific to plugins: generating first-pass net-new plugins, migrating existing Cordova plugins to Capacitor, unifying a plugin's Capacitor and Cordova sides into an OutSystems dual-stack plugin, and configuring OutSystems Developer Cloud (ODC) build actions for plugins.

The skills are written to be agent-agnostic. They package domain knowledge, best practices, and repeatable workflows as plain instructions and reference material, so any agent that supports the [skills](https://skills.sh) format can use them.

## Available Skills

### capacitor-plugin-generator

Generates new Capacitor plugin scaffolds and first-pass implementations from conversational requirements. It produces native code for iOS and Android along with the JavaScript/TypeScript bridge and plugin configuration.

**Use when:** Creating a new Capacitor plugin, scaffolding a native plugin for iOS and Android.

### cordova-plugin-migrator

An end-to-end Cordova-to-Capacitor migration orchestrator. It analyzes a Cordova plugin, produces a structured migration plan, hands that plan to `capacitor-plugin-generator` at a user checkpoint, and consolidates the results into a single `MIGRATION.md`.

**Use when:** Migrating a Cordova plugin to Capacitor, assessing migration feasibility, identifying migration blockers, or estimating migration effort. Scope is plugin-level only.

### build-actions-generator

Generates OutSystems Developer Cloud (ODC) build action JSON files that configure Capacitor mobile plugin builds for Android and iOS, including platform-specific actions, input variables, and conditional logic.

**Use when:** Creating a build action for an ODC plugin, generating a `buildAction.json` file, setting up Gradle or plist build actions, or configuring `AndroidManifest` for an ODC build. Note that build actions only apply to ODC — they have no effect in standalone Capacitor apps.

### plugin-unifier

Generates both sides of an OutSystems unified dual-stack plugin — the Capacitor plugin and the Cordova plugin — from a single agreed API spec. It orchestrates `cordova-plugin-migrator` and `capacitor-plugin-generator`, then overlays the OutSystems unified-plugin structure so both plugins expose identical method names, options, return shapes, and error codes.

**Use when:** Generating a unified plugin for a feature, creating the Cordova and Capacitor sides together, generating the missing side when one already exists, or aligning two diverged plugins to a single API. Not for a standalone Capacitor plugin (use `capacitor-plugin-generator`) or a plain Cordova-to-Capacitor migration (use `cordova-plugin-migrator`).

## Installation

Install skills directly from this repository using [skills.sh](https://skills.sh):

```bash
# Install all skills from this repository
npx skills add ionic-team/capacitor-skills

# Or install a specific skill
npx skills add ionic-team/capacitor-skills/capacitor-plugin-generator
npx skills add ionic-team/capacitor-skills/cordova-plugin-migrator
npx skills add ionic-team/capacitor-skills/build-actions-generator
npx skills add ionic-team/capacitor-skills/plugin-unifier
```

## Local Development

For testing and developing skills locally, use the provided toggle script:

```bash
# Toggle skills on/off for local development
./toggle-skills.sh
```

This script will:
- Automatically detect all skills in the `./skills` directory
- Create/remove symlinks to `~/.claude/skills/` for local testing
- Display which skills were added or removed

Run the script again to toggle between enabled and disabled states.

## Prerequisites

- Basic understanding of Capacitor and/or Cordova plugin architecture

## Usage

Once installed, the skills become available to your agent and activate based on the task you describe. Phrase requests in terms of the plugin work you want done, for example:

```
"Generate a Capacitor plugin for accessing device battery information"
"Migrate this Cordova plugin to Capacitor"
"Assess the migration feasibility of cordova-plugin-camera"
"Create an ODC build action for my Capacitor plugin"
```

The relevant skill activates automatically when your request matches what it handles.
