# Ionic & Capacitor Skills

A catalog of agent skills for working with Ionic and Capacitor framework projects.

## Overview

This repository contains specialized skills that enhance Claude Code's capabilities when generating Capacitor plugin candidates and analyzing Cordova plugins for Capacitor migration. These skills provide focused guidance, best practices, and structured workflows for native mobile plugin development.

## Available Skills

### capacitor-plugin-generator

Generates new Capacitor plugin scaffolds and first-pass implementations from conversational requirements or a structured YAML input contract. This skill helps you:

- Create new Capacitor plugins from scratch
- Design contract-first TypeScript APIs
- Implement native code for iOS (Swift) and Android (Java by default, Kotlin when selected)
- Bridge native APIs to JavaScript/TypeScript
- Implement the WebPlugin layer
- Generate a sample app that exercises the plugin API
- Run docgen, verify commands, and dry-run publish checks

**Use when:** Generating a new Capacitor plugin candidate from human intent or from YAML produced by the migration analyzer. This skill does not analyze Cordova source or produce production-ready code without human review.

### cordova-capacitor-plugin-migration

Analyzes Cordova plugins to understand their structure and plan their conversion to Capacitor. This skill provides:

- Architecture analysis of existing Cordova plugins
- Migration complexity assessment
- Cordova-to-Capacitor API mappings
- Identification of unsupported patterns and migration blockers
- Migration feasibility reports

**Use when:** Planning a Cordova to Capacitor migration, assessing migration effort, or understanding plugin architecture for conversion.

## Installation

Install skills directly from this repository using [skills.sh](https://skills.sh):

```bash
# Install all skills from this repository
npx skills add ionic-team/capacitor-skills

# Or install a specific skill
npx skills add ionic-team/capacitor-skills/capacitor-plugin-generator
npx skills add ionic-team/capacitor-skills/cordova-capacitor-plugin-migration
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

Once installed, these skills are automatically available. Mention plugin generation or migration analysis tasks in your prompts:

```
"Create a Capacitor plugin for accessing device battery information"
"Use this YAML contract to generate a Capacitor plugin"
"Analyze the migration complexity of cordova-plugin-camera"
```

The relevant skills will automatically activate based on your request.

## Resources

- [Capacitor Documentation](https://capacitorjs.com/docs)
- [Capacitor Plugin Guide](https://capacitorjs.com/docs/plugins)
- [Cordova to Capacitor Migration Guide](https://capacitorjs.com/docs/cordova/migrating-from-cordova-to-capacitor)
