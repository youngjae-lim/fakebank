# Environment Variables

## Why File?

- Development: Easily specify default configuration for local development and testing

## Why ENV Variables?

- Deployment: Easily override the default configurations when deploy with docker containers

## Viper

- Find, load, unmarshal config File

  - JSON, TOML, TAML, ENV, INI

- Read config from environment variables or flags

  - Override existing values, set default values

- Read config from remote system

  - Etcd, Consul

- Live watching and writing config File
  - Reread changed file, save any modifications
