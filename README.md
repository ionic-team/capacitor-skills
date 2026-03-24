# Ionic & Capacitor Skills

A catalog of agent skills for working with Ionic and Capacitor framework projects.

## Overview

This repository contains specialized skills that enhance Claude Code's capabilities when developing Capacitor plugins and migrating Cordova plugins to Capacitor. These skills provide comprehensive guidance, best practices, and automated workflows for native mobile plugin development.

## Available Skills

### capacitor-plugin-development

Guides the complete lifecycle of Capacitor plugin development, from requirements gathering through implementation and testing. This skill helps you:

- Create new Capacitor plugins from scratch
- Design plugin architecture and API contracts
- Implement native code for iOS (Swift) and Android (Kotlin/Java)
- Bridge native APIs to JavaScript/TypeScript
- Set up plugin configuration and build systems
- Write tests for Capacitor plugins
- Convert Cordova plugins to Capacitor

**Use when:** Creating custom native functionality, building plugin bridges, or converting existing Cordova plugins.

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
npx skills add ionic-team/skills

# Or install a specific skill
npx skills add ionic-team/skills/capacitor-plugin-development
npx skills add ionic-team/skills/cordova-capacitor-plugin-migration
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

Once installed, these skills are automatically available. Simply mention plugin development or migration tasks in your prompts:

```
"Create a Capacitor plugin for accessing device battery information"
"Migrate this Cordova plugin to Capacitor"
"Analyze the migration complexity of cordova-plugin-camera"
```

The relevant skills will automatically activate based on your request.

## Resources

- [Capacitor Documentation](https://capacitorjs.com/docs)
- [Capacitor Plugin Guide](https://capacitorjs.com/docs/plugins)
- [Cordova to Capacitor Migration Guide](https://capacitorjs.com/docs/cordova/migrating-from-cordova-to-capacitor)
